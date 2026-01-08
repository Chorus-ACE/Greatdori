//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongDetailOverviewView.swift
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
import SDWebImageSwiftUI
import SwiftUI

// MARK: SongDetailOverviewView
struct SongDetailOverviewView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let information: Song
    
    let coverSideLengthRegular: CGFloat = 260
    let coverSideLengthCompact: CGFloat = 220
    var body: some View {
        VStack {
            Group {
                // MARK: Title Image
                Group {
                    WebImage(url: information.jacketImageURL) { image in
                        image
                            .antialiased(true)
                            .resizable()
                            .cornerRadius(10)
                            .scaledToFit()
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(getPlaceholderColor())
                    }
                    .interpolation(.high)
                    .frame(width: sizeClass == .regular ? coverSideLengthRegular : coverSideLengthCompact, height: sizeClass == .regular ? coverSideLengthRegular : coverSideLengthCompact)
                    .shadow(radius: 5, y: 4)
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
                    }
                }
            }
        }
        .frame(maxWidth: infoContentMaxWidth)
    }
}

