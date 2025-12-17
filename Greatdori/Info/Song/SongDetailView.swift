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
            DetailsEventsSection(events: information.events, applyLocaleFilter: true)
            SongDetailMatchView(song: information.song, songMatches: $songMatches)
            DetailArtsSection {
                ArtsTab("Song.arts.cover", ratio: 1) {
                    for locale in DoriLocale.allCases {
                        if let urls = information.song.jacketImageURLs(in: locale, allowsFallback: false) {
                            for (index, url) in urls.enumerated() {
                                ArtsItem(title: .init(stringLiteral: "\(locale.rawValue.uppercased()) \(index + 1)"), url: url, ratio: 1)
                            }
                        }
                    }
                }
            }
            ExternalLinksSection(links: [ExternalLink(name: "External-link.bestdori", url: URL(string: "https://bestdori.com/info/songs/\(id)")!)])
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
