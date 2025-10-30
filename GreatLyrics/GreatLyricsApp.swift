//===---*- Greatdori! -*---------------------------------------------------===//
//
// GreatLyricsApp.swift
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
@_private(sourceFile: "FrontendSong.swift") import DoriKit

typealias Lyrics = _DoriFrontend.Songs.Lyrics

/// A utility for generating lyric files.
///
/// This app is only used for development and is not intended to publish.
@main
struct GreatLyricsApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        
        WindowGroup("Style Editor", id: "StyleEditor", for: StyleEditorWindowData.self) { $data in
            if let data {
                let ptrUpdate = unsafe UnsafePointer<(Lyrics.Style) -> Void>(bitPattern: data.update)!
                StyleEditorView(style: data.style, update: unsafe ptrUpdate.pointee)
            }
        }
    }
}

struct StyleEditorWindowData: Hashable, Codable {
    var style: Lyrics.Style
    @unsafe var update: Int
}
