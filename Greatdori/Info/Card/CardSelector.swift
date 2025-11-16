//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardSelector.swift
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

import DoriKit
import SwiftUI

struct MultiCardSelector: View {
    @Binding var selection: [PreviewCard]
    let gridLayoutItemWidth: CGFloat = 200
    let galleryLayoutItemMinimumWidth: CGFloat = 400
    let galleryLayoutItemMaximumWidth: CGFloat = 500
    var updateList: () async -> [PreviewCard]? = { await Card.all() }
    var body: some View {
        ItemSelectorView(selection: $selection, initialLayout: 1, updateList: updateList, layoutOptions: [("Filter.view.list", "list.bullet", 1), ("Filter.view.grid", "square.grid.2x2", 2), ("Filter.view.gallery", "text.below.rectangle", 3)]) { layout, _, content, _ in
            if layout == 1 {
                LazyVStack {
                    content
                }
                .frame(maxWidth: infoContentMaxWidth)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: layout == 2 ? gridLayoutItemWidth : galleryLayoutItemMinimumWidth, maximum: layout == 2 ? gridLayoutItemWidth : galleryLayoutItemMaximumWidth))]) {
                    content
                }
            }
        } eachContent: { layout, element in
            CardInfo(element, layoutType: layout)
        }
        .resultCountDescription { count in
            "Card.count.\(count)"
        }
    }
}

struct CardSelector: View {
    @Binding var selection: PreviewCard?
    var updateList: () async -> [PreviewCard]? = { await Card.all() }
    var body: some View {
        MultiCardSelector(selection: .init { [selection].compactMap { $0 } } set: { selection = $0.first }, updateList: updateList)
            .selectorDisablesMultipleSelection()
    }
}
