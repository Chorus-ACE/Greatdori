//===---*- Greatdori! -*---------------------------------------------------===//
//
// GachaListView.swift
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

struct GachaListView: View {
    @State var filter = DoriFilter.recoverable(id: "GachaList")
    @State var sorter = DoriSorter.recoverable(id: "GachaList")
    @State var gacha: [PreviewGacha]?
    @State var isFilterSettingsPresented = false
    @State var isSearchPresented = false
    @State var searchInput = ""
    @State var searchedGacha: [PreviewGacha]?
    @State var availability = true
    var body: some View {
        List {
            if let gacha = searchedGacha ?? gacha {
                ForEach(gacha) { gacha in
                    NavigationLink(destination: { GachaDetailView(id: gacha.id) }) {
                        GachaCardView(gacha)
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
                    UnavailableView("载入招募时出错", systemImage: "line.horizontal.star.fill.line.horizontal", retryHandler: getGacha)
                }
            }
        }
        .navigationTitle("招募")
        .sheet(isPresented: $isFilterSettingsPresented) {
            Task {
                gacha = nil
                await getGacha()
            }
        } content: {
            FilterView(filter: $filter, sorter: $sorter, includingKeys: [
                .attribute,
                .character,
                .characterRequiresMatchAll,
                .server,
                .timelineStatus,
                .gachaType
            ], includingKeywords: [
                .releaseDate(in: .jp),
                .releaseDate(in: .en),
                .releaseDate(in: .tw),
                .releaseDate(in: .cn),
                .releaseDate(in: .kr),
                .id
            ]) {
                if let gacha {
                    SearchView(items: gacha, text: $searchInput) { result in
                        searchedGacha = result
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
            await getGacha()
        }
    }
    
    func getGacha() async {
        availability = true
        withDoriCache(id: "GachaList_\(filter.identity)_\(sorter.identity)") {
            await PreviewGacha.all()?
                .filter(withDoriFilter: filter)
                .sorted(withDoriSorter: sorter)
        }.onUpdate {
            if let gacha = $0 {
                self.gacha = gacha
            } else {
                availability = false
            }
        }
    }
}
