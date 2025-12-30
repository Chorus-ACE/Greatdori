//===---*- Greatdori! -*---------------------------------------------------===//
//
// NeoAssetExplorer.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.com/LICENSE.txt for license information
// See https://greatdori.com/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import Alamofire
import DoriKit
import SwiftUI
import UniformTypeIdentifiers

struct AssetExplorerView: View {
    var body: some View {
        AssetListView(items: DoriLocale.allCases.map { locale in AssetItem(type: .folder, name: locale.rawValue, content: { LocaleAssetView(locale: locale) }) })
    }
}

struct LocaleAssetView: View {
    var locale: DoriLocale
    @State private var assetList: DoriAPI.Assets.AssetList?
    var body: some View {
        if let assetList {
            AssetListView(items: .init(assetList, path: DoriAPI.Assets.PathDescriptor(locale: locale)), locale: locale)
                .navigationTitle(locale.rawValue)
        } else {
            ProgressView()
                .controlSize(.large)
                .onAppear {
                    Task {
                        assetList = await DoriAPI.Assets.info(in: locale)
                    }
                }
        }
    }
}

struct AssetListView: View {
    @State var items: [AssetItem]?
    @State var filteredItems: [AssetItem]?
    var currentPath: DoriAPI.Assets.PathDescriptor?
    var locale: DoriLocale?
    
    @State var searchField = ""
    
    @State private var itemLookViewContent: ItemPresenter?
    @State private var contentLoadingItem: AssetItem?
    
