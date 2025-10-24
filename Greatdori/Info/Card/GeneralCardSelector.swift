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

struct CardSelector: View {
    @Binding var selection: [PreviewCard]
    let gridLayoutItemWidth: CGFloat = 200
    let galleryLayoutItemMinimumWidth: CGFloat = 400
    let galleryLayoutItemMaximumWidth: CGFloat = 500
    var body: some View {
        ItemSelectorView("Cards", selection: $selection, initialLayout: 1, layoutOptions: [("Filter.view.list", "list.bullet", 1), ("Filter.view.grid", "square.grid.2x2", 2), ("Filter.view.gallery", "text.below.rectangle", 3)]) { layout, _, content, _ in
            if layout == 1 {
                LazyVStack {
                    content
                }
                .frame(maxWidth: 600)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: layout == 2 ? gridLayoutItemWidth : galleryLayoutItemMinimumWidth, maximum: layout == 2 ? gridLayoutItemWidth : galleryLayoutItemMaximumWidth))]) {
                    content
                }
            }
        } eachContent: { layout, element in
            CardInfo(element, layoutType: layout)
        }
        .contentUnavailableImage(systemName: "line.horizontal.star.fill.line.horizontal")
        .resultCountDescription { count in
            "Card.count.\(count)"
        }
    }
}
