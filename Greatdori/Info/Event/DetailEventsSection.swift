//===---*- Greatdori! -*---------------------------------------------------===//
//
// DetailEventsSection.swift
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

import DoriKit
import SDWebImageSwiftUI
import SwiftUI


// MARK: DetailsEventsSection
struct DetailsEventsSection: View {
    var events: [PreviewEvent]?
    var event: DoriAPI.LocalizedData<PreviewEvent>?
    var sources: DoriAPI.LocalizedData<Set<ExtendedCard.Source>>?
    var applyLocaleFilter: Bool = false
    @State var locale: DoriLocale = DoriLocale.primaryLocale
    @State var eventsFromList: [PreviewEvent] = []
    @State var eventsFromSources: [PreviewEvent] = []
    @State var pointsDict: [PreviewEvent: Int] = [:]
    @State var showAll = false
    @State var sourcePreference: Int
    
    init(events: [PreviewEvent], applyLocaleFilter: Bool = false) {
        self.events = events
        self.event = nil
        self.sources = nil
        self.applyLocaleFilter = applyLocaleFilter
        self.sourcePreference = 0
    }
    init(event: DoriAPI.LocalizedData<PreviewEvent>, sources: DoriAPI.LocalizedData<Set<ExtendedCard.Source>>) {
        self.events = nil
        self.event = event
        self.sources = sources
        self.applyLocaleFilter = true
        self.sourcePreference = 1
    }
    
    var body: some View {
        DetailSectionBase("Details.events", elements: sourcePreference == 0 ? eventsFromList : eventsFromSources) { item in
            if sourcePreference == 0 {
                NavigationLink(destination: {
                    EventDetailView(id: item.id)
                }, label: {
                    EventInfo(item, showDetails: true)
                        .frame(maxWidth: 600)
                })
            } else {
                NavigationLink(destination: {
                    EventDetailView(id: item.id)
                }, label: {
                    EventInfo(item, subtitle: (pointsDict[item] == nil ? "Details.source.release-during-event" :"Details.events.source.rewarded-at-points.\(pointsDict[item]!)"), showDetails: true)
                        .frame(maxWidth: 600)
                })
            }
        }
        .contentUnavailablePrompt("Details.events.unavailable")
        .contentUnavailableImage(systemName: "star.hexagon")
        .onAppear {
            handleEvents()
        }
        .onChange(of: locale) {
            handleEvents()
        }
    }
    
    func handleEvents() {
        eventsFromList = []
        eventsFromSources = []
        pointsDict = [:]
        
        if sourcePreference == 0 {
            if let events {
                eventsFromList = events.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .releaseDate(in: applyLocaleFilter ? locale : .jp)))
                if applyLocaleFilter {
                    eventsFromList = eventsFromList.filter{$0.startAt.availableInLocale(locale)}
                }
            }
        } else {
            if let sources {
                for item in Array(sources.forLocale(locale) ?? Set()) {
                    switch item {
                    case .event(let dict):
                        for (key, value) in dict {
                            eventsFromSources.append(key)
                            pointsDict.updateValue(value, forKey: key)
                        }
                        eventsFromSources = eventsFromSources.sorted(withDoriSorter: DoriSorter(keyword: .releaseDate(in: locale)))
                    default: break
                    }
                }
            }
            if let localEvent = event?.forLocale(locale) {
                eventsFromSources.insert(localEvent, at: 0)
            }
        }
    }
    
    func getEventsCount() -> Int {
        if sourcePreference == 0 {
            return eventsFromList.count
        } else {
            return eventsFromSources.count
        }
    }
}
