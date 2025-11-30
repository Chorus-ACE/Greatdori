//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventDetailRotationMusicView.swift
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

struct EventDetailRotationMusicView: View {
    var information: ExtendedEvent
    @State private var musics: [_DoriAPI.Events.RotationMusic]?
    @State private var songList: [PreviewSong]?
    var body: some View {
        if information.event.eventType == .festival {
            LazyVStack(pinnedViews: .sectionHeaders) {
                Section {
                    CustomGroupBox {
                        LazyVStack {
                            if let musics, let songList {
                                ForEach(musics.map { IdentifiableRotationMusic(music: $0) }.grouped(), id: \.self) { musics in
                                    HStack {
                                        WrappingHStack(alignment: .leading, contentWidth: 50) {
                                            ForEach(musics) { music in
                                                if let song = songList.first(where: { $0.id == music.music.musicID }) {
                                                    NavigationLink(destination: { SongDetailView(id: song.id) }) {
                                                        WebImage(url: song.jacketImageURL)
                                                            .resizable()
                                                    }
                                                    .buttonStyle(.plain)
                                                    .frame(width: 50, height: 50)
                                                }
                                            }
                                        }
                                        Spacer(minLength: 0)
                                        MultilingualTextForCountdown(
                                            startDate: .init(_jp: musics.first!.music.startAt, en: nil, tw: nil, cn: nil, kr: nil),
                                            endDate: .init(_jp: musics.first!.music.endAt, en: nil, tw: nil, cn: nil, kr: nil)
                                        )
                                    }
                                }
                                .insert {
                                    Divider()
                                }
                            } else {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .controlSize(.large)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: infoContentMaxWidth)
                } header: {
                    HStack {
                        Text("Event.rotation-music")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    .frame(maxWidth: 615)
                }
            }
            .task {
                withDoriCache(id: "EventFestivalRotationMusic_\(information.event.id)") {
                    await _DoriAPI.Events.festivalRotationMusics(of: information.event.id)
                }.onUpdate {
                    musics = $0
                }
                withDoriCache(id: "SongList", trait: .realTime) {
                    await PreviewSong.all()
                }.onUpdate {
                    songList = $0
                }
            }
        }
    }
}

private struct IdentifiableRotationMusic: Identifiable, Hashable {
    var id: UUID = .init()
    var music: _DoriAPI.Events.RotationMusic
}

extension Array<IdentifiableRotationMusic> {
    fileprivate func grouped() -> [[IdentifiableRotationMusic]] {
        reduce(into: [[IdentifiableRotationMusic]]()) { partialResult, element in
            if let last = partialResult.last,
               last.last!.music.startAt == element.music.startAt {
                partialResult[partialResult.count - 1].append(element)
            } else {
                partialResult.append([element])
            }
        }
    }
}
