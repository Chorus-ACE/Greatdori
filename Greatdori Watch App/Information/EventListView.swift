//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventListView.swift
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

struct EventListView: View {
    @State var filter = DoriFilter.recoverable(id: "EventList")
    @State var sorter = DoriSorter.recoverable(id: "EventList")
    @State var events: [PreviewEvent]?
    @State var isFilterSettingsPresented = false
    @State var isSearchPresented = false
    @State var searchInput = ""
    @State var searchedEvents: [PreviewEvent]?
    @State var availability = true
    var body: some View {
        List {
            if let events = searchedEvents ?? events {
                ForEach(events) { event in
                    NavigationLink(destination: { EventDetailView(id: event.id) }) {
                        EventCardView(event, inLocale: nil)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入活动时出错", systemImage: "star.hexagon.fill", retryHandler: getEvents)
                }
            }
        }
        .navigationTitle("活动")
        .sheet(isPresented: $isFilterSettingsPresented) {
            Task {
                events = nil
                await getEvents()
            }
        } content: {
            FilterView(filter: $filter, sorter: $sorter, includingKeys: [
                .attribute,
                .character,
                .characterRequiresMatchAll,
                .server,
                .timelineStatus,
                .eventType
            ], includingKeywords: [
                .releaseDate(in: .jp),
                .releaseDate(in: .en),
                .releaseDate(in: .tw),
                .releaseDate(in: .cn),
                .releaseDate(in: .kr),
                .id
            ]) {
                if let events {
                    SearchView(items: events, text: $searchInput) { result in
                        searchedEvents = result
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    isFilterSettingsPresented = true
                }, label: {
                    Image(systemName: "line.3.horizontal.decrease")
                })
                .tint(filter.isFiltered || !searchInput.isEmpty ? .accent : nil)
            }
        }
        .task {
            await getEvents()
        }
    }
    
    func getEvents() async {
        availability = true
        withDoriCache(id: "EventList_\(filter.identity)_\(sorter.identity)") {
            await PreviewEvent.all()?
                .filter(withDoriFilter: filter)
                .sorted(withDoriSorter: sorter)
        }.onUpdate {
            if let events = $0 {
                self.events = events
            } else {
                availability = false
            }
        }
    }
}
