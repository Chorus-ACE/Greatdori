//===---*- Greatdori! -*---------------------------------------------------===//
//
// FallingWebImage.swift
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

struct FallingWebImage<Content: View>: View {
    var urls: [URL]
    var scale: CGFloat
    var options: SDWebImageOptions
    var context: [SDWebImageContextOption: Any]?
    var isAnimating: Binding<Bool> = .constant(true)
    var transaction: Transaction
    var content: (WebImagePhase) -> Content
    var modifiers: [(WebImage<Content>) -> WebImage<Content>] = []
    
    init(
        throughURLs urls: [URL?],
        scale: CGFloat = 1,
        options: SDWebImageOptions = [],
        context: [SDWebImageContextOption: Any]? = nil,
        isAnimating: Binding<Bool> = .constant(true)
    ) where Content == Image {
        self.init(throughURLs: urls, scale: scale, options: options, context: context, isAnimating: isAnimating) {
            $0.image ?? Image(uiImage: .init())
        }
    }
    init<I, P>(
        throughURLs urls: [URL?],
        scale: CGFloat = 1,
        options: SDWebImageOptions = [],
        context: [SDWebImageContextOption: Any]? = nil,
        isAnimating: Binding<Bool> = .constant(true),
        @ViewBuilder content: @escaping (Image) -> I,
        @ViewBuilder placeholder: @escaping () -> P
    ) where Content == _ConditionalContent<I, P>, I: View, P: View {
        self.init(throughURLs: urls, scale: scale, options: options, context: context, isAnimating: isAnimating) {
            if let image = $0.image {
                content(image)
            } else {
                placeholder()
            }
        }
    }
    init(
        throughURLs urls: [URL?],
        scale: CGFloat = 1,
        options: SDWebImageOptions = [],
        context: [SDWebImageContextOption : Any]? = nil,
        isAnimating: Binding<Bool> = .constant(true),
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (WebImagePhase) -> Content
    ) {
        self.urls = urls.compactMap { $0 }
        self.scale = scale
        self.options = options
        self.context = context
        self.isAnimating = isAnimating
        self.transaction = transaction
        self.content = content
        self._currentImageURLIndex = .init(initialValue: !urls.isEmpty ? 0 : nil)
    }
    
    @State var currentImageURLIndex: Array.Index?
    
    var body: some View {
        _makeView()
    }
    
    private func _makeView() -> some View {
        var result = WebImage(
            url: currentImageURLIndex != nil ? urls[currentImageURLIndex!] : nil,
            scale: scale,
            options: options,
            context: context,
            isAnimating: isAnimating,
            transaction: transaction,
            content: content
        )
        .onFailure { _ in
            DispatchQueue.main.async {
                currentImageURLIndex! + 1 < urls.count ? (currentImageURLIndex! += 1) : ()
            }
        }
        for modifier in modifiers {
            result = modifier(result)
        }
        return result
    }
}

extension FallingWebImage {
    func configure(_ block: @escaping (WebImage<Content>) -> WebImage<Content>) -> Self {
        var result = self
        result.modifiers.append(block)
        return result
    }
    
    public func resizable(
        capInsets: EdgeInsets = EdgeInsets(),
        resizingMode: Image.ResizingMode = .stretch) -> Self
    {
        configure { $0.resizable(capInsets: capInsets, resizingMode: resizingMode) }
    }
    
    public func renderingMode(_ renderingMode: Image.TemplateRenderingMode?) -> Self {
        configure { $0.renderingMode(renderingMode) }
    }
    
    public func interpolation(_ interpolation: Image.Interpolation) -> Self {
        configure { $0.interpolation(interpolation) }
    }
    
    public func antialiased(_ isAntialiased: Bool) -> Self {
        configure { $0.antialiased(isAntialiased) }
    }
}
