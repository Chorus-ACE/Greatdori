//===---*- Greatdori! -*---------------------------------------------------===//
//
// CostumeSelector.swift
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

struct MultiCostumeSelector: View {
    @Binding var selection: [PreviewCostume]
    let gridLayoutItemWidth: CGFloat = 200
    var body: some View {
        ItemSelectorView("Costumes", selection: $selection, initialLayout: SummaryLayout.horizontal, layoutOptions: verticalAndHorizontalLayouts) { layout, _, content, _ in
            if layout == .horizontal {
                LazyVStack {
                    content
                }
                .frame(maxWidth: infoContentMaxWidth)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: gridLayoutItemWidth, maximum: gridLayoutItemWidth))]) {
                    content
                }
            }
        } eachContent: { layout, element in
            CostumeInfo(element, layout: layout)
        }
        .contentUnavailableImage(systemName: "swatchpalette")
        .resultCountDescription { count in
            "Costume.count.\(count)"
        }
    }
}

struct CostumeSelector: View {
    @Binding var selection: PreviewCostume?
    var body: some View {
        MultiCostumeSelector(selection: .init { [selection].compactMap { $0 } } set: { selection = $0.first })
            .selectorDisablesMultipleSelection()
    }
}
