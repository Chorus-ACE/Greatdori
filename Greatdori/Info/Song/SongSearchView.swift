//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongSearchView.swift
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
import DoriKit

// MARK: SongSearchView
struct SongSearchView: View {
    let gridLayoutItemWidth: CGFloat = 225
    @State private var songMatches: [Int: DoriFrontend.Songs._NeoSongMatchResult]?
    var body: some View {
        SearchViewBase(forType: PreviewSong.self, initialLayout: SummaryLayout.horizontal, layoutOptions: verticalAndHorizontalLayouts) { layout, _, content, _ in
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
        } destination: { element, list in
            SongDetailView(id: element.id, allSongs: list, songMatches: songMatches)
        }
        .resultCountDescription { count in
            "Song.count.\(count)"
        }
        .onAppear {
            Task {
                DoriCache.withCache(id: "DoriFrontend.Songs._allMatches", trait: .invocationElidable) {
                    await DoriFrontend.Songs._allMatches()
                }.onUpdate {
                    self.songMatches = $0
                }
            }
        }
    }
}
