//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventDetailOverviewView.swift
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

// MARK: EventDetailOverviewView
struct EventDetailOverviewView: View {
    let information: ExtendedEvent
    @State var eventCharacterPercentageDict: [Int: [_DoriAPI.Events.EventCharacter]] = [:]
    @State var eventCharacterNameDict: [Int: LocalizedData<String>] = [:]
    @State var cardsArray: [PreviewCard] = []
    @State var cardsArraySeperated: [[PreviewCard?]] = []
    @State var cardsPercentage: Int = -100
    @State var rewardsArray: [PreviewCard] = []
    @State var cardsTitleWidth: CGFloat = 0 // Fixed
    @State var cardsPercentageWidth: CGFloat = 0 // Fixed
    @State var cardsContentRegularWidth: CGFloat = 0 // Fixed
    @State var cardsFixedWidth: CGFloat = 0 //Fixed
    @State var cardsUseCompactLayout = true
    
    @State var accessibilityNavigationTargetCard = 0
    @State var accessibilityNavigationIsActive = false
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
                    
                    #if !APP_STORE
//                    CustomGroupBox(cornerRadius: 3417) {
////                        Text("\(information.event.bgm)")
//                        CompactAudioPlayer(url: information.event.bgm)
//                    }
                    #endif
                    
                    //MARK: Info
                    CustomGroupBox(cornerRadius: 20) {
                        VStack {
                            Group {
                                ListItem(title: {
                                    Text("Event.title")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.event.eventName)
                                })
                                
                                ListItem(title: {
                                    Text("Event.type")
                                        .bold()
                                }, value: {
                                    Text(information.event.eventType.localizedString)
                                })
                                
                                ListItem(title: {
                                    Text("Event.countdown")
                                        .bold()
                                }, value: {
                                    MultilingualTextForCountdown(information.event)
                                })
                                
                                ListItem(title: {
                                    Text("Event.start-date")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.event.startAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                                })
                                
                                ListItem(title: {
                                    Text("Event.end-date")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.event.endAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                                })
                                
                                ListItem(title: {
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
                                        .accessibilityLabel(String("\(attribute.attribute.selectorText), +\(attribute.percent)%"))
                                    }
                                })
                                
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
                                                        if let name = eventCharacterNameDict[value.characterID]?.forPreferredLocale() {
                                                            Text(name)
                                                        } else {
                                                            Text(verbatim: "Lorum Ipsum")
                                                                .foregroundStyle(Color(UIColor.placeholderText))
                                                                .redacted(reason: .placeholder)
                                                        }
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
                                    //                                    .accessibilityLabel("Event.character")
                                    .accessibilityValue("Accessibility.event.character.\(valueArray.count).\("+\(firstKey)%")")
                                    .accessibilityAction {}
                                    .accessibilityActions {
                                        ForEach(valueArray, id: \.self) { item in
                                            NavigationLink(destination: {
                                                CharacterDetailView(id: item.characterID)
                                            }, label: {
                                                if let name = eventCharacterNameDict[item.characterID]?.forPreferredLocale() {
                                                    Text(name)
                                                }
                                            })
                                        }
                                    }
                                    .accessibilityElement(children: .combine)
                                } else {
                                    // Fallback to legacy render mode
                                    ListItem(title: {
                                        Text("Event.character")
                                            .bold()
                                            .fixedSize(horizontal: true, vertical: true)
                                        //                                Text("*")
                                    }, value: {
                                        VStack(alignment: .trailing) {
                                            let keys = eventCharacterPercentageDict.keys.sorted()
                                            ForEach(keys, id: \.self) { percentage in
                                                HStack {
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
                                                                    Text(eventCharacterNameDict[char.characterID]?.forPreferredLocale() ?? "Unknown")
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
                                    .accessibilityValue("Accessibility.event.character.\(eventCharacterPercentageDict.keys.count)")
                                }
                                
                                if let paramters = information.event.eventCharacterParameterBonus, paramters.total > 0 {
                                    ListItem(title: {
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
                                }
                                
                                if !cardsArray.isEmpty {
                                    ListItem(displayMode: .compactOnly, title: {
                                        Text("Event.card")
                                            .bold()
                                    }, value: {
                                        WrappingHStack(alignment: .trailing, contentWidth: cardThumbnailSideLength) {
                                            ForEach(cardsArray) { card in
                                                NavigationLink(destination: {
                                                    CardDetailView(id: card.id)
                                                }, label: {
                                                    CardPreviewImage(card, sideLength: cardThumbnailSideLength, showNavigationHints: true)
                                                })
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .accessibilityRepresentation {
                                            ForEach(cardsArray) { card in
                                                NavigationLink(destination: {
                                                    CardDetailView(id: card.id)
                                                }, label: {
                                                    CardPreviewImage(card, sideLength: cardThumbnailSideLength, showNavigationHints: true)
                                                })
                                                .buttonStyle(.plain)
                                                .accessibilityAction {}
                                            }
                                        }
                                        .accessibilityActions {
                                            ForEach(cardsArray) { card in
                                                NavigationLink(destination: {
                                                    CardDetailView(id: card.id)
                                                }, label: {
                                                    CardPreviewImage(card, sideLength: cardThumbnailSideLength, showNavigationHints: true)
                                                })
                                            }
                                        }
                                    })
                                    .accessibilityValue("Accessibility.event.card.\(cardsArray.count)")
                                    .accessibilityAction {}
                                    
//.accessibilityElement(children: .combine)
                                    
                                }
                                
                                if !rewardsArray.isEmpty {
                                    ListItem(title: {
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
                                    .accessibilityValue("Accessibility.event.card.\(rewardsArray.count)")
                                    .accessibilityAction {}
                                    .accessibilityActions {
                                        ForEach(rewardsArray) { card in
                                            NavigationLink(destination: {
                                                CardDetailView(id: card.id)
                                            }, label: {
                                                CardPreviewImage(card, sideLength: cardThumbnailSideLength, showNavigationHints: true)
                                            })
                                        }
                                    }
                                    .accessibilityElement(children: .combine)
                                }
                                
                                ListItem(title: {
                                    Text("ID")
                                        .bold()
                                }, value: {
                                    Text("\(String(information.id))")
                                })
                            }
                            .insert {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: infoContentMaxWidth)
        .onAppear {
            eventCharacterPercentageDict = [:]
            rewardsArray = []
            cardsArray = []
            let eventCharacters = information.event.characters
            for char in eventCharacters {
                eventCharacterPercentageDict.updateValue(((eventCharacterPercentageDict[char.percent] ?? []) + [char]), forKey: char.percent)
                Task {
                    if let allCharacters = await Character.all() {
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
