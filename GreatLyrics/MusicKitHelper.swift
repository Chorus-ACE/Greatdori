//===---*- Greatdori! -*---------------------------------------------------===//
//
// MusicKitHelper.swift
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
import Foundation
import MusicKit
import ShazamKit
import SwiftyJSON
import SwiftUI

struct AppleMusicSongMetadata: Identifiable, Hashable {
    let id: Int
    let title: String
    let artist: String
    let artworkURL: URL?
//    let album: String?
//    let duration: TimeInterval?
//    let genres: [String]
//    let isExplicit: Bool
//    let releaseDate: String?
}

func fetchAppleMusicMetadata(ids: [Int], storefront: String = "us", token: String) async throws -> [AppleMusicSongMetadata] {
    guard !ids.isEmpty else { return [] }

    let idsString = ids.map(String.init).joined(separator: ",")
    let urlString =
        "https://api.music.apple.com/v1/catalog/\(storefront)/songs?ids=\(idsString)"

    guard let url = URL(string: urlString) else {
        throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    request.setValue(
        "Bearer \(token)",
        forHTTPHeaderField: "Authorization"
    )

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    
    let json = JSON(data)
    
    return json["data"].arrayValue.compactMap { song in
        let attributes = song["attributes"]
        let id = song["id"].intValue
        
        let title = attributes["name"].stringValue
        let artist = attributes["artistName"].stringValue
        let artworkURL = attributes["artwork"]["url"].string.flatMap { url in
            URL(string: url
                .replacingOccurrences(of: "{w}", with: "512")
                .replacingOccurrences(of: "{h}", with: "512")
            )
        }
        
//        let album = attributes["albumName"].string
//        let duration = attributes["durationInMillis"].int.map { TimeInterval($0) / 1000 }
//        let genres = attributes["genreNames"].arrayValue.map { $0.stringValue }
//        let isExplicit = attributes["isExplicit"].boolValue
//        let releaseDate = attributes["releaseDate"].string
        
        return AppleMusicSongMetadata(id: id, title: title, artist: artist, artworkURL: artworkURL,)
    }
}

struct BlockMark: View {
    var character: Swift.Character
    var color: Color
    var description: LocalizedStringResource
    var body: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(color)
            .frame(width: 20, height: 20)
            .overlay {
                Text(character.uppercased())
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
            .help(description)
    }
}

func matchMediaItems(for id: Int, sliceFrom sliceInterval: TimeInterval = 30) async throws -> [_DoriFrontend.Songs._NeoSongMatchResult.MatchItem] {
    guard let song = await Song(id: id) else {
        throw CocoaError(.fileReadUnknown)
    }
    
    do {
        let shazamResult = try await matchMediaItemsShazam(for: id, sliceFrom: sliceInterval)
        let results = await withTaskGroup(
            of: _DoriFrontend.Songs._NeoSongMatchResult.MatchItem.self,
            returning: [_DoriFrontend.Songs._NeoSongMatchResult.MatchItem].self
        ) { group in
            for item in shazamResult {
                group.addTask(priority: .userInitiated) {
                    await _DoriFrontend.Songs._NeoSongMatchResult.MatchItem(from: item)
                }
            }

            var output: [_DoriFrontend.Songs._NeoSongMatchResult.MatchItem] = []
            for await result in group {
                output.append(result)
            }
            return output
        }
        
        return results
    } catch {
        throw error
    }
    
    func matchMediaItemsShazam(for id: Int, sliceFrom sliceInterval: TimeInterval = 30) async throws -> [SHMatchedMediaItem] {
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
}

func matchAllMediaItems(except ignoredSongs: [Int] = [], eachCompletion: @Sendable @escaping (Int, Result<[_DoriFrontend.Songs._NeoSongMatchResult.MatchItem], any Error>) -> Void) async {
    guard var songs = await Song.all() else { return }
    songs.removeAll { ignoredSongs.contains($0.id) }
    await withTaskGroup { group in
        var counter = 0
        for song in songs {
            group.addTask(priority: .userInitiated) {
                let _result: Result<[_DoriFrontend.Songs._NeoSongMatchResult.MatchItem], any Error>
                do {
                    let items = try await matchMediaItems(for: song.id)
                    _result = .success(items)
                } catch {
                    _result = .failure(error)
                }
                eachCompletion(song.id, _result)
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

extension _DoriFrontend.Songs._NeoSongMatchResult {
    var castSome: [_DoriFrontend.Songs._NeoSongMatchResult.MatchItem] {
        get {
            if case .success(let items) = self {
                items
            } else {
                preconditionFailure()
            }
        }
        set {
            self = .success(newValue)
        }
    }
    
    init(_ result: Result<[_DoriFrontend.Songs._NeoSongMatchResult.MatchItem], any Error>) {
        switch result {
        case .success(let items):
            self = .success(items)
        case .failure(let error):
            self = .failure(error.localizedDescription)
        }
    }
}

extension _DoriFrontend.Songs._NeoSongMatchResult.MatchItem {
    init(from item: SHMatchedMediaItem) async {
        let appleMusicID: Int? = item.appleMusicID == nil ? nil : Int(item.appleMusicID!)!
        let shazamID: Int? = item.shazamID == nil ? nil : Int(item.shazamID!)!
        do {
            guard let id = appleMusicID else {
                throw BasicError(content: "No Apple Music ID")
            }
            
            guard let token = await MusicKitTokenManager.shared.token else {
                throw BasicError(content: "No token given.")
            }
            
            let jp = try await fetchAppleMusicMetadata(ids: [id], storefront: "jp", token: token).first!
            let en = try await fetchAppleMusicMetadata(ids: [id], storefront: "us", token: token).first!
            self = .init(titleJP: jp.title, titleEN: en.title, artistJP: jp.artist, artistEN: en.artist, artworkURL: item.artworkURL, appleMusicID: appleMusicID, shazamID: shazamID)
        } catch {
            print("Did not access MusicKit. \(error)")
            self = .init(titleJP: item.title ?? "", artistJP: item.artist ?? "", artworkURL: item.artworkURL, appleMusicID: appleMusicID, shazamID: shazamID)
        }
    }
}

func getFullMetadata(from item: SHMatchedMediaItem) async -> _DoriFrontend.Songs._NeoSongMatchResult.MatchItem {
    let appleMusicID: Int? = item.appleMusicID == nil ? nil : Int(item.appleMusicID!)!
    let shazamID: Int? = item.shazamID == nil ? nil : Int(item.shazamID!)!
    if let id = appleMusicID, let token = await MusicKitTokenManager.shared.token {
        do {
            let jp = try await fetchAppleMusicMetadata(ids: [id], storefront: "jp", token: token).first!
            let en = try await fetchAppleMusicMetadata(ids: [id], storefront: "us", token: token).first!
            return .init(titleJP: jp.title, titleEN: en.title, artistJP: jp.artist, artistEN: en.artist, artworkURL: item.artworkURL, appleMusicID: appleMusicID, shazamID: shazamID)
        } catch {
            print("[ERROR] Failed to access MusicKit. \(error)")
            return .init(titleJP: item.title ?? "", artistJP: item.artist ?? "", artworkURL: item.artworkURL, appleMusicID: appleMusicID, shazamID: shazamID)
        }
    } else {
        return .init(titleJP: item.title ?? "", artistJP: item.artist ?? "", artworkURL: item.artworkURL, appleMusicID: appleMusicID, shazamID: shazamID)
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
    var results: [Int: _DoriFrontend.Songs._NeoSongMatchResult]

    do {
        _ = currentFile.startAccessingSecurityScopedResource()
        defer { currentFile.stopAccessingSecurityScopedResource() }
        let data = try Data(contentsOf: currentFile)
        let codedResults = try PropertyListDecoder().decode([Int: _DoriFrontend.Songs._NeoSongMatchResult].self, from: data)
        results = codedResults
    }

    var exceptions = results
    exceptions = exceptions.filter {
        if case .failure = $0.value {
            false
        } else { true }
    }
    
    await matchAllMediaItems(except: Array(exceptions.keys)) { song, result in
        DispatchQueue.main.async {
            if let existingSong = results.keys.first(where: { $0 == song }) {
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

@MainActor
class MusicKitTokenManager: Sendable {
    static let shared: MusicKitTokenManager = MusicKitTokenManager()
    
    var token: String?
}

struct BasicError: Error {
    var content: String
}
