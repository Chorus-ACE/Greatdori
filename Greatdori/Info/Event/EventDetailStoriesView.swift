//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventDetailStoriesView.swift
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

// MARK: EventDetailStroriesView
struct EventDetailStoriesView: View {
    var information: ExtendedEvent
    @State private var locale = DoriLocale.primaryLocale
    var body: some View {
        if !information.event.stories.isEmpty {
            Section {
                if information.event.stories[0].caption.forLocale(locale) != nil {
                    ForEach(Array(information.event.stories.enumerated()), id: \.element.scenarioID) { index, story in
                        StoryCardView(
                            story: .init(story),
                            type: .event,
                            locale: locale,
                            unsafeAssociatedID: String(information.event.id),
                            unsafeSecondaryAssociatedID: String(index),
                            notes: story.releaseConditions.forLocale(locale)
                        )
                    }
                } else {
                    DetailUnavailableView(title: "Details.unavailable.story", symbol: "star.hexagon")
                }
            } header: {
                HStack {
                    Text("Event.story")
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
