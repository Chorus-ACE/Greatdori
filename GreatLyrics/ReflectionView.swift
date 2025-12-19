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

struct ReflectionView: View {
    @AppStorage("ReflectionBatchRetryFailedItem") private var batchRetryFailedItem = false
    @State private var singleMusicIDInput = ""
    @State private var singleMatchResults: [CodableMatchResult.CodableMatchItem]?
    @State private var totalSongCount = 0
    @State private var batchMatchResults: [PreviewSong: CodableMatchResult] = [:]
    @State private var batchResultFile: PropertyListFileDocument?
    @State private var isGettingBatchResult = false
    @State private var isBatchResultImporterPresented = false
    @State private var isBatchResultExporterPresented = false
    @State private var batchListSearchText = ""
    @State private var isBatchExportVisible = true
    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("Music ID", text: $singleMusicIDInput)
                    Button("Generate") {
                        guard let musicID = Int(singleMusicIDInput) else { return }
                        Task {
                            do {
                                singleMatchResults = try await matchMediaItems(for: musicID).map {
                                    .init($0)
                                }
                            } catch {
                                print(error)
                            }
                        }
                    }
                }
                if let results = singleMatchResults {
                    ForEach(results) { result in
                        MediaItemPreview(result)
                    }
                }
            } header: {
                Text("Single")
            }
            Section {
                LazyVStack(alignment: .leading) {
                    HStack {
                        Group {
                            Button {
                                Task {
                                    isGettingBatchResult = true
                                    var exceptions = batchMatchResults
                                    if batchRetryFailedItem {
                                        exceptions = exceptions.filter {
                                            if case .none = $0.value {
                                                false
                                            } else { true }
                                        }
                                    }
                                    await matchAllMediaItems(except: Array(exceptions.keys)) { song, result in
                                        DispatchQueue.main.async {
                                            if let existingSong = batchMatchResults.keys.first(where: { $0.id == song.id }) {
                                                batchMatchResults.updateValue(.init(result), forKey: existingSong)
                                            } else {
                                                batchMatchResults.updateValue(.init(result), forKey: song)
                                            }
                                        }
                                    }
                                    isGettingBatchResult = false
                                }
                            } label: {
                                HStack {
                                    Text("Get All")
                                    if isGettingBatchResult {
                                        ProgressView()
                                            .controlSize(.small)
                                    }
                                }
                            }
                            Toggle("Retry Failed Items", isOn: $batchRetryFailedItem)
                                .toggleStyle(.checkbox)
                        }
                        .disabled(isGettingBatchResult)
                        Spacer()
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
                        Text("\(batchMatchResults.count) / \(totalSongCount)")
                    }
                    if !batchMatchResults.isEmpty {
                        Divider()
                        ForEach(
                            Array(batchMatchResults.keys)
                                .search(for: batchListSearchText)
                                .sorted(by: { $0.id > $1.id })
                        ) { key in
                            SongReflectionResultsView(for: key, in: $batchMatchResults)
                        }
                        .insert {
                            Divider()
                        }
                    }
                }
            } header: {
                Text("Batch")
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
                if let count = await Song.all()?.count {
                    totalSongCount = count
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
                   let codedResults = try? PropertyListDecoder().decode([PreviewSong: CodableMatchResult].self, from: data) {
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

private struct SongReflectionResultsView: View {
    @Binding var results: [PreviewSong: CodableMatchResult]
    var song: PreviewSong
    
    init(for song: PreviewSong, in results: Binding<[PreviewSong : CodableMatchResult]>) {
        self._results = results
        self.song = song
    }
    
    @State private var isEditing = false
    @State private var saveFlag = false
    @State private var reReflectionStart = 30.0
    @State private var isReReflecting = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(song.musicTitle.forPreferredLocale() ?? "[No title]")
                    .textSelection(.enabled)
                Text(verbatim: "#\(song.id)")
                    .foregroundStyle(.gray)
                Spacer()
                if case .some = results[song]! {
                    if !isEditing {
                        Button("Edit") {
                            isEditing = true
                        }
                    } else {
                        Button("Add", systemImage: "plus") {
                            switch results[song]! {
                            case .some(let items):
                                results.updateValue(
                                    .some(items + [.init(
                                        confidence: 1,
                                        matchOffset: 0,
                                        predictedCurrentMatchOffset: 0,
                                        frequencySkew: 0,
                                        timeRanges: [],
                                        frequencySkewRanges: [],
                                        genres: [],
                                        explicitContent: false,
                                        id: .init()
                                    )]),
                                    forKey: song
                                )
                            case .none:
                                results.updateValue(
                                    .some([.init(
                                        confidence: 1,
                                        matchOffset: 0,
                                        predictedCurrentMatchOffset: 0,
                                        frequencySkew: 0,
                                        timeRanges: [],
                                        frequencySkewRanges: [],
                                        genres: [],
                                        explicitContent: false,
                                        id: .init()
                                    )]),
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
                }
            }
            HStack {
                Text(PreCache.current.bands.first { $0.id == song.bandID }?.bandName.forPreferredLocale() ?? "[No Band]")
                    .foregroundStyle(.gray)
                    .padding(.top, -10)
                Spacer()
                if case .some = results[song]!, isEditing {
                    Button {
                        Task {
                            isReReflecting = true
                            do {
                                let result = try await matchMediaItems(for: song.id, sliceFrom: reReflectionStart)
                                results.updateValue(.init(.success(result)), forKey: song)
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
            case .some(let items):
                if !isEditing {
                    ForEach(items) { item in
                        MediaItemPreview(item)
                    }
                } else {
                    VStack {
                        ForEach(items.enumerated(), id: \.element.id) { index, item in
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
            case .none(let error):
                Text(error)
                    .foregroundStyle(.red)
            }
        }
    }
    
    private struct ItemEditView: View {
        var index: Int
        var item: CodableMatchResult.CodableMatchItem
        var song: PreviewSong
        @Binding var allResults: [PreviewSong: CodableMatchResult]
        var saveFlag: Bool
        @State private var confidence = ""
        @State private var matchOffset = ""
        @State private var predictedCurrentMatchOffset = ""
        @State private var frequencySkew = ""
        @State private var title = ""
        @State private var subtitle = ""
        @State private var artist = ""
        @State private var artworkURL = ""
        @State private var videoURL = ""
        @State private var isrc = ""
        @State private var appleMusicURL = ""
        @State private var appleMusicID = ""
        @State private var webURL = ""
        @State private var shazamID = ""
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
                    TextField("Confidence", text: $confidence)
                    TextField("Match Offset", text: $matchOffset)
                    TextField("Predicted Current Match Offset", text: $predictedCurrentMatchOffset)
                    TextField("Frequency Skew", text: $frequencySkew)
                    TextField("Title", text: $title)
                    TextField("Subtitle", text: $subtitle)
                    TextField("Artist", text: $artist)
                    TextField("Artwork URL", text: $artworkURL)
                    TextField("Video URL", text: $videoURL)
                    TextField("ISRC", text: $isrc)
                    TextField("Apple Music URL", text: $appleMusicURL)
                    TextField("Apple Music ID", text: $appleMusicID)
                    TextField("Web URL", text: $webURL)
                    TextField("Shazam ID", text: $shazamID)
                }
                .padding(5)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(nsColor: .tertiarySystemFill))
                }
            }
            .onAppear {
                guard confidence.isEmpty else { return }
                confidence = String(item.confidence)
                matchOffset = String(item.matchOffset)
                predictedCurrentMatchOffset = String(item.predictedCurrentMatchOffset)
                frequencySkew = String(item.frequencySkew)
                title = item.title ?? ""
                subtitle = item.subtitle ?? ""
                artist = item.artist ?? ""
                artworkURL = item.artworkURL?.absoluteString ?? ""
                videoURL = item.videoURL?.absoluteString ?? ""
                isrc = item.isrc ?? ""
                appleMusicURL = item.appleMusicURL?.absoluteString ?? ""
                appleMusicID = item.appleMusicID ?? ""
                webURL = item.webURL?.absoluteString ?? ""
                shazamID = item.shazamID ?? ""
            }
            .onChange(of: saveFlag) {
                if let confidence = Float(confidence) {
                    allResults[song]!.castSome[index].confidence = confidence
                }
                if let matchOffset = TimeInterval(matchOffset) {
                    allResults[song]!.castSome[index].matchOffset = matchOffset
                }
                if let predictedCurrentMatchOffset = TimeInterval(predictedCurrentMatchOffset) {
                    allResults[song]!.castSome[index].predictedCurrentMatchOffset = predictedCurrentMatchOffset
                }
                if let frequencySkew = Float(frequencySkew) {
                    allResults[song]!.castSome[index].frequencySkew = frequencySkew
                }
                allResults[song]!.castSome[index].title = title
                allResults[song]!.castSome[index].subtitle = subtitle
                allResults[song]!.castSome[index].artist = artist
                allResults[song]!.castSome[index].artworkURL = .init(string: artworkURL)
                allResults[song]!.castSome[index].videoURL = .init(string: videoURL)
                allResults[song]!.castSome[index].isrc = isrc
                allResults[song]!.castSome[index].appleMusicURL = .init(string: appleMusicURL)
                allResults[song]!.castSome[index].appleMusicID = appleMusicID.isEmpty ? nil : appleMusicID
                allResults[song]!.castSome[index].webURL = .init(string: webURL)
                allResults[song]!.castSome[index].shazamID = shazamID.isEmpty ? nil : shazamID
            }
        }
    }
}

private struct MediaItemPreview: View {
    var item: CodableMatchResult.CodableMatchItem
    
    init(_ item: CodableMatchResult.CodableMatchItem) {
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
            .cornerRadius(12)
            .scaledToFit()
            .frame(width: 100, height: 100)
            VStack(alignment: .leading) {
                Text(item.title ?? "No title")
                    .font(.title3)
                Text(item.artist ?? "No artist")
                    .font(.body)
                    .foregroundStyle(.gray)
                Text("\(unsafe String(format: "%.2f", item.confidence * 100))%")
            }
            Spacer()
            if let url = item.appleMusicURL {
                Button(action: {
                    openURL(url)
                }, label: {
                    HStack {
                        Image(_internalSystemName: "music")
                        Text("Open in Apple Music")
                        Image(systemName: "arrow.up.forward.app")
                    }
                    .foregroundStyle(.white)
                    .padding(5)
                    .padding(.horizontal, 5)
                    .background {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 230 / 255, green: 63 / 255, blue: 69 / 255))
                    }
                })
                .buttonStyle(.borderless)
            }
        }
    }
}

private func matchMediaItems(
    for id: Int,
    sliceFrom sliceInterval: TimeInterval = 30
) async throws -> [SHMatchedMediaItem] {
    guard let song = await Song(id: id) else {
        throw CocoaError(.fileReadUnknown)
    }
    let url = song.soundURL
    return try await withCheckedThrowingContinuation { continuation in
        DispatchQueue(label: "com.memz233.Greatdori.GreatLyrics.Download-Song-For-Reflection-\(song.id)", qos: .userInitiated).async {
            guard let data = try? Data(contentsOf: url) else {
                continuation.resume(
                    throwing: CocoaError(
                        .fileReadUnknown,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to download song from \(url.absoluteString)"]
                    )
                )
                return
            }
            let destination = URL(filePath: NSTemporaryDirectory() + "/\(url.lastPathComponent)")
            guard (try? data.write(to: destination)) != nil else {
                continuation.resume(throwing: CocoaError(.fileReadCorruptFile))
                return
            }
            SHSignatureGenerator.generateSignature(from: AVURLAsset(url: destination)) { signature, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                Task {
                    guard let signature = try? await signature?.slices(from: sliceInterval, duration: 12).first(where: { _ in true }) else {
                        continuation.resume(throwing: CocoaError(.coderValueNotFound))
                        return
                    }
                    let session = SHSession()
                    let result = await session.result(from: signature)
                    switch result {
                    case .match(let match):
                        continuation.resume(returning: match.mediaItems)
                    case .noMatch(_):
                        continuation.resume(returning: [])
                    case .error(let error, _):
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}

private func matchAllMediaItems(
    except ignoredSongs: [PreviewSong] = [],
    eachCompletion: @Sendable @escaping (PreviewSong, Result<[SHMatchedMediaItem], any Error>) -> Void
) async {
    guard var songs = await Song.all() else { return }
    songs.removeAll { ignoredSongs.map { $0.id }.contains($0.id) }
    await withTaskGroup { group in
        var counter = 0
        for song in songs {
            group.addTask(priority: .userInitiated) {
                let _result: Result<[SHMatchedMediaItem], any Error>
                do {
                    let items = try await matchMediaItems(for: song.id)
                    _result = .success(items)
                } catch {
                    _result = .failure(error)
                }
                eachCompletion(song, _result)
                return (song, _result)
            }
            if counter >= 20 {
                await group.waitForAll()
                counter = 0
            }
            counter += 1
        }
    }
}

// [PreviewSong: Result<[SHMatchedMediaItem], any Error>]
private enum CodableMatchResult: Codable {
    case some([CodableMatchItem])
    case none(String)
    
    init(_ result: Result<[SHMatchedMediaItem], any Error>) {
        self = switch result {
        case .success(let items): .some(items.map { .init($0) })
        case .failure(let error): .none(error.localizedDescription)
        }
    }
    
    struct CodableMatchItem: Identifiable, Codable {
        var confidence: Float
        var matchOffset: TimeInterval
        var predictedCurrentMatchOffset: TimeInterval
        var frequencySkew: Float
        var timeRanges: [Range<TimeInterval>]
        var frequencySkewRanges: [Range<Float>]
        var title: String?
        var subtitle: String?
        var artist: String?
        var artworkURL: URL?
        var videoURL: URL?
        var genres: [String]
        var explicitContent: Bool
        var creationDate: Date?
        var isrc: String?
        var id: UUID
        var appleMusicURL: URL?
        var appleMusicID: String?
        var webURL: URL?
        var shazamID: String?
    }
    
    var castSome: [CodableMatchItem] {
        get {
            if case .some(let items) = self {
                items
            } else {
                preconditionFailure()
            }
        }
        set {
            self = .some(newValue)
        }
    }
}
extension CodableMatchResult.CodableMatchItem {
    init(_ item: SHMatchedMediaItem) {
        self.confidence = item.confidence
        self.matchOffset = item.matchOffset
        self.predictedCurrentMatchOffset = item.predictedCurrentMatchOffset
        self.frequencySkew = item.frequencySkew
        self.timeRanges = item.timeRanges
        self.frequencySkewRanges = item.frequencySkewRanges
        self.title = item.title
        self.subtitle = item.subtitle
        self.artist = item.artist
        self.artworkURL = item.artworkURL
        self.videoURL = item.videoURL
        self.genres = item.genres
        self.explicitContent = item.explicitContent
        self.creationDate = item.creationDate
        self.isrc = item.isrc
        self.id = item.id
        self.appleMusicURL = item.appleMusicURL
        self.appleMusicID = item.appleMusicID
        self.webURL = item.webURL
        self.shazamID = item.shazamID
    }
}

struct PropertyListFileDocument: FileDocument {
    static let readableContentTypes = [UTType.propertyList]
    
    var data: Data
    
    init(_ data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
        } else {
            throw CocoaError(.coderReadCorrupt)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        return FileWrapper(regularFileWithContents: data)
    }
}

// MARK: Command Line Support
func reflectNewSongs(into newFile: URL, from currentFile: URL) async throws {
    var results: [PreviewSong: CodableMatchResult]
    
    do {
        _ = currentFile.startAccessingSecurityScopedResource()
        defer { currentFile.stopAccessingSecurityScopedResource() }
        let data = try Data(contentsOf: currentFile)
        let codedResults = try PropertyListDecoder().decode([PreviewSong: CodableMatchResult].self, from: data)
        results = codedResults
    }
    
    var exceptions = results
    exceptions = exceptions.filter {
        if case .none = $0.value {
            false
        } else { true }
    }
    await matchAllMediaItems(except: Array(exceptions.keys)) { song, result in
        DispatchQueue.main.async {
            if let existingSong = results.keys.first(where: { $0.id == song.id }) {
                results.updateValue(.init(result), forKey: existingSong)
            } else {
                results.updateValue(.init(result), forKey: song)
            }
        }
    }
    
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    try encoder.encode(results).write(to: newFile)
}
