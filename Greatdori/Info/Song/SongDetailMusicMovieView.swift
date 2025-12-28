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
import SDWebImageSwiftUI
import SwiftUI

struct SongDetailMusicMovieView: View {
    let musicVideos: [String: DoriAPI.Songs.Song.MusicVideoMetadata]?
    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
    @State var selectedMV: String? = nil
    @State var locale: DoriLocale = .primaryLocale
    @State var highQuality = true
    var body: some View {
        if let musicVideos, !musicVideos.isEmpty {
            Section {
                VStack {
                    if let mv = musicVideos[selectedMV ?? ""] {
                        WebImage(url: mv.thumbImageURL(in: DoriLocale.primaryLocale)) { image in
                            image
                                .antialiased(true)
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(getPlaceholderColor())
                        }
                        .interpolation(.high)
                        .frame(width: 256, height: 144)
                        
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
                            }
                        }
                        
                        if let videoURL = mv.videoURL(highQuality: highQuality, in: locale, allowsFallback: false) {
                            VideoPlayer(player: AVPlayer(url: videoURL))
                                .aspectRatio(30/17, contentMode: .fit)
                        } else {
                            DetailUnavailableView(title: "Song.music-video.unavailable", symbol: PreviewSong.symbol)
                        }
                    }
                }
                .frame(maxWidth: infoContentMaxWidth)
            } header: {
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
                .detailSectionHeader()
                .onAppear {
                    if selectedMV == nil {
                        selectedMV = musicVideos.first?.key
                    }
                }
            }
        }
    }
}
