//===---*- Greatdori! -*---------------------------------------------------===//
//
// DebugPlaygroundView.swift
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

struct DebugPlaygroundView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .center) {
                Button(action: {
                    Task {
                        print("Start")
                        let allSongs = await Song.all()
                        guard let allSongs else { fatalError() }
                        
                        for previewSong in allSongs {
                            var song = await Song(id: previewSong.id)
                            
                            guard let song else { fatalError() }
                            for (_, value) in song.musicVideos ?? [:] {
                                for endDate in value.endAt.compactMap({ $0 }) {
                                    if endDate.timeIntervalSince1970 < 3786879600 {
                                        print("#\(song.id) \(song.title)")
                                    }
                                }
                            }
                        }
                        
                        print("Done")
                    }
                }, label: {
                    Text(verbatim: "1")
                })
            }
        }
    }
}

//extension _DoriAPI.Songs.Song.MusicVideoMetadata: Sequence {}
