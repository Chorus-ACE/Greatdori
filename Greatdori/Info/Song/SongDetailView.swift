//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongDetailView.swift
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
import SDWebImageSwiftUI

// MARK: SongDetailView
struct SongDetailView: View {
    var id: Int
    var allSongs: [PreviewSong]? = nil
    @State var songMatches: [Int: _DoriFrontend.Songs._SongMatchResult]?
    var body: some View {
        DetailViewBase(previewList: allSongs, initialID: id) { information in
            SongDetailOverviewView(information: information.song)
            SongDetailGameplayView(information: information)
            SongDetailMusicMovieView(musicVideos: information.song.musicVideos)
            DetailsEventsSection(events: information.events)
            SongDetailMatchView(song: information.song, songMatches: $songMatches)
            DetailArtsSection {
                ArtsTab("Song.arts.cover", ratio: 1) {
                    for locale in DoriLocale.allCases {
                        if let url = information.song.jacketImageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url, ratio: 1)
                        }
                    }
                }
            }
            ExternalLinksSection(links: [ExternalLink(name: "External-link.bestdori", url: URL(string: "https://bestdori.com/info/songs/\(information.song.id)")!)])
        } switcherDestination: {
            SongSearchView()
        }
        .onAppear {
            Task {
                DoriCache.withCache(id: "_DoriFrontend.Songs._allMatches", trait: .invocationElidable) {
                    await _DoriFrontend.Songs._allMatches()
                }.onUpdate {
                    self.songMatches = $0
                }
            }
        }
    }
}
