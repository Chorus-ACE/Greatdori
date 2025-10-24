//===---*- Greatdori! -*---------------------------------------------------===//
//
// FilterView.swift
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

import OSLog
import SwiftUI
import DoriKit
import SDWebImageSwiftUI

struct FilterView: View {
    @Binding private var filter: DoriFilter
    @Binding private var sorter: DoriSorter
    private var includingKeys: Set<DoriFilter.Key>
    private var includingKeywords: Set<DoriSorter.Keyword>
    private var searchView: AnyView?
    
    init(
        filter: Binding<DoriFilter>,
        sorter: Binding<DoriSorter> = .constant(.init()),
        includingKeys: Set<DoriFilter.Key>,
        includingKeywords: Set<DoriSorter.Keyword> = []
    ) {
        self._filter = filter
        self._sorter = sorter
        self.includingKeys = includingKeys
        self.includingKeywords = includingKeywords
    }
    init<V: View>(
        filter: Binding<DoriFilter>,
        sorter: Binding<DoriSorter> = .constant(.init()),
        includingKeys: Set<DoriFilter.Key>,
        includingKeywords: Set<DoriSorter.Keyword> = [],
        @ViewBuilder searchView: () -> V
    ) {
        self._filter = filter
        self._sorter = sorter
        self.includingKeys = includingKeys
        self.includingKeywords = includingKeywords
        self.searchView = AnyView(searchView())
    }
    
    @Environment(\.dismiss) private var dismiss
    @State private var isSearchPresented = false
    
