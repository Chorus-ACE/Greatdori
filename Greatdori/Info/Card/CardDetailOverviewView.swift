//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardDetailOverviewView.swift
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

import AVKit
import DoriKit
import SDWebImageSwiftUI
import SwiftUI

// MARK: CardDetailOverviewView
struct CardDetailOverviewView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let information: ExtendedCard
    @State private var allSkills: [Skill] = []
    let cardCoverScalingFactor: CGFloat = 1
    var body: some View {
        DetailInfoBase {
            DetailInfoItem("Card.title", text: information.card.cardName)
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
                    .accessibilityLabel(information.character.characterName.forPreferredLocale() ?? "")
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
                .accessibilityLabel("\(information.card.rarity)")
            }
            if let skill = allSkills.first(where: { $0.id == information.card.skillID }) {
                DetailInfoItem("Card.skill", text: skill.maximumDescription)
            }
            if !information.card.gachaText.isValueEmpty {
                DetailInfoItem("Card.gacha-quote") {
                    MultilingualText(information.card.gachaText)
                    CompactAudioPlayer(url: information.card.gachaVoiceURL, showPlayButtonOnly: true)
                }
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
                if let url = information.card.animationVideoURL {
                    VideoPlayer(player: .init(url: url))
                        .aspectRatio(4/3, contentMode: .fit)
                }
                CustomGroupBox(cornerRadius: 3417) {
                    if !information.card.gachaText.isValueEmpty {
                        CompactAudioPlayer(url: information.card.gachaVoiceURL)
                    }
                }
                .frame(maxWidth: infoContentMaxWidth)
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
