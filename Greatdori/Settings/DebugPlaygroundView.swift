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
        Button(action: {
            Task {
                let allSongs = await Song.all()
                guard let allSongs else { fatalError() }
                
                for song in allSongs {
                    if (song.musicVideos?.keys.count ?? 0) > 1 {
                        print("#\(song.id) - \(song.title.forPreferredLocale())")
                    }
                }
            }
        }, label: {
            Text(verbatim: "1")
        })
    }
}
