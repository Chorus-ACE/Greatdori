//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongListView.swift
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

struct SongListView: View {
    @State var filter = DoriFilter.recoverable(id: "SongList")
    @State var sorter = DoriSorter.recoverable(id: "SongList")
    @State var songs: [PreviewSong]?
    @State var isFilterSettingsPresented = false
    @State var isSearchPresented = false
    @State var searchInput = ""
    @State var searchedSongs: [PreviewSong]?
    @State var availability = true
    var body: some View {
        List {
            if let songs = searchedSongs ?? songs {
                ForEach(songs) { song in
                    NavigationLink(destination: { SongDetailView(id: song.id) }) {
                        SongCardView(song)
                    }
                }
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入歌曲时出错", systemImage: "_song", retryHandler: getSongs)
                }
            }
        }
        .navigationTitle("歌曲")
        .sheet(isPresented: $isFilterSettingsPresented) {
            Task {
                songs = nil
                await getSongs()
            }
        } content: {
            FilterView(filter: $filter, sorter: $sorter, includingKeys: [
                .songType,
                .band,
                .server,
                .released
            ], includingKeywords: [
                .releaseDate(in: .jp),
                .releaseDate(in: .en),
                .releaseDate(in: .tw),
                .releaseDate(in: .cn),
                .releaseDate(in: .kr),
                .difficultyReleaseDate(in: .jp),
                .difficultyReleaseDate(in: .en),
                .difficultyReleaseDate(in: .tw),
                .difficultyReleaseDate(in: .cn),
                .difficultyReleaseDate(in: .kr),
                .mvReleaseDate(in: .jp),
                .mvReleaseDate(in: .en),
                .mvReleaseDate(in: .tw),
                .mvReleaseDate(in: .cn),
                .mvReleaseDate(in: .kr),
                .level(for: .easy),
                .level(for: .normal),
                .level(for: .hard),
                .level(for: .expert),
                .level(for: .special),
                .id
            ]) {
                if let songs {
                    SearchView(items: songs, text: $searchInput) { result in
                        searchedSongs = result
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    isFilterSettingsPresented = true
                }, label: {
                    Image(systemName: "line.3.horizontal.decrease")
                })
                .tint(filter.isFiltered || !searchInput.isEmpty ? .accent : nil)
            }
        }
        .task {
            await getSongs()
        }
    }
    
    func getSongs() async {
        availability = true
        withDoriCache(id: "SongList_\(filter.identity)_\(sorter.identity)") {
            await PreviewSong.all()?
                .filter(withDoriFilter: filter)
                .sorted(withDoriSorter: sorter)
        }.onUpdate {
            if let songs = $0 {
                self.songs = songs
            } else {
                availability = false
            }
        }
    }
}
