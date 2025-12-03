//===---*- Greatdori! -*---------------------------------------------------===//
//
// CostumeDetailView.swift
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

// MARK: CostumeDetailView
struct CostumeDetailView: View {
    var id: Int
    var allCostumes: [PreviewCostume]? = nil
    var body: some View {
        DetailViewBase(previewList: allCostumes, initialID: id) { information in
            CostumeDetailOverviewView(information: information)
            if !information.cards.isEmpty {
                DetailsCardsSection(cards: information.cards)
            }
            DetailArtsSection {
                ArtsTab("Costume.arts.thumb", ratio: 1) {
                    ArtsItem(title: "Costume.arts.thumb", url: information.costume.thumbImageURL)
                }
            }
        } switcherDestination: {
            CostumeSearchView()
        }
    }
}

// MARK: CostumeDetailOverviewView
struct CostumeDetailOverviewView: View {
    let information: ExtendedCostume
    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
    var body: some View {
        VStack {
            Group {
                NavigationLink(destination: { Live2DDetailView(costume: .init(information.costume)) }) {
                    Live2DView(resourceURL: information.costume.live2dResourceFileURL)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .frame(width: 350, height: 350)
                .padding(.bottom, -10)
//                .accessibilityLabel("""
//                Live2D of character \(information.character.characterName.forPreferredLocale() ?? ""). \
//                Wearing costume named "\(information.costume.description.forPreferredLocale() ?? "")". 
//                """)
                
                // MARK: Info
                CustomGroupBox(cornerRadius: 20) {
                    LazyVStack {
                        // MARK: Description
                        Group {
                            ListItem(title: {
                                Text("Costume.title")
                                    .bold()
                            }, value: {
                                MultilingualText(information.costume.description)
                            })
                            Divider()
                        }
                        
                        // MARK: Character
                        Group {
                            ListItem(title: {
                                Text("Costume.character")
                                    .bold()
                            }, value: {
                                NavigationLink(destination: {
                                    CharacterDetailView(id: information.character.id)
                                }, label: {
                                    Text(information.character.characterName.forPreferredLocale() ?? "Unknown")
                                    WebImage(url: information.character.iconImageURL)
                                        .resizable()
                                        .interpolation(.high)
                                        .antialiased(true)
                                        .frame(width: 30, height: 30)
                                })
                                .buttonStyle(.plain)
                            })
                            Divider()
                        }
                        
                        // MARK: Band
                        Group {
                            ListItem(title: {
                                Text("Costume.band")
                                    .bold()
                            }, value: {
                                Text(information.band.bandName.forPreferredLocale() ?? "Unknown")
                                WebImage(url: information.band.iconImageURL)
                                    .resizable()
                                    .interpolation(.high)
                                    .antialiased(true)
                                    .frame(width: 30, height: 30)
                            })
                            Divider()
                        }
                        
                        // MARK: Release Date
                        Group {
                            ListItem(title: {
                                Text("Costume.release-date")
                                    .bold()
                            }, value: {
                                MultilingualText(information.costume.publishedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                            })
                            Divider()
                        }
                        
                        if !information.costume.howToGet.isValueEmpty {
                            // MARK: How to Get
                            Group {
                                ListItem(displayMode: .basedOnUISizeClass, title: {
                                    Text("Costume.how-to-get")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.costume.howToGet)
                                })
                                Divider()
                            }
                        }
                        
                        // MARK: ID
                        Group {
                            ListItem(title: {
                                Text("ID")
                                    .bold()
                            }, value: {
                                Text("\(String(information.costume.id))")
                            })
                        }
                        
                    }
                }
            }
        }
        .frame(maxWidth: infoContentMaxWidth)
    }
}
