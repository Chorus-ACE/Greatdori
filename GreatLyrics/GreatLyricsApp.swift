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

typealias Lyrics = DoriFrontend.Songs.Lyrics

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
    
    @Option(name: [.long])
    var token: String? = nil
    
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
            guard let token else {
                fatalError("Reflection requires a MusicKit token")
            }
            MusicKitTokenManager.shared.token = token
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

// MARK: CustomGroupBox
struct CustomGroupBox<Content: View>: View {
    let content: () -> Content
    var cornerRadius: CGFloat
    var showGroupBox: Bool
    
    init(
        showGroupBox: Bool = true,
        cornerRadius: CGFloat = 15,
        useExtenedConstraints: Bool = false,
        strokeLineWidth: CGFloat = 0,
        customGroupBoxVersion: Int? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.showGroupBox = showGroupBox
        self.cornerRadius = cornerRadius
        self.content = content
    }
    
    var body: some View {
        Group {
            content()
        }
            .padding(.all, showGroupBox ? nil : 0)
            .background {
                if showGroupBox {
                    GeometryReader { geometry in
                        ZStack {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(.black.opacity(0.1))
                                .offset(y: 2)
                                .blur(radius: 2)
                                .mask {
                                    Rectangle()
                                        .size(width: geometry.size.width + 18, height: geometry.size.height + 18)
                                        .offset(x: -9, y: -9)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: cornerRadius)
                                                .blendMode(.destinationOut)
                                        }
                                }
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(.black.opacity(0.1))
                                .offset(y: 2)
                                .blur(radius: 4)
                                .mask {
                                    Rectangle()
                                        .size(width: geometry.size.width + 60, height: geometry.size.height + 60)
                                        .offset(x: -30, y: -30)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: cornerRadius)
                                                .blendMode(.destinationOut)
                                        }
                                }
                            
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(Color(.floatingCard))
                        }
                    }
                    
                }
            }
            .overlay {
                if showGroupBox {
                LinearGradient(
                    colors: [
                        Color(.floatingCardTopBorder),
                        Color(.floatingCard)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .mask {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.clear)
                        .stroke(.black, style: .init(lineWidth: 1))
                }
                .allowsHitTesting(false)
            }
        }
        // We pass the group box status bidirectionally to allow
        // other views that suppress the custom group box
        // to provide their own representation
        .preference(key: CustomGroupBoxActivePreference.self, value: showGroupBox)
    }
}


struct CustomGroupBoxActivePreference: PreferenceKey {
    @safe nonisolated(unsafe) static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}
