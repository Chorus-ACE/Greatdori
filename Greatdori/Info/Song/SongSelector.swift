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

struct SongSelector: View {
    @Binding var selection: [PreviewSong]
    let gridLayoutItemWidth: CGFloat = 225
    var body: some View {
        ItemSelectorView("Songs", selection: $selection, initialLayout: .horizontal, layoutOptions: verticalAndHorizontalLayouts) { layout, _, content, _ in
            if layout == .horizontal {
                LazyVStack {
                    content
                }
                .frame(maxWidth: 600)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: gridLayoutItemWidth, maximum: gridLayoutItemWidth))]) {
                    content
                }
            }
        } eachContent: { layout, element in
            SongInfo(element, layout: layout)
        }
        .contentUnavailableImage(systemName: "music.note")
        .resultCountDescription { count in
            "Song.count.\(count)"
        }
    }
}
