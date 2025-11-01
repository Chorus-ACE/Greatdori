//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongDetailGameplayView.swift
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
import SDWebImageSwiftUI


struct SongDetailGameplayView: View {
    var information: ExtendedSong
    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                CustomGroupBox {
                    VStack {
                        if let band = information.band {
                            //MARK: Band
                            Group {
                                ListItemView(title: {
                                    Text("Song.gameplay.band")
                                        .bold()
                                }, value: {
                                    MultilingualText(band.bandName)
                                    //                            Text(DoriCache.preCache.mainBands.first{$0.id == bandID}?.bandName.forPreferredLocale(allowsFallback: true) ?? "Unknown")
                                    if DoriCache.preCache.mainBands.contains(where: { $0.id == band.id }) || !DoriCache.PreCache.isAvailable {
                                        WebImage(url: band.iconImageURL)
                                            .resizable()
                                            .interpolation(.high)
                                            .antialiased(true)
                                            .frame(width: 30, height: 30)
                                    }
                                    
                                })
                                Divider()
                            }
                        }
                        
                        // MARK: Length
                        Group {
                            ListItemView(title: {
                                Text("Song.gameplay.difficulty")
                                    .bold()
                            }, value: {
                                SongDifficultiesIndicator(information.song.difficulty)
                            })
                            Divider()
                        }
                        
                        // MARK: Length
                        Group {
                            ListItemView(title: {
                                Text("Song.gameplay.length")
                                    .bold()
                            }, value: {
                                Text(formattedSongLength(information.song.length))
                            })
                            Divider()
                        }
                        
                        // MARK: Countdown
                        Group {
                            ListItemView(title: {
                                Text("Song.gameplay.countdown")
                                    .bold()
                            }, value: {
                                MultilingualTextForCountdownAlt(date: information.song.publishedAt)
                            })
                            Divider()
                        }
                        
                        // MARK: Release Date
                        Group {
                            ListItemView(title: {
                                Text("Song.gameplay.release-date")
                                    .bold()
                            }, value: {
                                MultilingualText(information.song.publishedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                            })
                            Divider()
                        }
                        
                        if !information.song.closedAt.map({$0?.corrected()}).isEmpty {
                            // MARK: Close Date
                            Group {
                                ListItemView(title: {
                                    Text("Song.gameplay.close-date")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.song.closedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                                })
                                Divider()
                            }
                        }
                        
                        // MARK: Release Date
                        Group {
                            ListItemView(title: {
                                Text("Song.gameplay.how-to-get")
                                    .bold()
                            }, value: {
                                MultilingualText(information.song.howToGet)
                            })
                        }
                    }
                }
                .frame(maxWidth: infoContentMaxWidth)
            }, header: {
                HStack {
                    Text("Song.gameplay")
                        .font(.title2)
                        .bold()
                    Spacer()
                }
                .frame(maxWidth: 615)
            })
        }
    }
}

