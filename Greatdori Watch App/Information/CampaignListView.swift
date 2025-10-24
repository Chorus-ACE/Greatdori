//===---*- Greatdori! -*---------------------------------------------------===//
//
// CampaignListView.swift
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

struct CampaignListView: View {
    @State var filter = DoriFilter.recoverable(id: "CampaignList")
    @State var sorter = DoriSorter.recoverable(id: "CampaignList")
    @State var campaigns: [PreviewLoginCampaign]?
    @State var isFilterSettingsPresented = false
    @State var isSearchPresented = false
    @State var searchInput = ""
    @State var searchedCampaigns: [PreviewLoginCampaign]?
    @State var availability = true
    var body: some View {
        List {
            if let campaigns = searchedCampaigns ?? campaigns {
                ForEach(campaigns) { campaign in
                    NavigationLink(destination: { CampaignDetailView(id: campaign.id) }) {
                        CampaignCardView(campaign)
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
                    UnavailableView("载入登录奖励时出错", systemImage: "_calendar.badge.ring.closed", retryHandler: getCampaigns)
                }
            }
        }
        .navigationTitle("登录奖励")
        .sheet(isPresented: $isFilterSettingsPresented) {
            Task {
                campaigns = nil
                await getCampaigns()
            }
        } content: {
            FilterView(filter: $filter, sorter: $sorter, includingKeys: [
                .loginCampaignType,
                .timelineStatus,
                .server
            ], includingKeywords: [
                .releaseDate(in: .jp),
                .releaseDate(in: .en),
                .releaseDate(in: .tw),
                .releaseDate(in: .cn),
                .releaseDate(in: .kr),
                .id
            ]) {
                if let campaigns {
                    SearchView(items: campaigns, text: $searchInput) { result in
                        searchedCampaigns = result
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
            await getCampaigns()
        }
    }
    
    func getCampaigns() async {
        availability = true
        withDoriCache(id: "CampaignList_\(filter.identity)_\(sorter.identity)") {
            await PreviewLoginCampaign.all()?
                .filter(withDoriFilter: filter)
                .sorted(withDoriSorter: sorter)
        }.onUpdate {
            if let campaigns = $0 {
                self.campaigns = campaigns
            } else {
                availability = false
            }
        }
    }
}
