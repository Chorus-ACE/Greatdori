//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventDetailView.swift
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


// MARK: EventDetailView
struct EventDetailView: View {
    var id: Int
    var allEvents: [PreviewEvent]?
    var body: some View {
        DetailViewBase(previewList: allEvents, initialID: id) { information in
            EventDetailOverviewView(information: information)
            DetailsGachasSection(gachas: information.gacha, applyLocaleFilter: true)
            DetailsSongsSection(songs: information.songs)
            EventDetailGoalsView(information: information)
            EventDetailTeamView(information: information)
            EventDetailStoriesView(information: information)
            DetailArtsSection {
                ArtsTab("Event.arts.banner", ratio: 3) {
                    for locale in DoriLocale.allCases {
                        if let url = information.event.bannerImageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url)
                        }
                        if let url = information.event.homeBannerImageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url)
                        }
                    }
                }
                ArtsTab("Event.arts.logo", ratio: 450/200) {
                    for locale in DoriLocale.allCases {
                        if let url = information.event.logoImageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url)
                        }
                    }
                }
                ArtsTab("Event.arts.home-screen") {
                    ArtsItem(title: "Event.arts.home-screen.characters", url: information.event.topScreenTrimmedImageURL, ratio: 1)
                    ArtsItem(title: "Event.arts.home-screen.background", url: information.event.topScreenBackgroundImageURL, ratio: 816/613)
                }
            }
        } switcherDestination: {
            EventSearchView()
        }
    }
}


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
                                ListItem(title: {
                                    Text("Event.title")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.event.eventName)
                                })
                                Divider()
                            }
                            
                            //MARK: Type
                            Group {
                                ListItem(title: {
                                    Text("Event.type")
                                        .bold()
                                }, value: {
                                    Text(information.event.eventType.localizedString)
                                })
                                Divider()
                            }
                            
                            //MARK: Countdown
                            Group {
                                ListItem(title: {
                                    Text("Event.countdown")
                                        .bold()
                                }, value: {
                                    MultilingualTextForCountdown(information.event)
                                })
                                Divider()
                            }
                            
                            //MARK: Start Date
                            Group {
                                ListItem(title: {
                                    Text("Event.start-date")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.event.startAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                                })
                                Divider()
                            }
                            
                            //MARK: End Date
                            Group {
                                ListItem(title: {
                                    Text("Event.end-date")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.event.endAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                                })
                                Divider()
                            }
                            
                            //MARK: Attribute
                            Group {
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
                                Divider()
                            }
                            
                            //MARK: Card
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
                                })
                                Divider()
                            }
                            
                            //MARK: Rewards
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
                                Divider()
                            }
                            
                            
                            //MARK: ID
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

struct EventDetailGoalsView: View {
    var information: ExtendedEvent
    var body: some View {
        if let missions = information.event.liveTryMissions,
           let missionDetails = information.event.liveTryMissionDetails,
           let missionTypeSeqs = information.event.liveTryMissionTypeSequences {
            LazyVStack(pinnedViews: .sectionHeaders) {
                Section(content: {
                    VStack {
                        let typedMissions = missions.reduce(into: [Event.LiveTryMissionType: [Event.LiveTryMission]]()) {
                            $0.updateValue(($0[$1.value.missionType] ?? []) + [$1.value], forKey: $1.value.missionType)
                        }.mapValues {
                            $0.sorted {
                                ($0.missionDifficultyType == $1.missionDifficultyType
                                 && $0.level < $1.level)
                                || $0.missionDifficultyType.rawValue > $1.missionDifficultyType.rawValue
                            }
                        }
                        ForEach(typedMissions.sorted {
                            (missionTypeSeqs[$0.key] ?? 0)
                            < (missionTypeSeqs[$1.key] ?? 0)
                        }, id: \.key) { type, missions in
                            SingleTypeGoalsView(
                                type: type,
                                missions: missions,
                                missionDetails: missionDetails
                            )
                        }
                    }
                    .frame(maxWidth: infoContentMaxWidth)
                }, header: {
                    HStack {
                        Text("Event.goals")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    .frame(maxWidth: 615)
                })
            }
        }
    }
    
    private struct SingleTypeGoalsView: View {
        var type: Event.LiveTryMissionType
        var missions: [Event.LiveTryMission]
        var missionDetails: [Int: Event.LiveTryMissionDetail]
        @State private var isExpanded = false
        var body: some View {
            CustomGroupBox {
                VStack {
                    HStack {
                        Text(type.localizedString)
                            .bold()
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .foregroundStyle(.secondary)
                            .rotationEffect(.init(degrees: isExpanded ? 90 : 0))
                            .font(isMACOS ? .body : .caption)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
                    
                    if isExpanded {
                        ForEach(Array(missions.enumerated()), id: \.element.missionID) { index, mission in
                            if let detail = missionDetails[mission.missionID] {
                                Divider()
                                ListItem {
                                    Text("Event.goals.level.\(mission.level).\(mission.missionDifficultyType == .extra ? " EX" : "")")
                                } value: {
                                    MultilingualText(detail.description.map({ $0?.replacing(#/\[[0-9A-Fa-f]{3,6}\]|\[-\]/#, with: "") }))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

struct EventDetailTeamView: View {
    var information: ExtendedEvent
    var body: some View {
        if let teams = information.event.teamList, teams.count >= 2 {
            CustomGroupBox {
                HStack {
                    Spacer()
                    VStack {
                        Text(teams[0].themeTitle)
                            .font(.title3)
                            .bold()
                            .multilineTextAlignment(.center)
                        HStack {
                            VStack {
                                WebImage(url: teams[0].iconImageURL(with: information.event))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                Text(teams[0].teamName)
                            }
                            Text(verbatim: "vs")
                                .padding(.horizontal, 20)
                            VStack {
                                WebImage(url: teams[1].iconImageURL(with: information.event))
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 100)
                                Text(teams[1].teamName)
                            }
                        }
                    }
                    Spacer()
                }
            }
            .frame(maxWidth: infoContentMaxWidth)
        }
    }
}

struct EventDetailStoriesView: View {
    var information: ExtendedEvent
    @State private var locale = DoriLocale.primaryLocale
    var body: some View {
        if !information.event.stories.isEmpty {
            LazyVStack(pinnedViews: .sectionHeaders) {
                Section {
                    ForEach(Array(information.event.stories.enumerated()), id: \.element.scenarioID) { index, story in
                        StoryCardView(
                            story: .init(story),
                            type: .event,
                            locale: locale,
                            unsafeAssociatedID: String(information.event.id),
                            unsafeSecondaryAssociatedID: String(index)
                        )
                    }
                } header: {
                    HStack {
                        Text("故事")
                            .font(.title2)
                            .bold()
                        DetailSectionOptionPicker(selection: $locale, options: DoriLocale.allCases)
                        Spacer()
                    }
                }
            }
            .frame(maxWidth: infoContentMaxWidth)
        }
    }
}
