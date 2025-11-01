//===---*- Greatdori! -*---------------------------------------------------===//
//
// ComicDetailView.swift
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


// MARK: ComicDetailView
struct ComicDetailView: View {
    var id: Int
    var allComics: [Comic]? = nil
    var body: some View {
        DetailViewBase(forType: Comic.self, previewList: allComics, initialID: id) { information in
            // FIXME: Implement `ComicDetailOverviewView` first
            //                            ComicDetailOverviewView(information: information, cardNavigationDestinationID: $cardNavigationDestinationID)
            
            //                            if !information.cards.isEmpty {
            //                                Rectangle()
            //                                    .opacity(0)
            //                                    .frame(height: 30)
            //                                DetailsCardsSection(cards: information.cards)
            //                            }
        } switcherDestination: {
            ComicSearchView()
        }
    }
}

// FIXME
// MARK: ComicDetailOverviewView
//struct ComicDetailOverviewView: View {
//    let information: Comic
//    @State var cardsArray: [DoriFrontend.Card.PreviewCard] = []
//    @State var cardsArraySeperated: [[DoriFrontend.Card.PreviewCard?]] = []
//    @State var cardsPercentage: Int = -100
//    @State var rewardsArray: [DoriFrontend.Card.PreviewCard] = []
//    @State var cardsTitleWidth: CGFloat = 0 // Fixed
//    @State var cardsPercentageWidth: CGFloat = 0 // Fixed
//    @State var cardsContentRegularWidth: CGFloat = 0 // Fixed
//    @State var cardsFixedWidth: CGFloat = 0 //Fixed
//    @State var cardsUseCompactLayout = true
//    @Binding var cardNavigationDestinationID: Int?
//    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
//    var body: some View {
//        VStack {
//            Group {
//                // MARK: Title Image
//                Group {
//                    Rectangle()
//                        .opacity(0)
//                        .frame(height: 2)
//                    // FIXME: Replace image with Live2D viewer
//                    WebImage(url: information.thumbImageURL) { image in
//                        image
//                            .antialiased(true)
//                            .resizable()
//                            .scaledToFit()
//                    } placeholder: {
//                        RoundedRectangle(cornerRadius: 10)
//                            .fill(getPlaceholderColor())
//                    }
//                    .interpolation(.high)
//                    .frame(width: 96, height: 96)
//                    Rectangle()
//                        .opacity(0)
//                        .frame(height: 2)
//                }
//
//
//                // MARK: Info
//                CustomGroupBox(cornerRadius: 20) {
//                    LazyVStack {
//                        // MARK: Description
//                        Group {
//                            ListItemView(title: {
//                                Text("Comic.title")
//                                    .bold()
//                            }, value: {
//                                MultilingualText(information.description)
//                            })
//                            Divider()
//                        }
//
//                        // MARK: Character
//                        Group {
//                            ListItemView(title: {
//                                Text("Comic.character")
//                                    .bold()
//                            }, value: {
//                                // FIXME: This requires `ExtendedComic` to be
//                                // FIXME: implemented in DoriKit.
//                            })
//                            Divider()
//                        }
//
//                        // MARK: Band
//                        Group {
//                            ListItemView(title: {
//                                Text("Comic.band")
//                                    .bold()
//                            }, value: {
//                                // FIXME: This requires `ExtendedComic` to be
//                                // FIXME: implemented in DoriKit.
//                            })
//                            Divider()
//                        }
//
//                        // MARK: Release Date
//                        Group {
//                            ListItemView(title: {
//                                Text("Comic.release-date")
//                                    .bold()
//                            }, value: {
//                                MultilingualText(information.publishedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
//                            })
//                            Divider()
//                        }
//
//                        if !information.howToGet.isValueEmpty {
//                            // MARK: How to Get
//                            Group {
//                                ListItemView(title: {
//                                    Text("Comic.how-to-get")
//                                        .bold()
//                                }, value: {
//                                    MultilingualText(information.howToGet)
//                                }, displayMode: .basedOnUISizeClass)
//                                Divider()
//                            }
//                        }
//
//                        // MARK: ID
//                        Group {
//                            ListItemView(title: {
//                                Text("ID")
//                                    .bold()
//                            }, value: {
//                                Text("\(String(information.id))")
//                            })
//                        }
//
//                    }
//                }
//            }
//        }
//        .frame(maxWidth: infoContentMaxWidth)
//    }
//}
