//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventDetailView.swift
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


// MARK: EventDetailView
struct EventDetailView: View {
    var id: Int
    var allEvents: [PreviewEvent]?
    var body: some View {
        DetailViewBase("Event", previewList: allEvents, initialID: id) { information in
            EventDetailOverviewView(information: information)
            DetailsGachasSection(gachas: information.gacha, applyLocaleFilter: false)
            DetailArtsSection {
                ArtsTab(id: "banner", name: "Event.arts.banner") {
                    for locale in DoriLocale.allCases {
                        if let url = information.event.bannerImageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url)
                        }
                        if let url = information.event.homeBannerImageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url)
                        }
                    }
                }
                ArtsTab(id: "logo", name: "Event.arts.logo") {
                    for locale in DoriLocale.allCases {
                        if let url = information.event.logoImageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url)
                        }
                    }
                }
                ArtsTab(id: "home-screen", name: "Event.arts.home-screen") {
                    ArtsItem(title: "Event.arts.home-screen.characters", url: information.event.topScreenTrimmedImageURL)
                    ArtsItem(title: "Event.arts.home-screen.background", url: information.event.topScreenBackgroundImageURL)
                }
            }
        } switcherDestination: {
            EventSearchView()
        }
    }
}


// MARK: EventDetailOverviewView
struct EventDetailOverviewView: View {
    let information: DoriFrontend.Event.ExtendedEvent
    @State var eventCharacterPercentageDict: [Int: [DoriAPI.Event.EventCharacter]] = [:]
    @State var eventCharacterNameDict: [Int: DoriAPI.LocalizedData<String>] = [:]
    @State var cardsArray: [DoriFrontend.Card.PreviewCard] = []
    @State var cardsArraySeperated: [[DoriFrontend.Card.PreviewCard?]] = []
    @State var cardsPercentage: Int = -100
    @State var rewardsArray: [DoriFrontend.Card.PreviewCard] = []
    @State var cardsTitleWidth: CGFloat = 0 // Fixed
    @State var cardsPercentageWidth: CGFloat = 0 // Fixed
    @State var cardsContentRegularWidth: CGFloat = 0 // Fixed
    @State var cardsFixedWidth: CGFloat = 0 //Fixed
    @State var cardsUseCompactLayout = true
    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
    var body: some View {
        Group {
            VStack {
                Group {
                    //MARK: Title Image
                    Group {
                        Rectangle()
                            .opacity(0)
                            .frame(height: 2)
                        FallbackableWebImage(throughURLs: [information.event.bannerImageURL, information.event.homeBannerImageURL]) { image in
                            image
                                .antialiased(true)
                                .resizable()
                                .aspectRatio(3.0, contentMode: .fit)
                                .frame(maxWidth: bannerWidth, maxHeight: bannerWidth/3)
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(getPlaceholderColor())
                                .aspectRatio(3.0, contentMode: .fit)
                                .frame(maxWidth: bannerWidth, maxHeight: bannerWidth/3)
                        }
                        .interpolation(.high)
                        .upscale { image in
                            image
                                .antialiased(true)
                                .resizable()
                                .aspectRatio(3.0, contentMode: .fit)
                                .frame(maxWidth: bannerWidth, maxHeight: bannerWidth/3)
                        }
                        .cornerRadius(10)
                        Rectangle()
                            .opacity(0)
                            .frame(height: 2)
                    }
                    
                    //MARK: Info
                    CustomGroupBox(cornerRadius: 20) {
                        VStack {
                            //MARK: Title
                            Group {
                                ListItemView(title: {
                                    Text("Event.title")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.event.eventName)
                                })
                                Divider()
                            }
                            
                            //MARK: Type
                            Group {
                                ListItemView(title: {
                                    Text("Event.type")
                                        .bold()
                                }, value: {
                                    Text(information.event.eventType.localizedString)
                                })
                                Divider()
                            }
                            
                            //MARK: Countdown
                            Group {
                                ListItemView(title: {
                                    Text("Event.countdown")
                                        .bold()
                                }, value: {
                                    MultilingualTextForCountdown(information.event)
                                })
                                Divider()
                            }
                            
                            //MARK: Start Date
                            Group {
                                ListItemView(title: {
                                    Text("Event.start-date")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.event.startAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                                })
                                Divider()
                            }
                            
                            //MARK: End Date
                            Group {
                                ListItemView(title: {
                                    Text("Event.end-date")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.event.endAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                                })
                                Divider()
                            }
                            
                            //MARK: Attribute
                            Group {
                                ListItemView(title: {
                                    Text("Event.attribute")
                                        .bold()
                                }, value: {
                                    ForEach(information.event.attributes, id: \.attribute.rawValue) { attribute in
                                        VStack(alignment: .trailing) {
                                            HStack {
                                                WebImage(url: attribute.attribute.iconImageURL)
                                                    .antialiased(true)
                                                    .resizable()
                                                    .frame(width: imageButtonSize, height: imageButtonSize)
                                                Text(verbatim: "+\(attribute.percent)%")
                                            }
                                        }
                                    }
                                })
                                Divider()
                            }
                            
                            //MARK: Character
                            Group {
                                if let firstKey = eventCharacterPercentageDict.keys.first, let valueArray = eventCharacterPercentageDict[firstKey], eventCharacterPercentageDict.keys.count == 1 {
                                    ListItemWithWrappingView(title: {
                                        Text("Event.character")
                                            .bold()
                                            .fixedSize(horizontal: true, vertical: true)
                                    }, element: { value in
#if os(macOS)
                                        if let value = value {
                                            NavigationLink(destination: {
                                                CharacterDetailView(id: value.characterID)
                                            }, label: {
                                                WebImage(url: value.iconImageURL)
                                                    .antialiased(true)
                                                    .resizable()
                                                    .frame(width: imageButtonSize, height: imageButtonSize)
                                            })
                                            .buttonStyle(.plain)
                                        } else {
                                            Rectangle()
                                                .opacity(0)
                                                .frame(width: 0, height: 0)
                                        }
#else
                                        if let value = value {
                                            Menu(content: {
                                                NavigationLink(destination: {
                                                    CharacterDetailView(id: value.characterID)
                                                }, label: {
                                                    HStack {
                                                        WebImage(url: value.iconImageURL)
                                                            .antialiased(true)
                                                            .resizable()
                                                            .frame(width: imageButtonSize, height: imageButtonSize)
                                                        //                                                Text(char.name)
                                                        if let name = eventCharacterNameDict[value.characterID]?.forPreferredLocale() {
                                                            Text(name)
                                                        } else {
                                                            Text(verbatim: "Lorum Ipsum")
                                                                .foregroundStyle(Color(UIColor.placeholderText))
                                                                .redacted(reason: .placeholder)
                                                        }
                                                        //                                                        Spacer()
                                                    }
                                                })
                                            }, label: {
                                                WebImage(url: value.iconImageURL)
                                                    .antialiased(true)
                                                    .resizable()
                                                    .frame(width: imageButtonSize, height: imageButtonSize)
                                            })
                                        } else {
                                            Rectangle()
                                                .opacity(0)
                                                .frame(width: 0, height: 0)
                                        }
#endif
                                    }, caption: {
                                        Text("+\(firstKey)%")
                                            .lineLimit(1)
                                            .fixedSize(horizontal: true, vertical: true)
                                    }, contentArray: valueArray, columnNumbers: 5, elementWidth: imageButtonSize)
                                } else {
                                    // Fallback to legacy render mode
                                    ListItemView(title: {
                                        Text("Event.character")
                                            .bold()
                                            .fixedSize(horizontal: true, vertical: true)
                                        //                                Text("*")
                                    }, value: {
                                        VStack(alignment: .trailing) {
                                            let keys = eventCharacterPercentageDict.keys.sorted()
                                            ForEach(keys, id: \.self) { percentage in
                                                HStack {
                                                    //                                                    Spacer()
                                                    ForEach(eventCharacterPercentageDict[percentage]!, id: \.self) { char in
#if os(macOS)
                                                        NavigationLink(destination: {
                                                            CharacterDetailView(id: char.characterID)
                                                        }, label: {
                                                            WebImage(url: char.iconImageURL)
                                                                .antialiased(true)
                                                                .resizable()
                                                                .frame(width: imageButtonSize, height: imageButtonSize)
                                                        })
                                                        .buttonStyle(.plain)
#else
                                                        Menu(content: {
                                                            NavigationLink(destination: {
                                                                CharacterDetailView(id: char.characterID)
                                                            }, label: {
                                                                HStack {
                                                                    WebImage(url: char.iconImageURL)
                                                                        .antialiased(true)
                                                                        .resizable()
                                                                        .frame(width: imageButtonSize, height: imageButtonSize)
                                                                    //                                                Text(char.name)
                                                                    Text(eventCharacterNameDict[char.characterID]?.forPreferredLocale() ?? "Unknown")
                                                                    //                                                                    Spacer()
                                                                }
                                                            })
                                                        }, label: {
                                                            WebImage(url: char.iconImageURL)
                                                                .antialiased(true)
                                                                .resizable()
                                                                .frame(width: imageButtonSize, height: imageButtonSize)
                                                        })
#endif
                                                    }
                                                    Text("+\(percentage)%")
                                                        .fixedSize(horizontal: true, vertical: true)
                                                }
                                            }
                                        }
                                    })
                                }
                                Divider()
                            }
                            
                            //MARK: Parameter
                            if let paramters = information.event.eventCharacterParameterBonus, paramters.total > 0 {
                                ListItemView(title: {
                                    Text("Event.parameter")
                                        .bold()
                                }, value: {
                                    VStack(alignment: .trailing) {
                                        if paramters.performance > 0 {
                                            HStack {
                                                Text("Event.parameter.performance")
                                                Text("+\(paramters.performance)%")
                                            }
                                        }
                                        if paramters.technique > 0 {
                                            HStack {
                                                Text("Event.parameter.technique")
                                                Text("+\(paramters.technique)%")
                                            }
                                        }
                                        if paramters.visual > 0 {
                                            HStack {
                                                Text("Event.parameter.visual")
                                                Text("+\(paramters.visual)%")
                                            }
                                        }
                                    }
                                })
                                Divider()
                            }
                            
                            //MARK: Card
                            if !cardsArray.isEmpty {
                                ListItemView(title: {
                                    Text("Event.card")
                                        .bold()
                                }, value: {
                                    WrappingHStack(hSpacing: 0, contentWidth: cardThumbnailSideLength) {
                                        ForEach(cardsArray) { card in
                                            NavigationLink(destination: {
                                                CardDetailView(id: card.id)
                                            }, label: {
                                                CardPreviewImage(card, sideLength: cardThumbnailSideLength, showNavigationHints: true)
                                            })
                                            .buttonStyle(.plain)
                                        }
                                    }
                                }, displayMode: .compactOnly)
                                Divider()
                            }
                            
                            //MARK: Rewards
                            if !rewardsArray.isEmpty {
                                ListItemView(title: {
                                    Text("Event.rewards")
                                        .bold()
                                }, value: {
                                    ForEach(rewardsArray) { card in
                                        NavigationLink(destination: {
                                            CardDetailView(id: card.id)
                                        }, label: {
                                            CardPreviewImage(card, sideLength: cardThumbnailSideLength, showNavigationHints: true)
                                        })
                                        .contentShape(Rectangle())
                                        .buttonStyle(.plain)
                                        
                                    }
                                })
                                Divider()
                            }
                            
                            
                            //MARK: ID
                            Group {
                                ListItemView(title: {
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
        }
        .frame(maxWidth: 600)
        .onAppear {
            eventCharacterPercentageDict = [:]
            rewardsArray = []
            cardsArray = []
            let eventCharacters = information.event.characters
            for char in eventCharacters {
                eventCharacterPercentageDict.updateValue(((eventCharacterPercentageDict[char.percent] ?? []) + [char]), forKey: char.percent)
                Task {
                    if let allCharacters = await DoriAPI.Character.all() {
                        if let character = allCharacters.first(where: { $0.id == char.characterID }) {
                            eventCharacterNameDict.updateValue(character.characterName, forKey: char.characterID)
                        }
                    }
                    
                }
            }
            for card in information.cards {
                if information.event.rewardCards.contains(card.id) {
                    rewardsArray.append(card)
                } else {
                    cardsArray.append(card)
                    if cardsPercentage == -100 {
                        cardsPercentage = information.event.members.first(where: { $0.situationID == card.id })?.percent ?? -200
                    }
                }
            }
            cardsArraySeperated = cardsArray.chunked(into: 3)
            for i in 0..<cardsArraySeperated.count {
                while cardsArraySeperated[i].count < 3 {
                    cardsArraySeperated[i].insert(nil, at: 0)
                }
            }
        }
    }
}
