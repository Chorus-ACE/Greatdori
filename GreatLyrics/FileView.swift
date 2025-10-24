//===---*- Greatdori! -*---------------------------------------------------===//
//
// FileView.swift
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
import UniformTypeIdentifiers
@_private(sourceFile: "FrontendSong.swift") import DoriKit

struct FileView: View {
    @Binding var lyrics: Lyrics
    @State var isLyricsImporterPresented = false
    @State private var exportingLyricsFile: LyricsFile?
    @State var isLyricsExporterPresented = false
    @State var isJSONRepCopied = false
    @State var isJSONRepExpanded = false
    @State var showingJSONRep = ""
    var body: some View {
        Form {
            Section {
                TextField("Identifier", text: .init {
                    String(lyrics.id)
                } set: {
                    lyrics.id = Int($0) ?? 0
                })
            } footer: {
                Text("Matching the corresponding song ID in Bestdori! database.")
            }
            Section {
                HStack {
                    Text("Decodable File")
                    Spacer()
                    Button("Import...") {
                        isLyricsImporterPresented = true
                    }
                    Button("Export...") {
                        exportingLyricsFile = .init(lyrics)
                        isLyricsExporterPresented = true
                    }
                }
                HStack {
                    Button {
                        showingJSONRep = jsonRep(formatting: [.prettyPrinted, .sortedKeys])
                        withAnimation(.easeOut(duration: 0.3)) {
                            isJSONRepExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: "chevron.forward")
                            .foregroundStyle(.gray)
                            .rotationEffect(.degrees(isJSONRepExpanded ? 90 : 0))
                    }
                    .buttonStyle(.borderless)
                    Text("JSON Representation")
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(jsonRep(), forType: .string)
                        withAnimation(.easeOut(duration: 0.1)) {
                            isJSONRepCopied = true
                        } completion: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                withAnimation(.easeOut(duration: 0.1)) {
                                    isJSONRepCopied = false
                                }
                            }
                        }
                    } label: {
                        if !isJSONRepCopied {
                            Text("Copy")
                        } else {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(.green)
                        }
                    }
                }
                if isJSONRepExpanded {
                    TextEditor(text: $showingJSONRep)
                        .onChange(of: showingJSONRep) {
                            let decoder = JSONDecoder()
                            if let _data = showingJSONRep.data(using: .utf8),
                               let lyrics = try? decoder.decode(Lyrics.self, from: _data) {
                                self.lyrics = lyrics
                            }
                        }
                }
            }
        }
        .formStyle(.grouped)
        .navigationSubtitle("File")
        .fileImporter(isPresented: $isLyricsImporterPresented, allowedContentTypes: [.propertyList]) { result in
            if case let .success(url) = result {
                importLyrics(from: url)
            }
        }
        .fileExporter(isPresented: $isLyricsExporterPresented, document: exportingLyricsFile, contentType: .propertyList, defaultFilename: String(lyrics.id)) { _ in
            exportingLyricsFile = nil
        }
    }
    
    func importLyrics(from url: URL) {
        _ = url.startAccessingSecurityScopedResource()
        let decoder = PropertyListDecoder()
        if let _data = try? Data(contentsOf: url),
           let lyrics = try? decoder.decode(Lyrics.self, from: _data) {
            if self.lyrics != .init(
                id: 0,
                version: 1,
                lyrics: [],
                mainStyle: nil,
                metadata: .init(legends: [])
            ) {
                let alert = NSAlert.init()
                alert.addButton(withTitle: String(localized: "Cancel"))
                alert.addButton(withTitle: String(localized: "Continue"))
                alert.messageText = String(localized: "Load New Lyrics from File?")
                alert.informativeText = String(localized: "This will replace current loaded lyrics data.")
                let response = alert.runModal()
                if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                    url.stopAccessingSecurityScopedResource()
                    return
                }
            }
            self.lyrics = lyrics
        }
        url.stopAccessingSecurityScopedResource()
    }
    func jsonRep(formatting: JSONEncoder.OutputFormatting = .sortedKeys) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = formatting
        return String(data: try! encoder.encode(lyrics), encoding: .utf8)!
    }
}

private struct LyricsFile: FileDocument {
    static let readableContentTypes = [UTType.propertyList]
    
    var lyrics: Lyrics
    
    init(_ lyrics: Lyrics) {
        self.lyrics = lyrics
    }
    
    init(configuration: ReadConfiguration) throws {
        let decoder = PropertyListDecoder()
        if let _data = configuration.file.regularFileContents {
            let lyrics = try decoder.decode(Lyrics.self, from: _data)
            self.lyrics = lyrics
        } else {
            throw CocoaError(.coderReadCorrupt)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = PropertyListEncoder()
        let data = try encoder.encode(lyrics)
        return FileWrapper(regularFileWithContents: data)
    }
}
