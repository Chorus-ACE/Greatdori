//===---*- Greatdori! -*---------------------------------------------------===//
//
// MusicKitView.swift
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
import SDWebImageSwiftUI
import SwiftUI

struct MusicKitView: View {
    @Environment(\.openURL) var openURL
    
    @State var appleMusicIDs: [Int] = []
    @State var musicIDInput = ""
    @State var musicIDInputIsValid = false
    @State var token: String = ""
    @State var searchResult: [_DoriFrontend.Songs._NeoSongMatchResult.MatchItem] = []
    @State var lastError: String = ""
    @State var region: String = "jp"
    @State var isLoading = false
    var body: some View {
        Form {
            Section {
                SecureField(text: $token, label: {
                    Text("Token")
                })
                .onChange(of: token) {
                    MusicKitTokenManager.shared.token = token
                }
                TextField(text: $musicIDInput, label: {
                    Text("Apple Music IDs")
                })
                .onChange(of: musicIDInput) {
                    if let result = getMusicIDsFromString(musicIDInput) {
                        musicIDInputIsValid = true
                        appleMusicIDs = result
                    } else {
                        musicIDInputIsValid = false
                    }
                }
                TextField(text: $region, label: {
                    Text("Region")
                })
                HStack {
                    if token.isEmpty {
                        Label("Token missing", systemImage: "key.slash")
                            .foregroundStyle(.yellow)
                    } else if !musicIDInputIsValid {
                        Label("Music ID is invalid", systemImage: "exclamationmark.circle")
                            .foregroundStyle(.red)
                    } else {
                        Label("Ready", systemImage: "checkmark.circle")
                            .foregroundStyle(.green)
                    }
                    Spacer()
                    Button(action: {
                        guard let result = getMusicIDsFromString(musicIDInput) else {
                            return musicIDInputIsValid = false
                        }
                        
                        appleMusicIDs = result
                        
                        Task {
                            isLoading = true
                            do {
                                searchResult = try await fetchAppleMusicMetadata(ids: appleMusicIDs, storefront: region, token: token).map({ $0.convertToNeoSongSearchResult() })
                            } catch {
                                lastError = "\(error)"
                            }
                            isLoading = false
                        }
                    }, label: {
                        Text("Fetch")
                    })
                    .disabled(!musicIDInputIsValid)
                }
            }
            
            Section {
                Button(action: {
                    Task {
                        await MusicAuthorization.request()
                    }
                }, label: {
                    Text("Request Authorization")
                })
            }
            
            if !lastError.isEmpty {
                Section("Error") {
                    Text(lastError)
                        .fontDesign(.monospaced)
                    Button(action: {
                        lastError = ""
                    }, label: {
                        Text("Clear")
                    })
                }
            }
            
            Section("Result") {
                if !searchResult.isEmpty {
                    ForEach(searchResult, id: \.self) { item in
                        HStack {
                            WebImage(url: item.artworkURL, content: { image in
                                image
                            }, placeholder: {
                                Rectangle()
                                    .foregroundStyle(.placeholder)
                            })
                            .resizable()
                            .cornerRadius(3)
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
                            }
                        }
                    }
                } else if isLoading {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Searching...")
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                } else {
                    Text("No Search Result")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .onAppear {
            token = MusicKitTokenManager.shared.token
        }
    }
    
    func getMusicIDsFromString(_ input: String) -> [Int]? {
        var mutableInput = input
        mutableInput.removeAll(where: { $0 == " " })
        let separatedInput = mutableInput.components(separatedBy: ",")
        var result: [Int] = []
        
        for item in separatedInput {
            if let integer = Int(item) {
                result.append(integer)
            } else {
                return nil
            }
        }
        
        return result.isEmpty ? nil : result
    }
}

extension AppleMusicSongMetadata {
    fileprivate func convertToNeoSongSearchResult() -> _DoriFrontend.Songs._NeoSongMatchResult.MatchItem {
        .init(
            titleJP: title,
            artistJP: artist,
            artworkURL: artworkURL,
        )
    }
}
