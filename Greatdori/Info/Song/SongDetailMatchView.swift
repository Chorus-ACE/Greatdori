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
    var songMatches: [Int: DoriFrontend.Songs._SongMatchResult]?
    @Environment(\.openURL) private var openURL
    var body: some View {
        if let songMatches,
           let matchResult = songMatches.first(where: { $0.key == song.id })?.value,
           case let .some(results) = matchResult {
            LazyVStack(pinnedViews: .sectionHeaders) {
                Section {
                    ForEach(results, id: \.self) { result in
                        CustomGroupBox {
                            VStack(alignment: .leading) {
                                HStack {
                                    WebImage(url: result.artworkURL) { image in
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
                                        Text(result.title ?? "No title")
                                            .font(.title3)
                                        Text(result.artist ?? "No artist")
                                            .font(.body)
                                            .foregroundStyle(.gray)
                                        Text("\(unsafe String(format: "%.2f", result.confidence * 100))%")
                                    }
                                    Spacer()
                                }
                                if let url = result.appleMusicURL {
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
                } header: {
                    HStack {
                        Text("音乐匹配")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    .frame(maxWidth: 615)
                }
            }
            .frame(maxWidth: 600)
        }
    }
}
