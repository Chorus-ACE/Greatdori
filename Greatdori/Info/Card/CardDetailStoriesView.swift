//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardDetailStoriesView.swift
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
import SwiftUI

struct CardDetailStoriesView: View {
    var information: ExtendedCard
    @State private var locale = DoriLocale.primaryLocale
    var body: some View {
        if !information.card.episodes.isEmpty {
            Section {
                VStack {
                    if information.card.episodes[0].title.forLocale(locale) != nil {
                        ForEach(Array(information.card.episodes.enumerated()), id: \.element.id) { index, story in
                            StoryCardView(
                                story: CustomStory(
                                    scenarioID: story.scenarioID,
                                    caption: story.episodeType.localizedString,
                                    title: story.title,
                                    synopsis: "",
                                    voiceAssetBundleName: nil
                                ),
                                type: .card,
                                locale: locale,
                                unsafeAssociatedID: information.card.resourceSetName
                            )
                        }
                    } else {
                        DetailUnavailableView(title: "Details.unavailable.story", symbol: "books.vertical")
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
                .detailSectionHeader()
            }
            .frame(maxWidth: infoContentMaxWidth)
        }
    }
}
