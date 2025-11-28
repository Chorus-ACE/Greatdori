//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongDetailMusicMovieView.swift
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

struct SongDetailMusicMovieView: View {
    let musicVideos: [String: _DoriAPI.Songs.MusicVideoMetadata]?
    @State var selectedMV: String? = nil
    var body: some View {
        if let musicVideos, !musicVideos.isEmpty {
            LazyVStack(pinnedViews: .sectionHeaders) {
                Section(content: {
                    VStack {
                        if let mv = musicVideos[selectedMV ?? ""] {
                            CustomGroupBox {
                                ListItem(title: {
                                    Text("Song.music-video.title")
                                }, value: {
                                    Text(verbatim: "111")
                                })
                            }
                        }
                    }
                    .frame(maxWidth: infoContentMaxWidth)
                }, header: {
                    HStack {
                        Text("Song.music-video")
                            .font(.title2)
                            .bold()
                        DetailSectionOptionPicker(selection: $selectedMV, options: Array(musicVideos.keys))
                        Spacer()
                    }
                    .frame(maxWidth: 615)
                })
            }
            .onAppear {
                if selectedMV == nil {
                    selectedMV = musicVideos.first?.key
                }
            }
        }
    }
}
