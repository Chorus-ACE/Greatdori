//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongSelector.swift
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

struct MultiSongSelector: View {
    @Binding var selection: [PreviewSong]
    let gridLayoutItemWidth: CGFloat = 225
    var body: some View {
        ItemSelectorView(selection: $selection, initialLayout: .horizontal, layoutOptions: verticalAndHorizontalLayouts) { layout, _, content, _ in
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
            SongInfo(element, layout: layout)
        }
        .resultCountDescription { count in
            "Song.count.\(count)"
        }
    }
}

struct SongSelector: View {
    @Binding var selection: PreviewSong?
    var body: some View {
        MultiSongSelector(selection: .init { [selection].compactMap { $0 } } set: { selection = $0.first })
            .selectorDisablesMultipleSelection()
    }
}
