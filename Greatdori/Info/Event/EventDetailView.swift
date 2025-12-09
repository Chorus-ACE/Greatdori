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
                .wrapIf(information.event.eventType == .festival) {
                    $0.appendingView { EventDetailRotationMusicView(information: information) }
                }
            EventDetailStageView(information: information)
            EventDetailGoalsView(information: information)
            EventDetailTeamsView(information: information)
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
            
            ExternalLinksSection(links: [ExternalLink(name: "External-link.bestdori", url: URL(string: "https://bestdori.com/info/events/\(id)")!)])
        } switcherDestination: {
            EventSearchView()
        }
    }
}
