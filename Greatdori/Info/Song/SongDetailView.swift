//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongDetailView.swift
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

// MARK: SongDetailView
struct SongDetailView: View {
    var id: Int
    var allSongs: [PreviewSong]? = nil
    @State var songMatches: [Int: _DoriFrontend.Songs._SongMatchResult]?
    var body: some View {
        DetailViewBase(previewList: allSongs, initialID: id) { information in
            SongDetailOverviewView(information: information.song)
            SongDetailMatchView(song: information.song, songMatches: $songMatches)
            SongDetailGameplayView(information: information)
            DetailsEventsSection(events: information.events)
            DetailArtsSection {
                ArtsTab("Song.arts.cover") {
                    for locale in DoriLocale.allCases {
                        if let url = information.song.jacketImageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url, expectedRatio: 1)
                        }
                    }
                }
            }
        } switcherDestination: {
            SongSearchView()
        }
        .onAppear {
            Task {
                DoriCache.withCache(id: "_DoriFrontend.Songs._allMatches", trait: .invocationElidable) {
                    await _DoriFrontend.Songs._allMatches()
                }.onUpdate {
                    self.songMatches = $0
                }
            }
        }
    }
}

// MARK: SongDetailOverviewView
struct SongDetailOverviewView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let information: Song
    
    let coverSideLengthRegular: CGFloat = 270
    let coverSideLengthCompact: CGFloat = 180
    var body: some View {
        VStack {
            Group {
                //                // MARK: Title Image
                Group {
                    Rectangle()
                        .opacity(0)
                        .frame(height: 2)
                    WebImage(url: information.jacketImageURL) { image in
                        image
                            .antialiased(true)
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(getPlaceholderColor())
                    }
                    .interpolation(.high)
                    .frame(width: sizeClass == .regular ? coverSideLengthRegular : coverSideLengthCompact, height: sizeClass == .regular ? coverSideLengthRegular : coverSideLengthCompact)
                    Rectangle()
                        .opacity(0)
                        .frame(height: 2)
                }
                // MARK: Info
                CustomGroupBox(cornerRadius: 20) {
                    LazyVStack {
                        // MARK: Title
                        Group {
                            ListItem(title: {
                                Text("Song.title")
                                    .bold()
                            }, value: {
                                MultilingualText(information.musicTitle)
                            })
                            Divider()
                        }
                        
                        // MARK: Type
                        Group {
                            ListItem(title: {
                                Text("Song.type")
                                    .bold()
                            }, value: {
                                Text(information.tag.localizedString)
                            })
                            Divider()
                        }
                        
                        // MARK: Lyrics
                        Group {
                            ListItem(title: {
                                Text("Song.lyrics")
                                    .bold()
                            }, value: {
                                MultilingualText(information.lyricist)
                            })
                            Divider()
                        }
                        
                        // MARK: Composer
                        Group {
                            ListItem(title: {
                                Text("Song.composer")
                                    .bold()
                            }, value: {
                                MultilingualText(information.composer)
                            })
                            Divider()
                        }
                        
                        // MARK: Arrangement
                        Group {
                            ListItem(title: {
                                Text("Song.arrangement")
                                    .bold()
                            }, value: {
                                MultilingualText(information.arranger)
                            })
                            Divider()
                        }
                        
                        // MARK: ID
                        Group {
                            ListItem(title: {
                                Text("ID")
                                    .bold()
                            }, value: {
                                Text("\(String(information.id))")
                            })
                        }
                        //
                        //                    }
                        //                }
                        //            }
                        //        }
                        //        .frame(maxWidth: infoContentMaxWidth)
                    }
                }
            }
        }
        .frame(maxWidth: infoContentMaxWidth)
    }
}
