//===---*- Greatdori! -*---------------------------------------------------===//
//
// ReflectionView.swift
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
import ShazamKit
import SDWebImageSwiftUI
import UniformTypeIdentifiers

struct NeoReflectionView: View {
    @AppStorage("ReflectionBatchRetryFailedItem") private var batchRetryFailedItem = false
    @State private var singleMusicIDInput = ""
    @State private var singleMatchResults: [_DoriFrontend.Songs._NeoSongMatchResult.MatchItem]?
    @State private var batchMatchResults: [Int: _DoriFrontend.Songs._NeoSongMatchResult] = [:]
    @State private var batchResultFile: PropertyListFileDocument?
    @State private var isGettingBatchResult = false
    @State private var isBatchResultImporterPresented = false
    @State private var isBatchResultExporterPresented = false
    @State private var batchListSearchText = ""
    @State private var isBatchExportVisible = true
    @State private var isFetchingFromGreatdoriServer = false
    
    @State var allSongs: [PreviewSong] = []
    var body: some View {
        Form {
            Section("Single") {
                HStack {
                    TextField("Music ID", text: $singleMusicIDInput)
                    Button(action: {
                        guard let musicID = Int(singleMusicIDInput) else { return }
                        Task {
                            do {
                                singleMatchResults = try await matchMediaItems(for: musicID)
                            } catch {
                                print(error)
                            }
                        }
                    }, label: {
                        Text("Generate")
                    })
                }
                if let results = singleMatchResults {
                    ForEach(results, id: \.self) { result in
                        NeoMediaItemPreview(result)
                    }
                }
            }
            
            Section("Batch") {
                LazyVStack(alignment: .leading) {
                    HStack {
                        Group {
                            Button(action: {
                                Task {
                                    isGettingBatchResult = true
                                    var exceptions = batchMatchResults
                                    if batchRetryFailedItem {
                                        exceptions = exceptions.filter {
                                            if case .failure = $0.value {
                                                false
                                            } else { true }
                                        }
                                    }
                                    await matchAllMediaItems(except: Array(exceptions.keys)) { song, result in
                                        DispatchQueue.main.async {
                                            if let existingSong = batchMatchResults.keys.first(where: { $0 == song }) {
                                                batchMatchResults.updateValue(.init(result), forKey: existingSong)
                                            } else {
                                                batchMatchResults.updateValue(.init(result), forKey: song)
                                            }
                                        }
                                    }
                                    isGettingBatchResult = false
                                }
                            }, label: {
                                HStack {
                                    Text("Get All")
                                    if isGettingBatchResult {
                                        ProgressView()
                                            .controlSize(.small)
                                    }
                                }
                            })
                            Toggle("Retry Failed Items", isOn: $batchRetryFailedItem)
                                .toggleStyle(.checkbox)
                        }
                        .disabled(isGettingBatchResult)
                        
                        Spacer()
                        Button(action: {
                            Task {
                                isFetchingFromGreatdoriServer = true
                                do {
                                    let (data, _) = try await URLSession.shared.data(from: URL(string: "https://kashi.greatdori.com/MappedSongs.plist")!)
                                    let codedResults = try PropertyListDecoder()
                                        .decode([Int: _DoriFrontend.Songs._NeoSongMatchResult].self, from: data)
                                    
                                    await MainActor.run {
                                        batchMatchResults = codedResults
                                    }
                                } catch {
                                    print("Failed to load or decode plist:", error)
                                }
                                isFetchingFromGreatdoriServer = false
                            }
                        }, label: {
                            HStack {
                                if isFetchingFromGreatdoriServer {
                                    ProgressView()
                                        .controlSize(.small)
                                }
                                Text("Fetch Current")
                            }
                        })
                        .disabled(isFetchingFromGreatdoriServer)
                        
                        Button("Import...") {
                            isBatchResultImporterPresented = true
                        }
                        
                        Button("Export...") {
                            let encoder = PropertyListEncoder()
                            if let data = try? encoder.encode(batchMatchResults) {
                                batchResultFile = .init(data)
                                isBatchResultExporterPresented = true
                            }
                        }
                        .onAppear {
                            withAnimation {
                                isBatchExportVisible = true
                            }
                        }
                        .onDisappear {
                            withAnimation {
                                isBatchExportVisible = false
                            }
                        }
                        
                        Text("\(batchMatchResults.count) / \(allSongs.count)")
                    }
                    
                    if !batchMatchResults.isEmpty {
                        Divider()
                        ForEach(Array(batchMatchResults.keys).sorted(by: { $0 > $1 }), id: \.self) { key in
                            let correspondingPreviewSong = allSongs.first(where: { $0.id == key })
                            if batchListSearchText.isEmpty || (correspondingPreviewSong?.title.contains(where: { $0?.contains(batchListSearchText) ?? false}) ?? false) {
                                NeoSongReflectionResultsView(for: key, in: $batchMatchResults, songInfo: correspondingPreviewSong)
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
        .searchable(text: $batchListSearchText, prompt: "Search in Batch Result...")
        .navigationSubtitle("Reflection")
        .toolbar {
            ToolbarItem {
                if !isBatchExportVisible {
                    Button("Export...", systemImage: "square.and.arrow.up") {
                        let encoder = PropertyListEncoder()
                        if let data = try? encoder.encode(batchMatchResults) {
                            batchResultFile = .init(data)
                            isBatchResultExporterPresented = true
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                if let songs = await Song.all() {
                    allSongs = songs
                }
            }
        }
        .fileImporter(
            isPresented: $isBatchResultImporterPresented,
            allowedContentTypes: [.propertyList]
        ) { result in
            if case .success(let url) = result {
                _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                if let data = try? Data(contentsOf: url),
                   let codedResults = try? PropertyListDecoder().decode([Int: _DoriFrontend.Songs._NeoSongMatchResult].self, from: data) {
                    batchMatchResults = codedResults
                }
            }
        }
        .fileExporter(
            isPresented: $isBatchResultExporterPresented,
            document: batchResultFile,
            contentType: .propertyList,
            defaultFilename: "MappedSongs.plist"
        ) { _ in
            batchResultFile = nil
        }
    }
}


private struct NeoSongReflectionResultsView: View {
    @Binding var results: [Int: _DoriFrontend.Songs._NeoSongMatchResult]
    var song: Int
    var previewSong: PreviewSong?
    
    init(for song: Int, in results: Binding<[Int : _DoriFrontend.Songs._NeoSongMatchResult]>, songInfo: PreviewSong?) {
        self._results = results
        self.song = song
        self.previewSong = songInfo
    }
    
    @State private var isEditing = false
    @State private var saveFlag = false
    @State private var reReflectionStart = 30.0
    @State private var isReReflecting = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let previewSong {
                    Text(previewSong.musicTitle.forPreferredLocale() ?? "[No title]")
                        .textSelection(.enabled)
                    Text(verbatim: "#\(previewSong.id)")
                        .foregroundStyle(.gray)
                        .fontDesign(.monospaced)
                } else {
                    Text(verbatim: "#\(song)")
                        .foregroundStyle(.gray)
                        .fontDesign(.monospaced)
                }
                Spacer()
                switch results[song]! {
                case .success(let items):
                    if !items.isEmpty {
                        if items.contains(where: { $0.appleMusicID == nil }) {
                            BlockMark(character: "A", color: .yellow, description: "Missing Apple Music URL")
                        }
                        if items.contains(where: { $0.appleMusicID == nil && $0.shazamID == nil }) {
                            BlockMark(character: "S", color: .red, description: "Missing Shazam ID")
                        }
                        if items.contains(where: { $0.artworkURL == nil }) {
                            BlockMark(character: "C", color: .red, description: "Missing artwork")
                        }
                    } else {
                        BlockMark(character: "N", color: .purple, description: "Missing result")
                        .contextMenu {
                            Button(action: {
                                results[song] = .expectedEmpty
                            }, label: {
                                Label("Mark as Expected", systemImage: "checkmark.seal")
                            })
                        }
                    }
                    if !isEditing {
                        Button(action: {
                            isEditing = true
                        }, label: {
//                            Image(systemName: "pencil.line")
                            Text("Edit")
                        })
                    } else {
                        Button("Add", systemImage: "plus") {
                            switch results[song]! {
                            case .success(let items):
                                results.updateValue(
                                    .success(items + [.init(titleJP: "", artistJP: "")]),
                                    forKey: song
                                )
                            default:
                                results.updateValue(
                                    .success([.init(titleJP: "", artistJP: "")]),
                                    forKey: song
                                )
                            }
                        }
                        Button("Discard", systemImage: "xmark", role: .destructive) {
                            isEditing = false
                        }
                        .tint(.red)
                        Button("Apply", systemImage: "checkmark") {
                            Task {
                                saveFlag.toggle()
                                await Task.yield()
                                isEditing = false
                            }
                        }
                    }
                case .failure:
                    BlockMark(character: "!", color: .red, description: "Error")
                case .expectedEmpty:
                    BlockMark(character: "N", color: .gray, description: "Empty as expected")
                        .contextMenu {
                            Button(action: {
                                results[song] = .success([])
                            }, label: {
                                Label("Mark as Unexpected", systemImage: "seal")
                            })
                        }
                @unknown default:
                    EmptyView()
                }
            }
            
            HStack {
                if let previewSong {
                    Text(PreCache.current.bands.first { $0.id == previewSong.bandID }?.bandName.forPreferredLocale() ?? "[No Band]")
                        .foregroundStyle(.gray)
                        .padding(.top, -10)
                }
                Spacer()
                if case .success = results[song]!, isEditing {
                    Button {
                        Task {
                            isReReflecting = true
                            do {
                                let result = try await matchMediaItems(for: song, sliceFrom: reReflectionStart)
                                
                                results.updateValue(.success(result), forKey: song)
                                isEditing = false
                            } catch {
                                print(error)
                            }
                            isReReflecting = false
                        }
                    } label: {
                        HStack {
                            if isReReflecting {
                                ProgressView()
                                    .controlSize(.small)
                            }
                            Label("Re-Reflect from \(unsafe String(format: "%.1f", reReflectionStart))s", systemImage: "music.note.arrow.trianglehead.clockwise")
                        }
                    }
                    .disabled(isReReflecting)
                    Slider(value: $reReflectionStart, in: 0...100)
                        .labelsHidden()
                        .frame(width: 200)
                }
            }
            
            switch results[song]! {
            case .success(let items):
                if !isEditing {
                    ForEach(items, id: \.self) { item in
                        NeoMediaItemPreview(item)
                    }
                } else {
                    VStack {
                        ForEach(items.enumerated(), id: \.element.self) { index, item in
                            ItemEditView(
                                index: index,
                                item: item,
                                song: song,
                                allResults: $results,
                                saveFlag: saveFlag
                            )
                        }
                        .insert {
                            Divider()
                        }
                    }
                }
            case .failure(let error):
                Text(error)
                    .foregroundStyle(.red)
            case .expectedEmpty:
                Text("Marked as expected empty.")
                    .foregroundStyle(.secondary)
            @unknown default:
                EmptyView()
            }
        }
    }
    
    private struct ItemEditView: View {
        var index: Int
        var item: _DoriFrontend.Songs._NeoSongMatchResult.MatchItem
        var song: Int
        @Binding var allResults: [Int: _DoriFrontend.Songs._NeoSongMatchResult]
        var saveFlag: Bool
        @State private var titleJP = ""
        @State private var titleEN = ""
        @State private var artistJP = ""
        @State private var artistEN = ""
        @State private var artworkURL = ""
        @State private var appleMusicID = 0
        @State private var shazamID = 0
        var body: some View {
            VStack {
                HStack {
                    Spacer()
                    Button("Remove Reference", systemImage: "trash", role: .destructive) {
                        allResults[song]!.castSome.remove(at: index)
                    }
                    .tint(.red)
                }
                Group {
                    TextField("Title JP", text: $titleJP)
                    TextField("Title EN", text: $titleEN)
                    TextField("Artist JP", text: $artistJP)
                    TextField("Artist EN", text: $artistEN)
                    TextField("Artwork URL", text: $artworkURL)
                    TextField("Apple Music ID", value: $appleMusicID, formatter: NumberFormatter())
                    TextField("Shazam ID", value: $shazamID, formatter: NumberFormatter())
                }
                .padding(5)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .tertiarySystemFill))
                }
            }
            .onAppear {
                titleJP = item.titleJP
                titleEN = item.titleEN ?? ""
                artistJP = item.artistJP
                artistEN = item.artistEN ?? ""
                artworkURL = item.artworkURL?.absoluteString ?? ""
                appleMusicID = item.appleMusicID ?? 0
                shazamID = item.shazamID ?? 0
            }
            .onChange(of: saveFlag) {
                allResults[song]!.castSome[index] = _DoriFrontend.Songs._NeoSongMatchResult.MatchItem.init(
                    titleJP: titleJP,
                    titleEN: titleEN.isEmpty ? nil : titleEN,
                    artistJP: artistJP,
                    artistEN: artistEN.isEmpty ? nil : artistEN,
                    artworkURL: artworkURL.isEmpty ? nil : .init(string: artworkURL),
                    appleMusicID: appleMusicID < 0 ? nil : appleMusicID,
                    shazamID: shazamID < 0 ? nil : shazamID
                )
            }
        }
    }
}

private struct NeoMediaItemPreview: View {
    var item: _DoriFrontend.Songs._NeoSongMatchResult.MatchItem
    
    init(_ item: _DoriFrontend.Songs._NeoSongMatchResult.MatchItem) {
        self.item = item
    }
    
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        HStack {
            WebImage(url: item.artworkURL) { image in
                image
            } placeholder: {
                Rectangle()
                    .fill(Color.gray)
            }
            .resizable()
            .cornerRadius(5)
            .scaledToFit()
            .frame(width: 75, height: 75)
            .onTapGesture {
                if let url = item.appleMusicURL {
                    openURL(url)
                }
            }
            VStack(alignment: .leading) {
                Text(item.title())
                Text(item.artist())
                    .foregroundStyle(.secondary)
//                Text("\(unsafe String(format: "%.2f", item.confidence * 100))%")
            }
            Spacer()
//            if let url = item.appleMusicURL {
//                Button(action: {
//                    openURL(url)
//                }, label: {
//                    HStack {
//                        Image(_internalSystemName: "music")
//                        Text("Open in Apple Music")
//                        Image(systemName: "arrow.up.forward.app")
//                    }
//                    .foregroundStyle(.white)
//                    .padding(5)
//                    .padding(.horizontal, 5)
//                    .background {
//                        RoundedRectangle(cornerRadius: 8)
////                            .fill(Color(red: 230 / 255, green: 63 / 255, blue: 69 / 255))
//                            .foregroundStyle(.secondary)
//                    }
//                })
//                .buttonStyle(.borderless)
//            }
        }
    }
}




