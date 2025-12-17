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
import ArgumentParser
@_private(sourceFile: "FrontendSong.swift") import DoriKit

typealias Lyrics = _DoriFrontend.Songs.Lyrics

/// A utility for generating lyric files.
///
/// This app is only used for development and is not intended to publish.
@main
struct GreatLyricsEntry {
    static func main() async {
        if CommandLine.arguments.contains(where: {
            GreatLyricsCommandLine.Action.allCases
                .filter { $0 != .none }
                .map { "--\($0.rawValue)" }
                .contains($0)
        }) {
            await GreatLyricsCommandLine.main(nil)
        } else {
            GreatLyricsApp.main()
        }
    }
}

struct GreatLyricsCommandLine: AsyncParsableCommand {
    @Flag var action: Action = .none
    
    @Option(name: [.long], transform: URL.init(fileURLWithPath:))
    var input: URL? = nil
    @Option(name: [.long], transform: URL.init(fileURLWithPath:))
    var output: URL? = nil
    
    @Argument(parsing: .allUnrecognized) var other: [String] = []
    
    func validate() throws {
        if let input {
            guard FileManager.default.fileExists(atPath: input.path) else {
                throw CocoaError(.fileNoSuchFile)
            }
        }
    }
    
    mutating func run() async throws {
        switch action {
        case .none:
            preconditionFailure()
        case .reflect:
            guard let input else {
                fatalError("Reflection requires an input file")
            }
            guard let output else {
                fatalError("Reflection requires an output file path")
            }
            try await reflectNewSongs(into: output, from: input)
        }
    }
    
    enum Action: String, EnumerableFlag {
        case none
        case reflect
    }
}

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
