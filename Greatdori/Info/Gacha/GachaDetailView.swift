//===---*- Greatdori! -*---------------------------------------------------===//
//
// GachaDetailView.swift
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
import Foundation
import SDWebImageSwiftUI
import SwiftUI


// MARK: GachaDetailView
struct GachaDetailView: View {
    var id: Int
    var allGachas: [PreviewGacha]? = nil
    var body: some View {
        DetailViewBase(previewList: allGachas, initialID: id) { information in
            GachaDetailOverviewView(information: information)
            DetailsEventsSection(events: information.events, applyLocaleFilter: true)
            GachaDetailCardsView(information: information)
            GachaDetailPossibilityView(information: information)
            GachaDetailConsumptionView(information: information)
            DetailArtsSection {
                ArtsTab("Gacha.arts.banner", ratio: 3) {
                    for locale in DoriLocale.allCases {
                        if let url = information.gacha.bannerImageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url)
                        }
                    }
                }
                ArtsTab("Gacha.arts.logo", ratio: 540/240) {
                    for locale in DoriLocale.allCases {
                        if let url = information.gacha.logoImageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url)
                        }
                    }
                }
                ArtsTab("Gacha.arts.pickup", ratio: 964/613) {
                    for locale in DoriLocale.allCases {
                        if let urls = information.gacha.pickupImageURLs(in: locale, allowsFallback: false) {
                            for i in 0..<urls.count {
                                ArtsItem(title: LocalizedStringResource(stringLiteral: "\(locale.rawValue.uppercased()) \(i+1)"), url: urls[i])
                            }
                        }
                    }
                }
            }
            ExternalLinksSection(links: [ExternalLink(name: "External-link.bestdori", url: URL(string: "https://bestdori.com/info/gacha/\(id)")!)])
        } switcherDestination: {
            GachaSearchView()
        }
    }
}


// MARK: GachaDetailOverviewView
struct GachaDetailOverviewView: View {
    let information: ExtendedGacha
    //    @State var gachaCharacterPercentageDict: [Int: [DoriAPI.Gacha.GachaCharacter]] = [:]
    //    @State var gachaCharacterNameDict: [Int: DoriAPI.LocalizedData<String>] = [:]
    @State var cardsArray: [PreviewCard] = []
    @State var cardsArraySeperated: [[PreviewCard?]] = []
    @State var cardsPercentage: Int = -100
    @State var rewardsArray: [PreviewCard] = []
    @State var cardsTitleWidth: CGFloat = 0 // Fixed
    @State var cardsPercentageWidth: CGFloat = 0 // Fixed
    @State var cardsContentRegularWidth: CGFloat = 0 // Fixed
    @State var cardsFixedWidth: CGFloat = 0 //Fixed
    @State var cardsUseCompactLayout = true
    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
    var body: some View {
        VStack {
            Group {
                // MARK: Title Image
                Group {
                    Rectangle()
                        .opacity(0)
                        .frame(height: 2)
                    WebImage(url: information.gacha.bannerImageURL) { image in
                        image
                            .antialiased(true)
                            .resizable()
                        //                            .aspectRatio(3.0, contentMode: .fit)
                            .scaledToFit()
                            .frame(maxWidth: bannerWidth,/* maxHeight: bannerWidth/3*/)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                        //                            .fill(Color.gray.opacity(0.15))
                            .fill(getPlaceholderColor())
                            .aspectRatio(3.0, contentMode: .fit)
                            .frame(maxWidth: bannerWidth, maxHeight: bannerWidth/3)
                    }
                    .interpolation(.high)
                    .cornerRadius(10)
                    Rectangle()
                        .opacity(0)
                        .frame(height: 2)
                }
                
                
                // MARK: Info
                CustomGroupBox(cornerRadius: 20) {
                    VStack {
                        // MARK: Title
                        Group {
                            ListItem(title: {
                                Text("Gacha.title")
                                    .bold()
                            }, value: {
                                MultilingualText(information.gacha.gachaName)
                            })
                            Divider()
                        }
                        
                        // MARK: Type
                        Group {
                            ListItem(title: {
                                Text("Gacha.type")
                                    .bold()
                            }, value: {
                                Text(information.gacha.type.localizedString)
                            })
                            Divider()
                        }
                        
                        // MARK: Countdown
                        Group {
                            ListItem(title: {
                                Text("Gacha.countdown")
                                    .bold()
                            }, value: {
                                MultilingualTextForCountdown(information.gacha)
                            })
                            Divider()
                        }
                        
                        // MARK: Release Date
                        Group {
                            ListItem(title: {
                                Text("Gacha.release-date")
                                    .bold()
                            }, value: {
                                MultilingualText(information.gacha.publishedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                            })
                            Divider()
                        }
                        
                        // MARK: Close Date
                        Group {
                            ListItem(title: {
                                Text("Gacha.close-date")
                                    .bold()
                            }, value: {
                                MultilingualText(information.gacha.closedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                            })
                            Divider()
                        }
                        
                        // MARK: Spotlight Card
                        if !information.pickupCards.isEmpty {
                            ListItem {
                                Text("Gacha.spotlight-card")
                                    .bold()
                            } value: {
                                WrappingHStack(alignment: .trailing, contentWidth: cardThumbnailSideLength) {
                                    ForEach(information.pickupCards) { card in
                                        NavigationLink(destination: {
                                            CardDetailView(id: card.id)
                                        }, label: {
                                            CardPreviewImage(card, sideLength: cardThumbnailSideLength, showNavigationHints: true)
                                        })
                                        .buttonStyle(.plain)
                                    }
                                }
                                .layoutPriority(1)
                            }
                            Divider()
                        }
                        
                        // MARK: Description
                        Group {
                            ListItem(title: {
                                Text("Gacha.descripition")
                                    .bold()
                            }, value: {
                                MultilingualText(information.gacha.description)
                            })
                            .listItemLayout(.basedOnUISizeClass)
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
        .onAppear {
            /*
             gachaCharacterPercentageDict = [:]
             rewardsArray = []
             cardsArray = []
             let gachaCharacters = information.gacha.characters
             for char in gachaCharacters {
             gachaCharacterPercentageDict.updateValue(((gachaCharacterPercentageDict[char.percent] ?? []) + [char]), forKey: char.percent)
             Task {
             if let allCharacters = await DoriAPI.Character.all() {
             if let character = allCharacters.first(where: { $0.id == char.characterID }) {
             gachaCharacterNameDict.updateValue(character.characterName, forKey: char.characterID)
             }
             }
             
             }
             }
             for card in information.cards {
             if information.gacha.rewardCards.contains(card.id) {
             rewardsArray.append(card)
             } else {
             cardsArray.append(card)
             if cardsPercentage == -100 {
             cardsPercentage = information.gacha.members.first(where: { $0.situationID == card.id })?.percent ?? -200
             }
             }
             }
             cardsArraySeperated = cardsArray.chunked(into: 3)
             for i in 0..<cardsArraySeperated.count {
             while cardsArraySeperated[i].count < 3 {
             cardsArraySeperated[i].insert(nil, at: 0)
             }
             }
             */
        }
        
    }
}



