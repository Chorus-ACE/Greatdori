//===---*- Greatdori! -*---------------------------------------------------===//
//
// CostumeListView.swift
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

import SwiftUI
import DoriKit

struct CostumeListView: View {
    @State var filter = DoriFilter.recoverable(id: "CostumeList")
    @State var sorter = DoriSorter.recoverable(id: "CostumeList")
    @State var costumes: [PreviewCostume]?
    @State var isFilterSettingsPresented = false
    @State var isSearchPresented = false
    @State var searchInput = ""
    @State var searchedCostumes: [PreviewCostume]?
    @State var availability = true
    var body: some View {
        List {
            if let costumes = searchedCostumes ?? costumes {
                ForEach(costumes) { costume in
                    NavigationLink(destination: { CostumeLive2DViewer(id: costume.id).ignoresSafeArea() }) {
                        ThumbCostumeCardView(costume)
                    }
                }
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入服装时出错", systemImage: "tshirt.fill", retryHandler: getCostumes)
                }
            }
        }
        .navigationTitle("服装")
        .sheet(isPresented: $isFilterSettingsPresented) {
            Task {
                costumes = nil
                await getCostumes()
            }
        } content: {
            FilterView(filter: $filter, sorter: $sorter, includingKeys: [
                .band,
                .character,
                .server,
                .released,
            ], includingKeywords: [
                .releaseDate(in: .jp),
                .releaseDate(in: .en),
                .releaseDate(in: .tw),
                .releaseDate(in: .cn),
                .releaseDate(in: .kr),
                .id
            ]) {
                if let costumes {
                    SearchView(items: costumes, text: $searchInput) { result in
                        searchedCostumes = result
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
            await getCostumes()
        }
    }
    
    func getCostumes() async {
        availability = true
        withDoriCache(id: "CostumeList_\(filter.identity)_\(sorter.identity)") {
            await PreviewCostume.all()?
                .filter(withDoriFilter: filter)
                .sorted(withDoriSorter: sorter)
        }.onUpdate {
            if let costumes = $0 {
                self.costumes = costumes
            } else {
                availability = false
            }
        }
    }
}

struct CostumeLive2DViewer: _UIViewRepresentable {
    var id: Int
    func makeUIView(context: Context) -> some NSObject {
        DoriFrontend.Costumes.live2dViewer(for: id)
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}
