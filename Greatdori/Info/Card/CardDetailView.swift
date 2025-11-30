//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardDetailView.swift
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


// MARK: CardDetailView
struct CardDetailView: View {
    var id: Int
    var allCards: [CardWithBand]? = nil
    var body: some View {
        DetailViewBase(forType: ExtendedCard.self, previewList: allCards, initialID: id) { information in
            CardDetailOverviewView(information: information)
            CardDetailStatsView(card: information.card)
            DetailsCostumesSection(costumes: [information.costume])
            if !information.event.isEmpty || information.cardSource.containsSource(from: .event) {
                DetailsEventsSection(event: information.event, sources: information.cardSource)
            }
            if information.cardSource.containsSource(from: .gacha) {
                DetailsGachasSection(sources: information.cardSource)
            }
            CardDetailStoriesView(information: information)
            DetailArtsSection {
                ArtsTab("Card.arts.full", ratio: 1334/1002) {
                    ArtsItem(title: "Card.arts.normal", url: information.card.coverNormalImageURL)
                    if let url = information.card.coverAfterTrainingImageURL {
                        ArtsItem(title: "Card.arts.trained", url: url)
                    }
                }
                ArtsTab("Card.arts.trimmed", ratio: 1) {
                    ArtsItem(title: "Card.arts.normal", url: information.card.trimmedNormalImageURL)
                    if let url = information.card.trimmedAfterTrainingImageURL {
                        ArtsItem(title: "Card.arts.trained", url: url)
                    }
                }
                ArtsTab("Card.arts.thumb", ratio: 1) {
                    ArtsItem(title: "Card.arts.normal", url: information.card.thumbNormalImageURL)
                    if let url = information.card.thumbAfterTrainingImageURL {
                        ArtsItem(title: "Card.arts.trained", url: url)
                    }
                }
                ArtsTab("Card.arts.livesd", ratio: 1) {
                    ArtsItem(title: "Card.arts.livesd", url: information.card.sdImageURL)
                }
            }
        } switcherDestination: {
            CardSearchView()
        }
    }
}


// MARK: CardDetailOverviewView
struct CardDetailOverviewView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let information: ExtendedCard
    @State private var allSkills: [Skill] = []
    let cardCoverScalingFactor: CGFloat = 1
    var body: some View {
        DetailInfoBase {
            DetailInfoItem("Card.title", text: information.card.prefix)
            DetailInfoItem("Card.type", text: information.card.type.localizedString)
            DetailInfoItem("Card.character") {
                NavigationLink(destination: {
                    CharacterDetailView(id: information.character.id)
                }, label: {
                    HStack {
                        MultilingualText(information.character.characterName)
                        WebImage(url: information.character.iconImageURL)
                            .resizable()
                            .clipShape(Circle())
                            .frame(width: imageButtonSize, height: imageButtonSize)
                    }
                })
            }
            DetailInfoItem("Card.band") {
                HStack {
                    MultilingualText(information.band.bandName, allowPopover: false)
                    WebImage(url: information.band.iconImageURL)
                        .resizable()
                        .frame(width: imageButtonSize, height: imageButtonSize)
                }
            }
            DetailInfoItem("Card.attribute") {
                HStack {
                    Text(information.card.attribute.selectorText.uppercased())
                    WebImage(url: information.card.attribute.iconImageURL)
                        .resizable()
                        .frame(width: imageButtonSize, height: imageButtonSize)
                }
            }
            DetailInfoItem("Card.rarity") {
                HStack(spacing: 0) {
                    ForEach(1...information.card.rarity, id: \.self) { _ in
                        Image(information.card.rarity >= 3 ? .trainedStar : .star)
                            .resizable()
                            .frame(width: imageButtonSize, height: imageButtonSize)
                            .padding(.top, -1)
                    }
                }
            }
            if let skill = allSkills.first(where: { $0.id == information.card.skillID }) {
                DetailInfoItem("Card.skill", text: skill.maximumDescription)
            }
            if !information.card.gachaText.isValueEmpty {
                DetailInfoItem("Card.gacha-quote", text: information.card.gachaText)
            }
            DetailInfoItem("Card.release-date", date: information.card.releasedAt)
                .showsLocaleKey()
            DetailInfoItem("ID", text: "\(String(information.id))")
        } head: {
            VStack {
                CardCoverImage(information.card, band: information.band)
                    .wrapIf(sizeClass == .regular) { content in
                        content
                            .frame(maxWidth: 480*cardCoverScalingFactor, maxHeight: 320*cardCoverScalingFactor)
                    } else: { content in
                        content
                    }
                CompactAudioPlayer(url: information.card.gachaVoiceURL)
            }
        }
        .task {
            // Load skills asynchronously once when the view appears
            if allSkills.isEmpty {
                if let fetched = await Skill.all() {
                    allSkills = fetched
                }
            }
        }
    }
}

struct CardDetailStoriesView: View {
    var information: ExtendedCard
    @State private var locale = DoriLocale.primaryLocale
    var body: some View {
        if !information.card.episodes.isEmpty {
            LazyVStack(pinnedViews: .sectionHeaders) {
                Section {
                    ForEach(Array(information.card.episodes.enumerated()), id: \.element.id) { index, story in
                        if let title = story.title.forLocale(locale) {
                            StoryCardView(
                                story: CustomStory(
                                    scenarioID: story.scenarioID,
                                    caption: story.episodeType.localizedString,
                                    title: title,
                                    synopsis: "",
                                    voiceAssetBundleName: nil
                                ),
                                type: .event,
                                locale: locale,
                                unsafeAssociatedID: information.card.resourceSetName
                            )
                        }
                    }
                } header: {
                    HStack {
                        Text("Card.story")
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
