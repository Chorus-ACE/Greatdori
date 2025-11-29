//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongDetailMusicMovieView.swift
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

import AVKit
import DoriKit
import SwiftUI

struct SongDetailMusicMovieView: View {
    let musicVideos: [String: _DoriAPI.Songs.Song.MusicVideoMetadata]?
    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
    @State var selectedMV: String? = nil
    @State var locale: DoriLocale = .primaryLocale
    @State var highQuality = true
    var body: some View {
        if let musicVideos, !musicVideos.isEmpty {
            LazyVStack(pinnedViews: .sectionHeaders) {
                Section(content: {
                    VStack {
                        if let mv = musicVideos[selectedMV ?? ""] {
                            CustomGroupBox {
                                VStack {
                                    Group {
                                        ListItem(title: {
                                            Text("Song.music-video.title")
                                        }, value: {
                                            MultilingualText(mv.title)
                                        })
                                        Divider()
                                    }
                                    
                                    Group {
                                        ListItem(title: {
                                            Text("Song.music-video.countdown")
                                        }, value: {
                                            MultilingualTextForCountdownAlt(date: mv.startAt)
                                        })
                                        Divider()
                                    }
                                    
                                    Group {
                                        ListItem(title: {
                                            Text("Song.music-video.release-date")
                                                .bold()
                                        }, value: {
                                            MultilingualText(mv.startAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                                        })
                                        Divider()
                                    }
                                    
                                    if !mv.endAt.map({$0?.corrected()}).isEmpty {
                                        Group {
                                            ListItem(title: {
                                                Text("Song.music-video.close-date")
                                                    .bold()
                                            }, value: {
                                                MultilingualText(mv.endAt.map{ $0?.corrected() == nil ? String(localized: "Date.unavailable") :  dateFormatter.string(for: $0)}, showLocaleKey: true)
                                            })
                                        }
                                    }
                                }
                            }
                            
                            CustomGroupBox {
                                VStack {
                                    ListItem(title: {
                                        Text("Song.music-video.locale")
                                    }, value: {
                                        LocalePicker($locale)
                                    })
                                    Divider()
                                    ListItem(title: {
                                        Text("Song.music-video.high-quality")
                                    }, value: {
                                        Toggle(isOn: $highQuality, label: {EmptyView()})
                                            .labelsHidden()
                                            .toggleStyle(.switch)
                                    })
                                    Divider()
                                    ListItem(title: {
                                        Text(verbatim: "musicStartDelay")
                                    }, value: {
                                        Text("\(mv.musicStartDelay)")
                                    })
                                }
                            }
                        }
                    }
                    .frame(maxWidth: infoContentMaxWidth)
                }, header: {
                    HStack {
                        Text("Song.music-video")
                            .font(.title2)
                            .bold()
                        if musicVideos.keys.count > 1 {
                            DetailSectionOptionPicker(selection: $selectedMV, options: Array(musicVideos.keys), labels: musicVideos.mapValues({ $0.title.forPreferredLocale() ?? "" }))
                        }
                        Spacer()
                    }
                    .frame(maxWidth: 615)
                })
            }
            .onAppear {
                if selectedMV == nil {
                    selectedMV = musicVideos.first?.key
                }
            }
        }
    }
}
