//===---*- Greatdori! -*---------------------------------------------------===//
//
// CostumeSearchView.swift
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

// MARK: CostumeSearchView
struct CostumeSearchView: View {
    let gridLayoutItemWidth: CGFloat = 200
    var body: some View {
        SearchViewBase(forType: PreviewCostume.self, initialLayout: SummaryLayout.horizontal, layoutOptions: verticalAndHorizontalLayouts) { layout, _, content, _ in
            if layout == .horizontal {
                LazyVStack {
                    content
                }
                .frame(maxWidth: 600)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: gridLayoutItemWidth, maximum: gridLayoutItemWidth))]) {
                    content
                }
            }
        } eachContent: { layout, element in
            CostumeInfo(element, layout: layout)
        } destination: { element, list in
            CostumeDetailView(id: element.id, allCostumes: list)
        }
        .resultCountDescription { count in
            "Costume.count.\(count)"
        }
    }
}

/*
// MARK: CostumeSearchView
struct CostumeSearchView: View {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    @State var filter = DoriFrontend.Filter()
    @State var sorter = DoriFrontend.Sorter(keyword: .releaseDate(in: .jp), direction: .descending)
    @State var costumes: [DoriFrontend.Costume.PreviewCostume]?
    @State var searchedCostumes: [DoriFrontend.Costume.PreviewCostume]?
    @State var infoIsAvailable = true
    @State var searchedText = ""
    @State var layout = Axis.horizontal
    @State var showFilterSheet = false
    @State var presentingCostumeID: Int?
    @Namespace var costumeLists
    
    let gridLayoutItemWidth: CGFloat = 200*0.9
    var body: some View {
        Group {
            Group {
                if let resultCostumes = searchedCostumes ?? costumes {
                    Group {
                        if !resultCostumes.isEmpty {
                            ScrollView {
                                HStack {
                                    Spacer(minLength: 0)
                                    Group {
                                        if layout == .horizontal {
                                            LazyVStack {
                                                ForEach(resultCostumes, id: \.self) { costume in
                                                    Button(action: {
                                                        showFilterSheet = false
                                                        presentingCostumeID = costume.id
                                                    }, label: {
                                                        CostumeInfo(costume, preferHeavierFonts: true, inLocale: nil, layout: layout, searchedKeyword: $searchedText)
                                                    })
                                                    .buttonStyle(.plain)
                                                    .wrapIf(true, in: { content in
                                                        if #available(iOS 18.0, macOS 15.0, *) {
                                                            content
                                                                .matchedTransitionSource(id: costume.id, in: costumeLists)
                                                        } else {
                                                            content
                                                        }
                                                    })
                                                }
                                            }
                                            .frame(maxWidth: 600)
                                        } else {
                                            LazyVGrid(columns: [GridItem(.adaptive(minimum: gridLayoutItemWidth, maximum: gridLayoutItemWidth))]) {
                                                ForEach(resultCostumes, id: \.self) { costume in
                                                    Button(action: {
                                                        showFilterSheet = false
                                                        presentingCostumeID = costume.id
                                                    }, label: {
                                                        CostumeInfo(costume, preferHeavierFonts: true, inLocale: nil, layout: layout, searchedKeyword: $searchedText)
                                                    })
                                                    .buttonStyle(.plain)
                                                    .wrapIf(true, in: { content in
                                                        if #available(iOS 18.0, macOS 15.0, *) {
                                                            content
                                                                .matchedTransitionSource(id: costume.id, in: costumeLists)
                                                        } else {
                                                            content
                                                        }
                                                    })
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                    Spacer(minLength: 0)
                                }
                            }
                            .geometryGroup()
                            .navigationDestination(item: $presentingCostumeID) { id in
                                CostumeDetailView(id: id, allCostumes: costumes)
#if !os(macOS)
                                    .wrapIf(true, in: { content in
                                        if #available(iOS 18.0, macOS 15.0, *) {
                                            content
                                                .navigationTransition(.zoom(sourceID: id, in: costumeLists))
                                        } else {
                                            content
                                        }
                                    })
#endif
                            }
                        } else {
                            ContentUnavailableView("Search.no-results", systemImage: "magnifyingglass", description: Text("Search.no-results.description"))
                        }
                    }
                    .onSubmit {
                        if let costumes {
                            searchedCostumes = costumes.search(for: searchedText)
                        }
                    }
                } else {
                    if infoIsAvailable {
                        ExtendedConstraints {
                            ProgressView()
                        }
                    } else {
                        ExtendedConstraints {
                            ContentUnavailableView("Costume.search.unavailable", systemImage: "line.horizontal.star.fill.line.horizontal", description: Text("Search.unavailable.description"))
                                .onTapGesture {
                                    Task {
                                        await getCostumes()
                                    }
                                }
                        }
                    }
                }
            }
            .searchable(text: $searchedText, prompt: "Costume.search.placeholder")
            .navigationTitle("Costume")
            .wrapIf(searchedCostumes != nil, in: { content in
                if #available(iOS 26.0, *) {
                    content.navigationSubtitle((searchedText.isEmpty && !filter.isFiltered) ? "Costume.count.\(searchedCostumes!.count)" :  "Search.result.\(searchedCostumes!.count)")
                } else {
                    content
                }
            })
            .toolbar {
                ToolbarItem {
                    LayoutPicker(selection: $layout, options: [("Filter.view.list", "list.bullet", Axis.horizontal), ("Filter.view.grid", "square.grid.2x2", Axis.vertical)])
                }
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer()
                }
                ToolbarItemGroup {
                    FilterAndSorterPicker(showFilterSheet: $showFilterSheet, sorter: $sorter, filterIsFiltering: filter.isFiltered, sorterKeywords: PreviewCostume.applicableSortingTypes, hasEndingDate: false)
                }
            }
            .onDisappear {
                showFilterSheet = false
            }
        }
        .withSystemBackground()
        .inspector(isPresented: $showFilterSheet) {
            FilterView(filter: $filter, includingKeys: Set(PreviewCostume.applicableFilteringKeys))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
        }
        .withSystemBackground() // This modifier MUST be placed BOTH before
                                // and after `inspector` to make it work as expected
        .task {
            await getCostumes()
        }
        .onChange(of: filter) {
            if let costumes {
                searchedCostumes = costumes.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: sorter) {
            if let costumes {
                searchedCostumes = costumes.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: searchedText, {
            if let costumes {
                searchedCostumes = costumes.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        })
    }
    
    func getCostumes() async {
        infoIsAvailable = true
        withDoriCache(id: "CostumeList_\(filter.identity)", trait: .realTime) {
            await PreviewCostume.all()
        } .onUpdate {
            if let costumes = $0 {
                self.costumes = costumes.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending))
                searchedCostumes = costumes.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            } else {
                infoIsAvailable = false
            }
        }
    }
}
*/