    var body: some View {
        NavigationStack {
            List {
                if filter.isFiltered {
                    Button("清除过滤", systemImage: "arrow.counterclockwise") {
                        filter.clearAll()
                    }
                }
                Section {
                    let sortedKeys = includingKeys.sorted()
                    ForEach(sortedKeys) { key in
                        if key != .characterRequiresMatchAll {
                            switch key.selector.type {
                            case .single:
                                SingleSelector(filter: $filter, key: key)
                            case .multiple:
                                MultipleSelector(
                                    filter: $filter,
                                    key: key,
                                    containsCharacterMatchAll: includingKeys.contains(.characterRequiresMatchAll)
                                )
                            }
                        }
                    }
                    if !includingKeywords.isEmpty {
                        SorterSelector(sorter: $sorter, keywords: includingKeywords.sorted())
                    }
                }
            }
            .animation(.default, value: filter.isFiltered)
            .navigationTitle("过滤")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $isSearchPresented) {
                dismiss()
            } content: {
                if let searchView {
                    searchView
                }
            }
            .toolbar {
                if searchView != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: {
                            isSearchPresented = true
                        }, label: {
                            Image(systemName: "magnifyingglass")
                        })
                    }
                }
            }
        }
    }
    
    private struct SingleSelector: View {
        @Binding var filter: DoriFilter
        var key: DoriFilter.Key
        var body: some View {
            NavigationLink {
                List {
                    if key == .skill {
                        Button(action: {
                            filter[key] = nil as Optional<DoriFilter.Skill>
                        }, label: {
                            HStack {
                                Text("任意")
                                Spacer()
                                if (filter[key].base as! Optional<DoriFilter.Skill>) == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accent)
                                }
                            }
                        })
                    }
                    ForEach(key.selector.items, id: \.self) { item in
                        Button(action: {
                            filter[key] = item.item.value
                        }, label: {
                            HStack {
                                Text(item.text)
                                Spacer() 
                                if (filter[key].base as! any DoriFilter._Selectable).isEqual(to: item.item.value.base as! any DoriFilter._Selectable) {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accent)
                                }
                            }
                        })
                    }
                }
                .navigationTitle(key.localizedString)
            } label: {
                VStack(alignment: .leading) {
                    Text(key.localizedString)
                    if let filterItem = filter[key] as? any DoriFilter._Selectable {
                        Text(filterItem.selectorText)
                            .font(.system(size: 14))
                            .lineLimit(1)
                            .opacity(0.6)
                    }
                }
            }
        }
    }
    private struct MultipleSelector: View {
        @Binding var filter: DoriFilter
        var key: DoriFilter.Key
        var containsCharacterMatchAll: Bool = false
        var body: some View {
            NavigationLink {
                List {
                    if key == .character && containsCharacterMatchAll {
                        Button(action: {
                            filter.characterRequiresMatchAll.toggle()
                        }, label: {
                            HStack {
                                Text(false.selectorText)
                                    .foregroundColor(filter.characterRequiresMatchAll ? .secondary : .primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                                Spacer(minLength: 0)
                                Text(verbatim: "|").fontDesign(.rounded)
                                Spacer(minLength: 0)
                                Text(true.selectorText)
                                    .foregroundColor(filter.characterRequiresMatchAll ? .primary : .secondary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                        })
                    }
                    ForEach(key.selector.items, id: \.self) { item in
                        Button(action: {
                            if var filterSet = filter[key] as? Set<AnyHashable> {
                                if filterSet.contains(item.item.value) {
                                    filterSet.remove(item.item.value)
                                } else {
                                    filterSet.insert(item.item.value)
                                }
                                filter[key] = filterSet
                            } else {
                                os_log(.fault, "\(type(of: filter[key])) is not Set")
                            }
                        }, label: {
                            HStack {
                                if key != .server, let imageURL = item.imageURL {
                                    WebImage(url: imageURL)
                                        .resizable()
                                        .frame(width: 25, height: 25)
                                }
                                Text(item.text)
                                Spacer()
                                if let filterSet = filter[key] as? Set<AnyHashable> {
                                    Image(systemName: filterSet.contains(item.item.value) ? "checkmark.circle.fill" : "circle")
                                        .foregroundStyle(.accent)
                                } else {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.yellow)
                                }
                            }
                        })
                    }
                }
                .navigationTitle(key.localizedString)
                .toolbar {
                    if let filterSet = filter[key] as? Set<AnyHashable> {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                if filterSet == Set(key.selector.items.map { $0.item.value }) {
                                    // Currently selected all, we unselect all
                                    var filterSet = filterSet
                                    filterSet.removeAll()
                                    filter[key] = filterSet
                                } else {
                                    filter[key] = Set(key.selector.items.map { $0.item.value })
                                }
                            }, label: {
                                Image(systemName: filterSet == Set(key.selector.items.map { $0.item.value }) ? "checklist.checked" : (filterSet.isEmpty ? "checklist.unchecked" : "checklist"))
                            })
                        }
                    }
                }
            } label: {
                VStack(alignment: .leading) {
                    Text(key.localizedString)
                    if let filterSet = filter[key] as? Set<AnyHashable> {
                        Text(filterSet.map { ($0 as! (any DoriFilter._Selectable)).selectorText }.sorted().joined(separator: ", "))
                            .font(.system(size: 14))
                            .lineLimit(1)
                            .opacity(0.6)
                    }
                }
            }
        }
    }
    private struct SorterSelector: View {
        @Binding var sorter: DoriSorter
        var keywords: [DoriSorter.Keyword]
        var body: some View {
            NavigationLink {
                List {
                    Section {
                        ForEach(keywords, id: \.rawValue) { keyword in
                            Button(action: {
                                if sorter.keyword != keyword {
                                    sorter.keyword = keyword
                                } else {
                                    sorter.direction = sorter.direction == .ascending ? .descending : .ascending
                                }
                            }, label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(keyword.localizedString)
                                        if sorter.keyword == keyword {
                                            Text(sorter.localizedDirectionName())
                                                .font(.system(size: 14))
                                                .opacity(0.6)
                                        }
                                    }
                                    Spacer()
                                    if sorter.keyword == keyword {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.accent)
                                    }
                                }
                            })
                        }
                    }
                }
            } label: {
                VStack(alignment: .leading) {
                    Text("排序")
                    Text(verbatim: "\(sorter.keyword.localizedString), \(sorter.localizedDirectionName())")
                        .font(.system(size: 14))
                        .opacity(0.6)
                }
            }
        }
    }
}
