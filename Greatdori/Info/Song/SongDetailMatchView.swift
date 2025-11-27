//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongDetailMatchView.swift
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
import SDWebImageSwiftUI

struct SongDetailMatchView: View {
    var song: Song
    @Binding var songMatches: [Int: _DoriFrontend.Songs._SongMatchResult]?
    @Environment(\.openURL) private var openURL
    var body: some View {
        Group {
            if let songMatches,
               let matchResult = songMatches.first(where: { $0.key == song.id })?.value,
               case let .some(results) = matchResult, !results.isEmpty {
                LazyVStack(pinnedViews: .sectionHeaders) {
                    Section {
                        ForEach(results, id: \.self) { result in
                            Button(action: {
                                if let url = result.appleMusicURL {
                                    openURL(url)
                                } else if let url = result.webURL {
                                    openURL(url)
                                }
                            }, label: {
                                CustomGroupBox {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            WebImage(url: result.artworkURL) { image in
                                                image
                                            } placeholder: {
                                                Rectangle()
                                                    .fill(Color.secondary)
                                            }
                                            .resizable()
                                            .cornerRadius(5)
                                            .scaledToFit()
                                            .frame(width: 100, height: 100)
                                            .padding(.trailing, 3)
                                            
                                            VStack(alignment: .leading) {
                                                Text(result.title ?? "")
                                                Group {
                                                    Text(result.artist ?? "") + Text(" · ") + Text(result.appleMusicURL != nil ? "Song.shazam.apple-music" : "Song.shazam.shazam")
                                                }
                                                .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            if result.appleMusicURL != nil || result.webURL != nil {
                                                Image(systemName: "arrow.up.forward.app")
                                                    .foregroundStyle(.secondary)
                                                    .font(.title3)
                                            }
                                        }
                                    }
                                }
                            })
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: infoContentMaxWidth)
                    } header: {
                        HStack {
                            Text("Song.shazam")
                                .font(.title2)
                                .bold()
                            Spacer()
                        }
                        .frame(maxWidth: 615)
                    }
                }
            }
        }
    }
}
