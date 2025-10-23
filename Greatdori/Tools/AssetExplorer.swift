//===---*- Greatdori! -*---------------------------------------------------===//
//
// AssetExplorer.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.memz.top/LICENSE.txt for license information
// See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import WebKit
import DoriKit
import SwiftUI
import Alamofire

struct AssetExplorerView: View {
    var body: some View {
        AssetListView(items: [
            .init(type: .folder, name: "jp") {
                LocaleAssetView(locale: .jp)
            },
            .init(type: .folder, name: "en") {
                LocaleAssetView(locale: .en)
            },
            .init(type: .folder, name: "tw") {
                LocaleAssetView(locale: .tw)
            },
            .init(type: .folder, name: "cn") {
                LocaleAssetView(locale: .cn)
            },
            .init(type: .folder, name: "kr") {
                LocaleAssetView(locale: .kr)
            }
        ])
    }
}

private struct LocaleAssetView: View {
    var locale: DoriLocale
    @State private var assetList: DoriAPI.Asset.AssetList?
    var body: some View {
        if let assetList {
            AssetListView(items: .init(assetList, path: .init(locale: locale)))
        } else {
            ProgressView()
                .controlSize(.large)
                .onAppear {
                    Task {
                        assetList = await DoriAPI.Asset.info(in: locale)
                    }
                }
        }
    }
}

private struct AssetItem: @unchecked Sendable, Hashable {
    var type: AssetType
    var name: String
    var view: AnyView
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.type == rhs.type && lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(name)
    }
    
    enum AssetType {
        case file
        case folder
        case rip
    }
}
extension AssetItem {
    init(type: AssetType, name: String, @ViewBuilder content: () -> some View) {
        self.init(type: type, name: name, view: AnyView(content()))
    }
}
extension Array<AssetItem> {
    init(_ info: DoriAPI.Asset.AssetList, path: DoriAPI.Asset.PathDescriptor) {
        func resolveInfo(_ info: DoriAPI.Asset.AssetList, path: DoriAPI.Asset.PathDescriptor) -> [AssetItem] {
            var result = [AssetItem]()
            let keys = info.keys.sorted()
            for key in keys {
                var newPath = path
                let value = info.access(key, updatingPath: &newPath)!
                switch value {
                case .files:
                    result.append(.init(type: .rip, name: key) {
                        AssetListView(currentPath: newPath)
                    })
                case .list(let list):
                    result.append(.init(type: .folder, name: key) {
                        AssetListView(items: resolveInfo(list, path: newPath), currentPath: newPath)
                    })
                }
            }
            return result
        }
        
        self = resolveInfo(info, path: path)
    }
}

private struct AssetListView: View {
    @State var items: [AssetItem]?
    var currentPath: DoriAPI.Asset.PathDescriptor?
    @State private var tintingItem: AssetItem?
    @State private var navigatingItem: AssetItem?
    @State private var previousTapTime = 0.0
    @State private var itemLookViewContent: ItemPresenter?
    @State private var contentLoadingItem: AssetItem?
    var body: some View {
        Group {
            if let items {
                List {
                    ForEach(Array(items.enumerated()), id: \.element.self) { index, item in
                        HStack {
                            Label {
                                Text(item.name)
                            } icon: {
                                if contentLoadingItem != item {
                                    switch item.type {
                                    case .file:
                                        Image(systemName: "document")
                                            .foregroundStyle(.gray)
                                    case .folder:
                                        Image(systemName: "folder.fill")
                                            .foregroundStyle(Color(red: 121 / 255, green: 190 / 255, blue: 230 / 255).gradient)
                                            .background {
                                                Rectangle()
                                                    .fill(Color.white)
                                                    .padding(isMACOS ? 3 : 4)
                                                    .offset(y: 1)
                                            }
                                    case .rip:
                                        Image(systemName: "zipper.page")
                                            .foregroundStyle(.gray)
                                    }
                                } else {
                                    ProgressView()
                                }
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .wrapIf(isMACOS) { content in
                            content
                                .onTapGesture {
                                    if (item == tintingItem && CFAbsoluteTimeGetCurrent() - previousTapTime < 0.5) {
                                        if item.type == .file {
                                            openItem(item)
                                        } else {
                                            navigatingItem = item
                                        }
                                    }
                                    tintingItem = item
                                    previousTapTime = CFAbsoluteTimeGetCurrent()
                                }
                                .listRowBackground(itemBackground(for: item, index: index))
                                .listRowSeparator(.hidden)
                                .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
                        } else: { content in
                            content
                                .onTapGesture {
                                    if item.type == .file {
                                        openItem(item)
                                    } else {
                                        navigatingItem = item
                                    }
                                }
                                .wrapIf(index == 0 || index == items.count - 1) { content in
                                    content
                                        .listRowSeparator(.hidden, edges: index == 0 ? .top : .bottom)
                                }
                        }
                    }
                }
                .listStyle(.plain)
                .wrapIf(isMACOS) { content in
                    content
                        .environment(\.defaultMinListRowHeight, 5)
                        .padding(.horizontal, 10)
                }
                .navigationTitle(currentPath?.componments.last ?? String(localized: "数据包浏览器"))
                #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .navigationDestination(item: $navigatingItem) { item in
                    item.view
                }
                #if os(macOS)
                .window(item: $itemLookViewContent) { content in
                    content.view
                }
                #else
                .fullScreenCover(item: $itemLookViewContent) { content in
                    content.view
                }
                #endif
            } else if let currentPath {
                ExtendedConstraints {
                    ProgressView()
                        .controlSize(.large)
                        .onAppear {
                            Task {
                                if let contents = await DoriAPI.Asset.contentsOf(currentPath) {
                                    items = contents.map {
                                        .init(type: .file, name: $0) {}
                                    }
                                }
                            }
                        }
                }
            } else {
                ExtendedConstraints {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                }
            }
        }
        .withSystemBackground()
    }
    
    @ViewBuilder
    private func itemBackground(for item: AssetItem, index: Int) -> some View {
        if tintingItem == item {
            RoundedRectangle(cornerRadius: 8)
            #if os(macOS)
                .fill(Color(.selectedContentBackgroundColor))
            #endif
        } else {
            if index % 2 == 0 {
                Color.clear
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.11))
            }
        }
    }
    
    private func openItem(_ item: AssetItem) {
        if let path = currentPath {
            if item.name.hasSuffix(".png") || item.name.hasSuffix(".jpg") {
                contentLoadingItem = item
                AF.request(path.resourceURL(name: item.name)).response { response in
                    if let data = response.data {
                        #if os(macOS)
                        let image = NSImage(data: data)
                        #else
                        let image = UIImage(data: data)
                        #endif
                        if let image {
                            DispatchQueue.main.async {
                                #if os(macOS)
                                itemLookViewContent = .init {
                                    ImageLookView(image: image, title: item.name)
                                }
                                #else
                                itemLookViewContent = .init {
                                    ImageLookView(
                                        image: image,
                                        title: item.name,
                                        subtitle: path.locale.rawValue.uppercased(),
                                        imageFrame: .zero
                                    )
                                }
                                #endif
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        contentLoadingItem = nil
                    }
                }
            }
        }
    }
    
    private struct ItemPresenter: Identifiable {
        var id = UUID()
        var view: AnyView
        
        init(@ViewBuilder content: () -> some View) {
            self.view = AnyView(content())
        }
    }
}
