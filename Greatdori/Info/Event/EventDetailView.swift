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
            DetailsSongsSection(
                songs: .init(
                    _jp: songs(for: .jp, with: information),
                    en: songs(for: .en, with: information),
                    tw: songs(for: .tw, with: information),
                    cn: songs(for: .cn, with: information),
                    kr: songs(for: .kr, with: information)
                ),
                subtitles: {
                    var result: [Int: LocalizedStringKey] = [:]
                    for song in information.songs {
                        result.updateValue("Detail.source.released-during-event", forKey: song.id)
                    }
                    for locale in DoriLocale.allCases {
                        information.eventSongs?.forLocale(locale)?.forEach {
                            result.updateValue("Detail.songs.source.event-song", forKey: $0.id)
                        }
                    }
                    return result
                }()
            )
            .wrapIf(information.event.eventType == .festival) {
                $0.appendingView { EventDetailRotationMusicView(information: information) }
            }
            EventDetailStageView(information: information)
            EventDetailGoalsView(information: information)
            EventDetailTeamsView(information: information)
            EventDetailDegreesView(information: information)
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
    
    private func songs(for locale: DoriLocale, with information: ExtendedEvent) -> [PreviewSong] {
        Array(Set(information.songs.filter { $0.publishedAt.forLocale(locale) != nil }
        + (information.eventSongs?.forLocale(locale) ?? [])))
    }
}
