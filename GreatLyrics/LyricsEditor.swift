//===---*- Greatdori! -*---------------------------------------------------===//
//
// LyricsEditor.swift
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

import Alamofire
import AppKit
import AVKit
import DoriKit
import SDWebImageSwiftUI
import SwiftUI
import UniformTypeIdentifiers

struct LyricsEditorView: View {
    @State var fileImporterIsPresented = false
    @State var fileExporterIsPresented = false
    @State var exportingFile: PropertyListFileDocument?
    //    @State private var batchResultFile: PropertyListFileDocument?
    @State var allLyrics: [Int: PlainLyrics] = [:]
    @State var allSongs: [PreviewSong] = []
    @State var searchText = ""
    @State var isFocusing = false
    var body: some View {
        Group {
            if isFocusing {
                LyricsFocusView(allLyrics: $allLyrics, allSongs: $allSongs)
            } else {
                Form {
                    Section {
                        HStack {
                            Button(action: {
                                for song in allSongs {
                                    if !allLyrics.contains(where: { $0.key == song.id }) {
                                        allLyrics.updateValue(PlainLyrics(lyrics: "", source: ""), forKey: song.id)
                                    }
                                }
                            }, label: {
                                Text("Add All Unlisted")
                            })
                            Spacer()
                            Button(action: {
                                fileImporterIsPresented = true
                            }, label: {
                                Text("Import...")
                            })
                            Button(action: {
                                let encoder = PropertyListEncoder()
                                if let data = try? encoder.encode(allLyrics) {
                                    exportingFile = .init(data)
                                    fileExporterIsPresented = true
                                }
                            }, label: {
                                Text("Export...")
                            })
                        }
                    }
                    
                    if !allLyrics.isEmpty {
                        Section {
                            LazyVStack {
                                ForEach(Array(allLyrics.keys).sorted(by: { $0 > $1 }), id: \.self) { key in
                                    let correspondingPreviewSong = allSongs.first(where: { $0.id == key })
                                    if searchText.isEmpty || (correspondingPreviewSong?.title.contains(where: { $0?.contains(searchText) ?? false}) ?? false) {
                                        LyricsItemView(for: key, in: $allLyrics, songInfo: correspondingPreviewSong)
                                    }
                                }
                                .insert {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .formStyle(.grouped)
                .searchable(text: $searchText)
            }
        }
        .toolbar {
            ToolbarItem {
                Toggle(isOn: $isFocusing, label: {
                    Label("Focus Mode", systemImage: "book")
                })
            }
        }
        .fileImporter(
            isPresented: $fileImporterIsPresented,
            allowedContentTypes: [.propertyList]
        ) { result in
            if case .success(let url) = result {
                _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                if let data = try? Data(contentsOf: url),
                   let decodedResults = try? PropertyListDecoder().decode([Int: PlainLyrics].self, from: data) {
                    allLyrics = decodedResults
                }
            }
        }
        .fileExporter(
            isPresented: $fileExporterIsPresented,
            document: exportingFile,
            contentType: .propertyList,
            defaultFilename: "PlainLyrics.plist"
        ) { _ in
            exportingFile = nil
        }
        .onAppear {
            allLyrics = PlainLyricsStore.shared.load() ?? [:]
            Task {
                allSongs = await Song.all() ?? []
            }
        }
        .onChange(of: allLyrics, {
            PlainLyricsStore.shared.save(allLyrics)
        })
    }
}

struct LyricsFocusView: View {
    @Environment(\.openURL) var openURL
    @Binding var allLyrics: [Int: PlainLyrics]
    @Binding var allSongs: [PreviewSong]
    @State var focusingItemIndex: Int = 0
    @State var focusPendingItems: [Int] = []
    
    @State var focusLyrics = ""
    @State var focusSource = ""
    
    @State var isFetchingLyricsFromMusixmatch = false
    @State var lyricsFetchField = ""
    @State var isFetching = false
    @State var fetchingHasFailed = false
    var body: some View {
        Group {
            if !focusPendingItems.isEmpty {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
                            CustomGroupBox {
                                LyricsItemView(for: focusPendingItems[focusingItemIndex], in: $allLyrics, songInfo: allSongs.first(where: { $0.id == focusPendingItems[focusingItemIndex] }), interactless: true)
                                    .frame(height: 80)
                            }
                            CustomGroupBox {
                                HStack {
                                    CompactAudioPlayer(url: URL(string: "https://bestdori.com/assets/jp/sound/bgm\(addZeros(focusPendingItems[focusingItemIndex]))_rip/bgm\(addZeros(focusPendingItems[focusingItemIndex])).mp3")!)
                                    Spacer()
                                    Text("#\(String(focusPendingItems[focusingItemIndex])) (\(focusingItemIndex+1)/\(focusPendingItems.count))")
                                        .fontDesign(.monospaced)
                                    Button(action: {
                                        if focusingItemIndex > 0 {
                                            focusingItemIndex -= 1
                                        }
                                    }, label: {
                                        Image(systemName: "chevron.backward")
                                    })
                                    .disabled(focusingItemIndex <= 0)
                                    .keyboardShortcut(.leftArrow, modifiers: [.command, .option])
                                    Button(action: {
                                        if focusingItemIndex < focusPendingItems.count-1 {
                                            focusingItemIndex += 1
                                        }
                                    }, label: {
                                        Image(systemName: "chevron.forward")
                                    })
                                    .disabled(focusingItemIndex >= focusPendingItems.count-1)
                                    .keyboardShortcut(.rightArrow, modifiers: [.command, .option])
                                }
                            }
                            Rectangle()
                                .frame(width: 0, height: 15)
                                .opacity(0)
                            
                            CustomGroupBox {
                                HStack {
                                    TextField("Musixmatch URL", text: $lyricsFetchField)
                                    Button(action: {
                                        Task {
                                            fetchingHasFailed = false
                                            isFetching = true
                                            let fetchedLyrics = await fetchLyricsFromMusixmatch(URL(string: lyricsFetchField)!)
                                            if let fetchedLyrics {
                                                focusLyrics = fetchedLyrics
                                                focusSource = "Musixmatch"
                                            } else {
                                                fetchingHasFailed = true
                                            }
                                            isFetching = false
                                        }
                                    }, label: {
                                        HStack {
                                            if isFetching {
                                                ProgressView()
                                                    .controlSize(.small)
                                            }
                                            if fetchingHasFailed {
                                                Text("Parse (Error)")
                                            } else {
                                                Text("Parse")
                                            }
                                        }
                                    })
                                    .disabled(isFetching)
                                    .disabled(URL(string: lyricsFetchField) == nil)
                                }
                            }
                            CustomGroupBox {
                                HStack {
                                    Text("Source")
                                        .foregroundStyle(focusSource.isEmpty ? .yellow : .primary)
                                    Spacer()
                                    TextField("", text: $focusSource)
                                    Menu(content: {
                                        ForEach(["Musixmatch", "LyricFind"] + [""], id: \.self) { item in
                                            Button(action: {
                                                focusSource = item
                                            }, label: {
                                                Text(item.isEmpty ? "(Clear)" : item)
                                            })
                                        }
                                    }, label: {
                                        Text("Commons")
                                    })
                                }
                            }
                            CustomGroupBox {
//                                NSTextViewWrapper(text: $focusLyrics)
//                                TextField("", text: $focusLyrics)
                                NSTextViewWrapper(text: $focusLyrics)
                                    .typesettingLanguage(.explicit(.init(identifier: "ja")))
                                    .frame(height: 1500)
                            }
                            CustomGroupBox {
                                HStack {
                                    Button(action: {
                                        let previewSong = allSongs.first(where: { $0.id == focusPendingItems[focusingItemIndex] })
                                        var components = URLComponents(string: "https://www.google.com/search")
                                        components?.queryItems = [
                                            URLQueryItem(name: "q", value: "\(previewSong?.title.forLocale(.jp) ?? "") Lyrics")
                                        ]
                                        if let url = components?.url {
                                            openURL(url)
                                        }
                                    }, label: {
                                        Text("Search Google")
                                    })
                                    .keyboardShortcut("G", modifiers: [.command])
                                    Button(action: {
                                        let previewSong = allSongs.first(where: { $0.id == focusPendingItems[focusingItemIndex] })
                                        var components = URLComponents(string: "https://www.google.com/search")
                                        components?.queryItems = [
                                            URLQueryItem(name: "q", value: "\(previewSong?.title.forLocale(.jp) ?? "") site:musixmatch.com")
                                        ]
                                        if let url = components?.url {
                                            openURL(url)
                                        }
                                    }, label: {
                                        Text("Search Musixmatch")
                                    })
                                    .keyboardShortcut("X", modifiers: [.command])
                                    Button(action: {
                                        focusingItemIndex = 0
                                    }, label: {
                                        Text("Go to First")
                                    })
                                    Button(action: {
                                        focusingItemIndex = focusPendingItems.count-1
                                    }, label: {
                                        Text("Go to Last")
                                    })
                                    Spacer()
                                }
                            }
                        }
                        .frame(maxWidth: 615)
                        Spacer(minLength: 0)
                    }
                    .padding()
                }
                .navigationTitle("\(allSongs.first(where: { $0.id == focusPendingItems[focusingItemIndex] })?.title.forLocale(.jp) ?? "Unknown Song")")
                .navigationSubtitle(Text("#\(String(focusPendingItems[focusingItemIndex])) (\(focusingItemIndex+1)/\(focusPendingItems.count))"))
            } else {
                ContentUnavailableView("No Pending Item", systemImage: "book", description: Text("Every item is ready for distribution."))
            }
        }
        .onAppear {
            focusingItemIndex = 0
            focusPendingItems = []
            for (key, value) in allLyrics {
                if value.lyrics.count < 50 || value.source.isEmpty || value.source == "Uta-Net" {
                    focusPendingItems.append(key)
                }
            }
            focusPendingItems.sort()
            focusLyrics = allLyrics[focusPendingItems[focusingItemIndex]]!.lyrics
            focusSource = allLyrics[focusPendingItems[focusingItemIndex]]!.source
        }
        .onChange(of: focusingItemIndex) {
            focusLyrics = allLyrics[focusPendingItems[focusingItemIndex]]!.lyrics
            focusSource = allLyrics[focusPendingItems[focusingItemIndex]]!.source
            lyricsFetchField = ""
        }
        .onChange(of: focusLyrics, focusSource) {
            allLyrics.updateValue(PlainLyrics(lyrics: focusLyrics, source: focusSource), forKey: focusPendingItems[focusingItemIndex])
        }
    }
    
    func addZeros(_ integer: Int) -> String {
        return "\(integer<100 ? "0" : "")\(integer<10 ? "0" : "")\(String(integer))"
    }
}
 
struct LyricsItemView: View {
    @Binding var results: [Int: PlainLyrics]
    var song: Int
    var previewSong: PreviewSong?
    var interactless: Bool = false
    
    @State var songBand: Band? = nil
    @State var headerName: String? = nil
    @State var isEditing = false
    
    init(for song: Int, in results: Binding<[Int: PlainLyrics]>, songInfo: PreviewSong?, interactless: Bool = false) {
        self._results = results
        self.song = song
        self.previewSong = songInfo
        self.interactless = interactless
    }
    
    let coverSideLength: CGFloat = 80
    let coverCornerRadius: CGFloat = 3
    
    var body: some View {
        HStack {
            if let previewSong {
                WebImage(url: previewSong.jacketImageURL) { image in
                    image
                        .resizable()
                        .antialiased(true)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: coverSideLength, height: coverSideLength)
                        .cornerRadius(coverCornerRadius)
                } placeholder: {
                    RoundedRectangle(cornerRadius: coverCornerRadius)
                        .fill(.placeholder)
                        .frame(width: coverSideLength, height: coverSideLength)
                }
                .interpolation(.high)
            }
            VStack(alignment: .leading) {
                if let headerName {
                    Text(headerName)
                        .bold()
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                        .fontWidth(.expanded)
                }
                HStack {
                    if let previewSong {
                        Text(previewSong.title.forPreferredLocale() ?? "(No Title)")
                        Text("#\(String(song))").foregroundStyle(.secondary)
                    } else {
                        Text("#\(String(song))")
                    }
                }
                if !interactless {
                    Group {
                        Text(results[song]!.lyrics.isEmpty ? "(Empty Lyrics)" : results[song]!.lyrics)
                            .lineLimit(2)
                            .typesettingLanguage(.explicit(.init(identifier: "ja")))
                            .foregroundStyle(results[song]!.lyrics.isEmpty ? .red : .secondary)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            Spacer()
            VStack {
                HStack {
                    let result = results[song]!
                    if result.source.isEmpty {
                        BlockMark(character: "W", color: .red, description: "Source Missing") // (W)here
                    }
                    if result.lyrics.isEmpty {
                        BlockMark(character: "E", color: .red, description: "Empty Lyrics") // (E)mpty
                    } else if result.lyrics.count < 50 {
                        BlockMark(character: "S", color: .yellow, description: "Lyrics Too Short") // (S)hort
                    }
                    if !interactless {
                        Button(action: {
                            isEditing = true
                        }, label: {
                            Text("Edit")
                        })
                    } else if !result.source.isEmpty && result.lyrics.count >= 50 {
                        BlockMark(character: "G", color: .green, description: "No issue.") // (G)reat
                    }
                }
                Spacer()
            }
        }
        .sheet(isPresented: $isEditing, content: {
            LyricsEditView(allLyrics: $results, songID: song)
        })
        .onChange(of: song, initial: true) {
            songBand = DoriCache.preCache.bands.first { $0.id == previewSong?.bandID ?? -1 }
            if let previewSong {
                headerName = previewSong.tag == .anime ? "Cover" : songBand?.bandName.forPreferredLocale()?.uppercased() ?? nil
            } else {
                headerName = nil
            }
        }
    }
}

struct LyricsEditView: View {
    @Binding var allLyrics: [Int: PlainLyrics]
//    @Binding var allSongs: [PreviewSong]
    var songID: Int
    
    @State var focusLyrics = ""
    @State var focusSource = ""
    var body: some View {
        Form {
            TextField("Source", text: $focusSource)
            NSTextViewWrapper(text: $focusLyrics)
                .typesettingLanguage(.explicit(.init(identifier: "ja")))
                .frame(height: 300)
//            Menu(content: {
//                ForEach(["Musixmatch", "LyricFind", "Uta-Net"] + [""], id: \.self) { item in
//                    Button(action: {
//                        focusSource = item
//                    }, label: {
//                        Text(item.isEmpty ? "(Clear)" : item)
//                    })
//                }
//            }, label: {
//                Text("Commons")
//            })
        }
        .formStyle(.grouped)
        .onAppear {
            focusLyrics = allLyrics[songID]!.lyrics
            focusSource = allLyrics[songID]!.source
        }
        .onChange(of: focusLyrics, focusSource) {
            allLyrics.updateValue(PlainLyrics(lyrics: focusLyrics, source: focusSource), forKey: songID)
        }
    }
}

struct PlainLyrics: Hashable, Codable, Sendable {
    var lyrics: String
    var source: String
}

struct NSTextViewWrapper: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = NSTextView()
        textView.isRichText = false
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = .systemFont(ofSize: NSFont.systemFontSize)
        textView.delegate = context.coordinator

        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.documentView = textView

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }

        // 避免死循环：只有在内容不一致时才更新
        if textView.string != text {
            textView.string = text
        }
    }

    // MARK: - Coordinator
    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: NSTextViewWrapper

        init(_ parent: NSTextViewWrapper) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

final class PlainLyricsStore {
    @MainActor static let shared = PlainLyricsStore()

    private let url: URL = {
        let folder = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!

        let appFolder = folder.appendingPathComponent("YourAppName", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: appFolder,
            withIntermediateDirectories: true
        )

        return appFolder.appendingPathComponent("plain_lyrics.json")
    }()

    func save(_ value: [Int: PlainLyrics]) {
        do {
            let data = try JSONEncoder().encode(value)
            try data.write(to: url, options: .atomic)
        } catch {
            print("Save failed:", error)
        }
    }

    func load() -> [Int: PlainLyrics] {
        guard let data = try? Data(contentsOf: url),
              let value = try? JSONDecoder().decode([Int: PlainLyrics].self, from: data)
        else {
            return [:]
        }
        return value
    }
}
