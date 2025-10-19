//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongDetailView.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.memz.top/LICENSE.txt for license information
// See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import SwiftUI
import DoriKit
import SDWebImageSwiftUI


// MARK: SongDetailView
struct SongDetailView: View {
    var id: Int
    var allSongs: [PreviewSong]? = nil
    var body: some View {
        DetailViewBase("Song", previewList: allSongs, initialID: id) { information in
            SongDetailOverviewView(information: information.song)
            SongDetailGameplayView(information: information)
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
                            ListItemView(title: {
                                Text("Song.title")
                                    .bold()
                            }, value: {
                                MultilingualText(information.musicTitle)
                            })
                            Divider()
                        }
                        
                        // MARK: Type
                        Group {
                            ListItemView(title: {
                                Text("Song.type")
                                    .bold()
                            }, value: {
                                Text(information.tag.localizedString)
                            })
                            Divider()
                        }
                        
                        // MARK: Lyrics
                        Group {
                            ListItemView(title: {
                                Text("Song.lyrics")
                                    .bold()
                            }, value: {
                                MultilingualText(information.lyricist)
                            })
                            Divider()
                        }
                        
                        // MARK: Composer
                        Group {
                            ListItemView(title: {
                                Text("Song.composer")
                                    .bold()
                            }, value: {
                                MultilingualText(information.composer)
                            })
                            Divider()
                        }
                        
                        // MARK: Arrangement
                        Group {
                            ListItemView(title: {
                                Text("Song.arrangement")
                                    .bold()
                            }, value: {
                                MultilingualText(information.arranger)
                            })
                            Divider()
                        }
                        
                        // MARK: ID
                        Group {
                            ListItemView(title: {
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
                        //        .frame(maxWidth: 600)
                    }
                }
            }
        }
        .frame(maxWidth: 600)
    }
}