    @State private var isFileExporterPresented = false
    @State private var fileExporterDocument: AssetFileDocument?
    @State private var fileExporterDefaultFileName: String?
    var body: some View {
        Group {
            if let items {
                CustomScrollView {
                    if let filteredItems {
                        LazyVStack {
                            CustomGroupBox {
                                if !filteredItems.isEmpty {
                                    VStack {
                                        ForEach(filteredItems, id: \.self) { item in
                                            Group {
                                                if item.type == .file {
                                                    Button(action: {
                                                        openItem(item)
                                                    }, label: {
                                                        HStack {
                                                            Label(title: {
                                                                HighlightableText(item.name)
                                                                    .highlightKeyword($searchField)
                                                            }, icon: {
                                                                if item == contentLoadingItem {
                                                                    ProgressView()
                                                                        .controlSize(.small)
                                                                } else {
                                                                    Image(_internalSystemName: {
                                                                        if item.name.hasSuffix(".jpg") || item.name.hasSuffix(".png") {
                                                                            return "photo"
                                                                        } else if item.name.hasSuffix(".mp3") {
                                                                            return "music.note"
                                                                        } else if item.name.hasSuffix(".mp4") {
                                                                            return "film"
                                                                        } else if item.name.hasSuffix(".bundle") {
                                                                            return "buildingblock"
                                                                        } else if item.name.hasSuffix(".txt") {
                                                                            return "text.document"
                                                                        } else {
                                                                            return "document"
                                                                        }
                                                                    }())
                                                                    .foregroundStyle(.gray)
                                                                }
                                                            })
                                                            Spacer()
                                                        }
                                                        .contentShape(Rectangle())
                                                    })
                                                } else {
                                                    NavigationLink(destination: {
                                                        item.view
                                                    }, label: {
                                                        HStack {
                                                            Label(title: {
                                                                HighlightableText(item.name)
                                                                    .highlightKeyword($searchField)
                                                            }, icon: {
                                                                Group {
                                                                    switch item.type {
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
                                                                            .foregroundStyle(Color(red: 121 / 255, green: 190 / 255, blue: 230 / 255).gradient)
                                                                    default:
                                                                        EmptyView()
                                                                    }
                                                                }
                                                                .frame(minWidth: 5)
                                                            })
                                                            Spacer()
                                                        }
                                                        .contentShape(Rectangle())
                                                    })
                                                }
                                            }
                                            .frame(minHeight: 5)
                                            .buttonStyle(.plain)
                                            .contextMenu {
                                                Section {
                                                    if item.type == .file, let path = currentPath {
                                                        Button("Asset-explorer.download", systemImage: "arrow.down.circle") {
                                                            downloadItem(item, withPath: path)
                                                        }
                                                    }
                                                }
                                            }
                                            .fileExporter(
                                                isPresented: $isFileExporterPresented,
                                                document: fileExporterDocument,
                                                contentType: .content,
                                                defaultFilename: fileExporterDefaultFileName
                                            ) { _ in
                                                fileExporterDocument = nil
                                                fileExporterDefaultFileName = nil
                                            }
                                            if item != filteredItems.last {
                                                Divider()
                                            }
                                        }
                                    }
                                } else {
                                    HStack {
                                        Spacer()
                                        ContentUnavailableView("Search.no-results", systemImage: "magnifyingglass", description: Text("Search.no-results.description"))
                                        Spacer()
                                    }
                                }
                            }
                            .frame(maxWidth: infoContentMaxWidth)
                            
                            DetailSectionsSpacer()
                            
                            let imageItems = filteredItems.filter( { $0.name.hasSuffix(".jpg") || $0.name.hasSuffix(".png") } )
                            if let currentPath, !imageItems.isEmpty {
                                DetailArtsSection {
                                    ArtsTab("") {
                                        for item in imageItems {
                                            ArtsItem(title: LocalizedStringResource(stringLiteral: item.name), url: currentPath.resourceURL(name: item.name))
                                        }
                                    }
                                }
                                .highlightKeyword($searchField)
                            }
                        }
                        .padding()
                        .wrapIf(true, in: {
                            if #available(iOS 26, macOS 14.0, *) {
                                $0.navigationSubtitle(Text(searchField.isEmpty ? "Search.item.\(filteredItems.count)" : "Search.result.\(filteredItems.count)"))
                            } else {
                                $0
                            }
                        })
                    }
                }
                .searchable(text: $searchField, prompt: "Asset-explorer.search")
                .onChange(of: searchField, initial: true) {
                    filteredItems = searchField.isEmpty ? items : items.filter( { $0.name.contains(searchField) } )
                }
            } else if let currentPath {
                ExtendedConstraints {
                    ProgressView()
                        .onAppear {
                            Task {
                                if let contents = await DoriAPI.Assets.contentsOf(currentPath) {
                                    items = contents.map {
                                        .init(type: .file, name: $0) {}
                                    }
                                }
                            }
                        }
                }
            } else {
                ExtendedConstraints {
                    DetailUnavailableView(title: "Asset-explorer.unavailable", symbol: "exclamationmark.circle")
                }
            }
        }
        .navigationTitle(currentPath?.componments.last ?? locale?.rawValue ?? String(localized: "Asset-explorer"))
        .withSystemBackground()
        #if os(macOS)
        .window(item: $itemLookViewContent) { content in
            content.view
        }
        #else
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $itemLookViewContent) { content in
            content.view
        }
        #endif
    }
    
    func openItem(_ item: AssetItem) {
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
            } else if item.name.hasSuffix(".mp3") {
                itemLookViewContent = .init {
                    AssetAudioPlayer(url: path.resourceURL(name: item.name), name: item.name)
                }
            } else if item.name.hasSuffix(".mp4") {
                itemLookViewContent = .init {
                    AssetVideoPlayer(url: path.resourceURL(name: item.name))
                }
            } else if [".txt", ".json", ".asset", ".bundle", ".sprites"].contains(where: { item.name.hasSuffix($0) }) {
                itemLookViewContent = .init {
                    AssetTextViewer(url: path.resourceURL(name: item.name), name: item.name)
                }
            }
        }
    }
    
    func downloadItem(_ item: AssetItem, withPath path: DoriAPI.Assets.PathDescriptor) {
        contentLoadingItem = item
        #if os(macOS)
        let downloadURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!.appending(path: item.name)
        AF.download(path.resourceURL(name: item.name), to: { _, _ in
            (downloadURL, [])
        }).response { response in
            if response.error == nil {
                DistributedNotificationCenter.default.post(
                    name: .init("com.apple.DownloadFileFinished"),
                    object: downloadURL.resolvingSymlinksInPath().path
                )
            }
            DispatchQueue.main.async {
                contentLoadingItem = nil
            }
        }
        #else // os(macOS)
        AF.request(path.resourceURL(name: item.name)).response { response in
            DispatchQueue.main.async {
                if let data = response.data {
                    fileExporterDocument = .init(data: data)
                    fileExporterDefaultFileName = item.name
                    isFileExporterPresented = true
                }
                contentLoadingItem = nil
            }
        }
        #endif // os(macOS)
    }
}

struct ItemPresenter: Identifiable {
    var id = UUID()
    var view: AnyView
    
    init(@ViewBuilder content: () -> some View) {
        self.view = AnyView(content())
    }
}
