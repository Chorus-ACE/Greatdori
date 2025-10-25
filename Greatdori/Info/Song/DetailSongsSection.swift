//===---*- Greatdori! -*---------------------------------------------------===//
//
// DetailSongsSection.swift
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
import SDWebImageSwiftUI
import SwiftUI


// MARK: DetailsSongsSection
struct DetailsSongsSection: View {
    var songs: [PreviewSong]
    var body: some View {
        DetailSectionBase(elements: songs.sorted(withDoriSorter: DoriSorter(keyword: .releaseDate(in: .jp)))) { item in
            NavigationLink(destination: {
                SongDetailView(id: item.id)
            }, label: {
                SongInfo(item, layout: .horizontal)
            })
        }
        .contentUnavailablePrompt("Details.songs.unavailable")
        .contentUnavailableImage(systemName: "person.crop.square.on.square.angled")
    }
}
