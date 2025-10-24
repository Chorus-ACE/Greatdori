//===---*- Greatdori! -*---------------------------------------------------===//
//
// ImageViewer.swift
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

import SwiftUI
import SDWebImageSwiftUI

extension WebImage {
    func inspectable() -> some View {
        ModifiedContent(content: self, modifier: ImageInspectableModifier(image: self))
    }
}
private struct ImageInspectableModifier<V: View>: ViewModifier {
    var image: WebImage<V>
    @State var isInspectorPresented = false
    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isInspectorPresented) {
                image
                    .scaledToFit()
                    .interactiveFrameTransformable()
            }
            .onTapGesture {
                isInspectorPresented = true
            }
    }
}

extension View {
    func interactiveFrameTransformable() -> some View {
        ModifiedContent(content: self, modifier: Zoomable())
    }
}
private struct Zoomable: ViewModifier {
    @State var scale: CGFloat = 1.0
    @State var offset = CGSize.zero
    @State var lastOffset = CGSize.zero
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .focusable()
            .digitalCrownRotation($scale, from: 0.5, through: .infinity, by: 0.02, sensitivity: .low, isHapticFeedbackEnabled: false)
            .scrollIndicators(.never)
            .offset(x: offset.width, y: offset.height)
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = CGSize(width: gesture.translation.width + lastOffset.width, height: gesture.translation.height + lastOffset.height)
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
            )
            .onDisappear {
                offset = CGSize.zero
                lastOffset = CGSize.zero
            }
            .onChange(of: scale) {
                if scale < 2.0 {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        offset = CGSize.zero
                        lastOffset = CGSize.zero
                    }
                }
            }
    }
}

struct ImageListView: View {
    var groups: [ImageGroup]
    
    init(_ groups: [ImageGroup]) {
        self.groups = groups
        self._selectedGroup = .init(initialValue: groups.first)
    }
    init(@ImageGroupListBuilder content: () -> [ImageGroup]) {
        self.groups = content()
        self._selectedGroup = .init(initialValue: self.groups.first)
    }
    
    @State private var selectedGroup: ImageGroup?
    
    var body: some View {
        Picker("分组", selection: $selectedGroup) {
            if selectedGroup == nil {
                Text("(选择一项)").tag(Optional<ImageGroup>.none)
            }
            ForEach(groups, id: \.self) { group in
                Text(group.name).tag(group)
            }
        }
        if let selectedGroup {
            ForEach(selectedGroup.images, id: \.self) { item in
                ImageButton(item: item)
            }
        }
    }
    
    private struct ImageButton: View {
        var item: ImageItem
        @State private var isInspectorPresented = false
        var body: some View {
            Button(action: {
                isInspectorPresented = true
            }, label: {
                HStack {
                    Spacer()
                    VStack {
                        WebImage(url: item.url) { image in
                            image
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.4))
                        }
                        .resizable()
                        .onFailure { error in
                            print(error)
                        }
                        .scaledToFit()
                        Text(item.description)
                    }
                    Spacer()
                }
            })
            .sheet(isPresented: $isInspectorPresented) {
                WebImage(url: item.url)
                    .resizable()
                    .indicator(.activity)
                    .scaledToFit()
                    .interactiveFrameTransformable()
            }
        }
    }
}
struct ImageGroup: Hashable {
    var name: String
    var images: [ImageItem]
    
    init(name: LocalizedStringResource, images: [ImageItem]) {
        self.name = String(localized: name)
        self.images = images
    }
    
    @_disfavoredOverload
    init(name: String, images: [ImageItem]) {
        self.name = name
        self.images = images
    }
    
    init(_ name: LocalizedStringResource, @_ImageItemBuilder builder: () -> [ImageItem]) {
        self.name = String(localized: name)
        self.images = builder()
    }
    
    @_disfavoredOverload
    init(_ name: String, @_ImageItemBuilder builder: () -> [ImageItem]) {
        self.name = name
        self.images = builder()
    }
}
struct ImageItem: Hashable {
    var url: URL
    var description: String
    
    init(url: URL, description: LocalizedStringResource) {
        self.url = url
        self.description = String(localized: description)
    }
    
    @_disfavoredOverload
    init(url: URL, description: String) {
        self.url = url
        self.description = description
    }
}

@resultBuilder
struct ImageGroupListBuilder {
    static func buildBlock(_ components: ImageGroup...) -> [ImageGroup] {
        components
    }
}
@resultBuilder
struct _ImageItemBuilder {
    static func buildExpression(_ expression: ImageItem) -> [ImageItem] {
        [expression]
    }
    
    static func buildBlock(_ components: [ImageItem]...) -> [ImageItem] {
        components.flatMap { $0 }
    }
    
    static func buildOptional(_ component: [ImageItem]?) -> [ImageItem] {
        component ?? []
    }
    static func buildEither(first component: [ImageItem]) -> [ImageItem] {
        component
    }
    static func buildEither(second component: [ImageItem]) -> [ImageItem] {
        component
    }
}
