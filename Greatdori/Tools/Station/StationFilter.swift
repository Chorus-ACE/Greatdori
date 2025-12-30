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

import DoriKit
import SDWebImageSwiftUI
import SwiftUI

#if os(iOS)
import UIKit
#endif

struct StationFilter: Hashable, Sendable {
    var roomTypes: Set<DoriAPI.Station.RoomType> = Set(DoriAPI.Station.RoomType.allCases)
    var disallowedKeywords: [String] = []
    var disallowedUsers: [DisallowedUser] = []
    
    struct DisallowedUser: Hashable, Sendable {
        var id: Int
        var name: String
    }
    
    var isFiltering: Bool {
        return roomTypes != Set(DoriAPI.Station.RoomType.allCases) || !roomTypes.isEmpty || !disallowedUsers.isEmpty
    }
}


struct StationFilterView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Binding var filter: StationFilter
    
    @State var lastSelectAllActionIsDeselect: Bool = false
    @State var theItemThatShowsSelectAllTips: DoriFrontend.Filter.Key? = nil
    
    @State var keywordNewItem = ""
    var body: some View {
        Form {
            Section(content: {
                VStack {
                    HStack {
                        VStack {
                            Text("Station.filter.type")
                                .bold()
                                .accessibilityHeading(.h2)
                        }
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.05)) {
                                if filter.roomTypes.isEmpty {
                                    filter.roomTypes = Set(DoriAPI.Station.RoomType.allCases)
                                } else {
                                    filter.roomTypes = Set([])
                                }
                            }
                        }, label: {
                            Group {
                                let selectionStatus = (filter.roomTypes.count == DoriAPI.Station.RoomType.allCases.count) ? true : (filter.roomTypes.count == 0 ? false : nil)
                                CompactToggle(isLit: selectionStatus)
                                    .accessibilityValue({
                                        if selectionStatus == true {
                                            return "Accessibility.filter.selections-toggle.value.all-selected"
                                        } else if selectionStatus == false {
                                            return "Accessibility.filter.selections-toggle.value.none-selected"
                                        } else {
                                            return "Accessibility.filter.selections-toggle.value.partially-selected"
                                        }
                                    }())
                                    .accessibilityHint({
                                        if selectionStatus == false {
                                            return "Accessibility.filter.selections-toggle.hint.select-all"
                                        } else {
                                            return "Accessibility.filter.selections-toggle.hint.deselect-all"
                                        }
                                    }())
                            }
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Accessibility.filter.selections-toggle")
                        })
                        .buttonStyle(.plain)
                    }

                    FlowLayout(items: DoriAPI.Station.RoomType.allCases, verticalSpacing: flowLayoutDefaultVerticalSpacing, horizontalSpacing: flowLayoutDefaultHorizontalSpacing) { item in
                        Button(action: {
                            if filter.roomTypes.contains(item) {
                                filter.roomTypes.remove(item)
                            } else {
                                filter.roomTypes.insert(item)
                            }
                        }, label: {
                            FilterItemView.FilterSelectionCapsuleView(isActive: filter.roomTypes.contains(item), content: {
                                Text(item.localizedName)
                            })
                        })
                        .buttonStyle(.plain)
                        .wrapIf(filter.roomTypes.contains(item), in: {
                            $0.accessibilityValue("Accessibility.filter.activated")
                        })
                        .accessibilityHint("Accessibility.filter.tap-to-toggle")
                    }
                }
                VStack {
                    HStack {
                        VStack {
                            Text("Station.filter.keyword")
                                .bold()
                                .accessibilityHeading(.h2)
                        }
                        Spacer()
                        Button(action: {
                            filter.disallowedKeywords.removeAll()
                        }, label: {
                            Text("Station.filter.clear")
                            .foregroundStyle(.secondary)
                        })
                        .buttonStyle(.plain)
                    }
                    
                    HStack {
                        TextField("Station.filter.keyword.prompt", text: $keywordNewItem)
                        Button(action: {
                            if !filter.disallowedKeywords.contains(keywordNewItem) {
                                filter.disallowedKeywords.append(keywordNewItem)
                            }
                        }, label: {
                            Label("Station.filter.keyword.add", systemImage: "plus")
                                .labelStyle(.iconOnly)
                        })
                        .disabled(keywordNewItem.isEmpty || filter.disallowedKeywords.contains(keywordNewItem))
                    }
                }
            }, header: {
                VStack(alignment: .leading) {
                    if sizeClass == .compact {
                        Color.clear.frame(height: 10)
                    }
                    Text("Filter")
                }
            })
            
            Section {
                Button(action: {
                    filter = .init()
                }, label: {
                    Text("Filter.clear-all")
                })
                .disabled(!filter.isFiltering)
            }
        }
    }
}
