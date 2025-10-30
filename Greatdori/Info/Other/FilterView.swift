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

let flowLayoutDefaultVerticalSpacing: CGFloat = 3
let flowLayoutDefaultHorizontalSpacing: CGFloat = 3
let capsuleDefaultCornerRadius: CGFloat = isMACOS ? 6 : 10

struct FilterView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Binding var filter: _DoriFrontend.Filter
    var includingKeys: Set<_DoriFrontend.Filter.Key>
    
    @State var lastSelectAllActionIsDeselect: Bool = false
    @State var theItemThatShowsSelectAllTips: _DoriFrontend.Filter.Key? = nil
    
    let filterKeysOrder: [_DoriFrontend.Filter.Key] = [.band, .attribute, .rarity, .character, .server, .timelineStatus, .songAvailability, .released, .cardType, .eventType, .gachaType, .songType, .loginCampaignType, .comicType, .skill, .level]
    
    var body: some View {
        Form {
            Section(content: {
                // Some keys should be displayed indirectly, hence we don't traverse `includingKeys`.
                ForEach(filterKeysOrder, id: \.self) { key in
                    if includingKeys.contains(key) {
                        FilterItemView(filter: $filter, allKeys: includingKeys, key: key)
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
                    filter.clearAll()
                }, label: {
                    Text("Filter.clear-all")
                })
                .disabled(!filter.isFiltered)
            }
        }
        .geometryGroup()
    }
}


struct FilterItemView: View {
    @Binding var filter: _DoriFrontend.Filter
    let allKeys: Set<_DoriFrontend.Filter.Key>
    let key: _DoriFrontend.Filter.Key
    
    @State var isHovering = false
    @State var characterRequiresMatchAll = false
    @State var skill: _DoriFrontend.Filter.Skill? = nil
    @State var levelSliderIsEnabled = false
    @State var level: Double = 5
    var body: some View {
            VStack(alignment: .leading) {
                if key.selector.type == .multiple {
                    //MARK: Title Part
                    HStack {
                        VStack {
                            Text(key.localizedString)
                                .bold()
                        }
                        if key == .character && allKeys.contains(.characterRequiresMatchAll) {
                            Menu(content: {
                                Picker(selection: $characterRequiresMatchAll, content: {
                                    Text("Filter.match-all.any-selected")
                                        .tag(false)
                                    Text("Filter.match-all.all-selected")
                                        .tag(true)
                                }, label: {
                                    Text("")
                                })
                                .pickerStyle(.inline)
                                .labelsHidden()
                                .multilineTextAlignment(.leading)
                            }, label: {
                                ViewThatFits {
                                    Text(getAttributedStringForMatchAll(isAllSelected: characterRequiresMatchAll))
                                    Text(getAttributedStringForMatchAll(isAllSelected: characterRequiresMatchAll, isCompact: true))
                                }
                            })
                            .menuIndicator(.hidden)
                            .menuStyle(.borderlessButton)
                            .buttonStyle(.plain)
                            .onChange(of: characterRequiresMatchAll, {
                                filter.characterRequiresMatchAll = characterRequiresMatchAll
                            })
                        }
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.05)) {
                                let allCases = key.selector.items.map { $0.item.value }
                                if let filterSet = filter[key] as? Set<AnyHashable> {
                                    if filterSet.count == 0 {
                                        filter[key] = Set(allCases)
                                        if key == .band && allKeys.contains(.bandMatchesOthers) {
                                            filter.bandMatchesOthers = .includeOthers
                                        }
                                    } else {
                                        if var filterSet = filter[key] as? Set<AnyHashable> {
                                            filterSet.removeAll()
                                            filter[key] = filterSet
                                            if key == .band && allKeys.contains(.bandMatchesOthers) {
                                                filter.bandMatchesOthers = .excludeOthers
                                            }
                                        }
                                    }
                                }
                            }
                        }, label: {
                            Group {
                                let allCases = key.selector.items.map { $0.item.value }
                                if let filterSet = filter[key] as? Set<AnyHashable> {
                                    if key == .band && allKeys.contains(.bandMatchesOthers) {
                                        CompactToggle(isLit: (filterSet.count == allCases.count && filter.bandMatchesOthers == .includeOthers) ? true : (filterSet.count == 0 && filter.bandMatchesOthers == .excludeOthers ? false : nil))
                                    } else {
                                        CompactToggle(isLit: (filterSet.count == allCases.count) ? true : (filterSet.count == 0 ? false : nil))
                                    }
                                }
                            }
                            .foregroundStyle(.secondary)
                        })
                        .buttonStyle(.plain)
                    }
                    
                    //MARK: Picker Part
                    // Multiple Selection
                    if key.selector.items.first?.imageURL != nil && key != .server {
                        // `.server` is not expected to use flags in Greatdori!.
                        //MARK: Image Selection
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: filterItemHeight))]/*, spacing: 3*/) {
                            ForEach((key == .band && allKeys.contains(.bandMatchesOthers)) ? key.selector.items + [_DoriFrontend.Filter.Key.bandMatchesOthers.selector.items.first!] : key.selector.items, id: \.self) { item in
                                Group {
                                    if item != _DoriFrontend.Filter.Key.bandMatchesOthers.selector.items.first! {
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.05)) {
                                                if var filterSet = filter[key] as? Set<AnyHashable> {
                                                    if filterSet.contains(item.item.value) {
                                                        filterSet.remove(item.item.value)
                                                    } else {
                                                        filterSet.insert(item.item.value)
                                                    }
                                                    filter[key] = filterSet
                                                }
                                            }
                                        }, label: {
                                            ZStack {
                                                Circle()
                                                    .stroke(Color.accent, lineWidth: 2)
                                                    .frame(width: filterItemHeight, height: filterItemHeight)
                                                    .opacity(((filter[key] as? Set<AnyHashable>)?.contains(item.item.value) == true) ? 1 : 0)
                                                WebImage(url: item.imageURL)
                                                    .antialiased(true)
                                                    .resizable()
                                                    .frame(width: filterItemHeight, height: filterItemHeight)
                                                    .scaleEffect([_DoriFrontend.Filter.Key.attribute, _DoriFrontend.Filter.Key.character].contains(key) ? 0.9 : 0.75)
                                            }
                                            .contentShape(Circle())
                                        })
                                    } else {
                                        Button(action: {
                                            withAnimation(.easeInOut(duration: 0.05)) {
                                                if filter.bandMatchesOthers == .includeOthers {
                                                    filter.bandMatchesOthers = .excludeOthers
                                                } else {
                                                    filter.bandMatchesOthers = .includeOthers
                                                }
                                            }
                                        }, label: {
                                            ZStack {
                                                Circle()
                                                    .stroke(Color.accent, lineWidth: 2)
                                                    .frame(width: filterItemHeight, height: filterItemHeight)
                                                    .opacity(filter.bandMatchesOthers == .includeOthers ? 1 : 0)
                                                if item.imageURL != nil {
                                                    WebImage(url: item.imageURL)
                                                        .antialiased(true)
                                                        .resizable()
                                                        .frame(width: filterItemHeight, height: filterItemHeight)
                                                        .scaleEffect([_DoriFrontend.Filter.Key.attribute, _DoriFrontend.Filter.Key.character].contains(key) ? 0.9 : 0.75)
                                                } else {
                                                    Image(systemName: "person.fill")
                                                        .frame(width: filterItemHeight*0.95, height: filterItemHeight*0.95)
                                                }
                                            }
                                            .contentShape(Circle())
                                        })
                                    }
                                }
                                .buttonStyle(.plain)
                                .accessibilityValue(Text(item.text))
                            }
                        }
                    } else {
                        //MARK: Text Selection
                        FlowLayout(items: key.selector.items, verticalSpacing: flowLayoutDefaultVerticalSpacing, horizontalSpacing: flowLayoutDefaultHorizontalSpacing) { item in
                            Button(action: {
                                //                                withAnimation(.easeInOut(duration: 0.05)) {
                                if var filterSet = filter[key] as? Set<AnyHashable> {
                                    if filterSet.contains(item.item.value) {
                                        filterSet.remove(item.item.value)
                                    } else {
                                        filterSet.insert(item.item.value)
                                    }
                                    filter[key] = filterSet
                                }
                                //                                }
                            }, label: {
                                FilterSelectionCapsuleView(isActive: ((filter[key] as? Set<AnyHashable>)?.contains(item.item.value) == true), content: {
                                    Text(item.text)
                                })
                                //                                .animation(.easeInOut(duration: 0.05))
                            })
                            .buttonStyle(.plain)
                        }
                    }
                } else {
                    //MARK: Single Selection
                    if key == .skill {
//                        #if os(macOS)
                        Group {
                            if #available(iOS 18.0, macOS 15.0, *) {
                                #if os(iOS)
                                VStack(alignment: .leading) {
                                    Text(key.localizedString)
                                        .bold()
//                                        .offset(y: 5)
                                    Picker(selection: $skill, content: {
                                        // Optional "Any" to clear the filter
                                        Text("Filter.skill.any")
                                            .tag(Optional<_DoriFrontend.Filter.Skill>.none)
                                        
                                        ForEach(key.selector.items, id: \.self) { item in
                                            if let value = item.item.value as? _DoriFrontend.Filter.Skill {
                                                // Use the skill's simpleDescription (localized) instead of selectorText
                                                //                                    let label = value.simpleDescription.forPreferredLocale() ?? ""
                                                //                                    let label = value.description.forPreferredLocale() ?? ""
                                                Text(item.text)
                                                    .tag(Optional(value))
                                            }
                                        }
                                    }, label: {
                                        Text(key.localizedString)
                                            .bold()
                                    }, currentValueLabel: {
                                        HStack {
                                            Text(skill?.selectorText ?? String(localized: "Filter.skill.any"))
                                            Spacer()
//                                                .multilineTextAlignment(.trailing)
                                        }
                                    })
                                    .labelsHidden()
                                    .padding(.vertical, -4)
                                    .padding(.leading, -5)
//                                    .border(.red)
                                    .offset(y: -5)
                                }
                                #else
                                Picker(selection: $skill, content: {
                                    // Optional "Any" to clear the filter
                                    Text("Filter.skill.any")
                                        .tag(Optional<_DoriFrontend.Filter.Skill>.none)
                                    
                                    ForEach(key.selector.items, id: \.self) { item in
                                        if let value = item.item.value as? _DoriFrontend.Filter.Skill {
                                            // Use the skill's simpleDescription (localized) instead of selectorText
                                            //                                    let label = value.simpleDescription.forPreferredLocale() ?? ""
                                            //                                    let label = value.description.forPreferredLocale() ?? ""
                                            Text(item.text)
                                                .tag(Optional(value))
                                        }
                                    }
                                }, label: {
                                    Text(key.localizedString)
                                        .bold()
                                        .lineLimit(nil)
                                })
                                #endif
                            } else {
                                Picker(selection: $skill, content: {
                                    // Optional "Any" to clear the filter
                                    Text("Filter.skill.any")
                                        .tag(Optional<_DoriFrontend.Filter.Skill>.none)
                                    
                                    ForEach(key.selector.items, id: \.self) { item in
                                        if let value = item.item.value as? _DoriFrontend.Filter.Skill {
                                            // Use the skill's simpleDescription (localized) instead of selectorText
                                            //                                    let label = value.simpleDescription.forPreferredLocale() ?? ""
                                            //                                    let label = value.description.forPreferredLocale() ?? ""
                                            Text(item.text)
                                                .tag(Optional(value))
                                        }
                                    }
                                }, label: {
                                    Text(key.localizedString)
                                        .bold()
                                        .lineLimit(nil)
                                })
                            }
                        }
                        .pickerStyle(.menu)
                        .onChange(of: skill) { _, newValue in
                            filter.skill = newValue
                        }
                    } else if key == .level {
                        VStack {
                            Toggle(isOn: $levelSliderIsEnabled, label: {
                                HStack {
                                    Text(key.localizedString)
                                        .bold()
                                    Spacer()
                                    if levelSliderIsEnabled {
                                        Text("\(Int(level))")
//                                            .contentTransition(.numericText())
//                                            .animation(.default, value: level)
                                        Stepper("", value: $level, in: 5...35, step: 1, onEditingChanged: { value in
                                            filter.level = Int(level)
                                        })
                                        .labelsHidden()
                                    }
                                    
                                }
                            })
                            .toggleStyle(.switch)
                            .tint(Color.accent)
//                            .foregroundStyle(Color.tint)
                            if levelSliderIsEnabled {
                                Slider(value: $level, in: 5...35, step: 1, label: {
                                    Text("")
                                }, onEditingChanged: { value in
                                    if !value {
                                        filter.level = Int(level)
                                    }
                                })
//                                Slider(value: $level, in: 5...35, step: 1, label: {
//                                    Text("")
//                                })
//                                .onSubmit {
//                                    print("SUBMITTED!")
//                                    filter.level = Int(level)
//                                }
                                .labelsHidden()
                                .disabled(!levelSliderIsEnabled)
                            }
                        }
//                        .onChange(of: level) { _, newValue in
//                            filter.level = Int(newValue)
//                        }
                        .onChange(of: levelSliderIsEnabled) { _, isEnabledNow in
                            if isEnabledNow {
                                filter.level = Int(level)
                            } else {
                                filter.level = nil
                            }
                        }
                    }
                }
            }
            .onHover(perform: { isHovered in
                isHovering = isHovered
            })
            .onAppear {
                skill = filter.skill
                if let filterLevel = filter.level {
                    levelSliderIsEnabled = true
                    level = Double(filterLevel)
                } else {
                    levelSliderIsEnabled = false
                }
            }
            .onChange(of: filter.skill) {
                if skill == nil {
                    skill = filter.skill
                }
            }
            .onChange(of: filter.level) {
                if filter.level == nil {
                    levelSliderIsEnabled = false
                }
            }
    }
    struct FilterSelectionCapsuleView<Content: View>: View {
        @Environment(\.horizontalSizeClass) var sizeClass
        var isActive: Bool
        let content: Content
        let cornerRadius: CGFloat = capsuleDefaultCornerRadius
        @State var textWidth: CGFloat = 0
        
        init(isActive: Bool, @ViewBuilder content: () -> Content) {
            self.isActive = isActive
            self.content = content()
        }
        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .foregroundStyle(isActive ? Color.accent : getTertiaryLabelColor())
                    .frame(width: textWidth, height: filterItemHeight)
                content
                    .foregroundStyle(isActive ? .white : Color.gray)
                    .frame(height: filterItemHeight)
                    .padding(.horizontal, isMACOS ? 10 : nil)
                    .onFrameChange(perform: { geometry in
                        textWidth = geometry.size.width
                    })
                //FIXME: Text padding to much in macOS
            }
            .animation(.easeInOut(duration: 0.05), value: isActive)
        }
    }
    func getAttributedStringForMatchAll(isAllSelected: Bool = false, isCompact: Bool = false) -> AttributedString {
        var attrString = AttributedString()
        if isCompact {
            attrString = AttributedString(String(localized: isAllSelected ? "Filter.match-all.all-selected.abbr" : "Filter.match-all.any-selected.abbr"))
        } else {
            attrString = AttributedString(String(localized: isAllSelected ? "Filter.match-all.all-selected" : "Filter.match-all.any-selected"))
        }
        attrString.font = .system(.body, weight: .thin)
        attrString.foregroundColor = .secondary
        return attrString
    }
}



// You may ask why this View looks so weird and has so many warnings.
// It becuase it's generated by ChatGPT and it suprisingly works.
// (P.S. It's super weird that I wanted to add a comment every time I see this.)
// --@ThreeManager785
struct FlowLayout<Data: RandomAccessCollection, Content: View>: View
where Data.Element: Hashable {
    let items: Data
    let verticalSpacing: CGFloat
    let horizontalSpacing: CGFloat
    let content: (Data.Element) -> Content
    
    @State private var totalHeight = CGFloat.zero
    
    var body: some View {
        GeometryReader { geo in
            self.generateContent(in: geo)
        }
        .frame(height: totalHeight)
    }
    
    private func generateContent(in geo: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero
        
        return ZStack(alignment: .topLeading) {
            ForEach(Array(items), id: \.self) { item in
                content(item)
                    .padding(.vertical, verticalSpacing)
                    .padding(.horizontal, horizontalSpacing)
                    .alignmentGuide(.leading) { d in
                        if (abs(width - d.width) > geo.size.width) {
                            width = 0
                            height -= d.height
                        }
                        let result = width
                        if item == items.last {
                            width = 0 // reset
                        } else {
                            width -= d.width
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if item == items.last {
                            height = 0 // reset
                        }
                        return result
                    }
            }
        }
        .background(
            GeometryReader { geo -> Color in
                DispatchQueue.main.async {
                    self.totalHeight = geo.size.height
                }
                return Color.clear
            }
        )
        //        .offset(x: -horizontalSpacing)wo x
    }
}

struct SorterPickerView: View {
    @Binding var sorter: _DoriFrontend.Sorter
    var allOptions: [_DoriFrontend.Sorter.Keyword] = _DoriFrontend.Sorter.Keyword.allCases
    var sortingItemsHaveEndingDate = false
    @State var isMenuPresented = false // iOS only
    var body: some View {
        Menu(content: {
            Section {
                ForEach(_DoriFrontend.Sorter.Keyword.allCases, id: \.self) { item in
                    if allOptions.contains(item) {
                        Button(action: {
                            if sorter.keyword == item && !isMACOS {
                                sorter.direction.reverse()
                            } else {
                                sorter.keyword = item
                            }
                        }, label: {
                            Label(title: {
                                Text(item.localizedString(hasEndingDate: sortingItemsHaveEndingDate))
                            }, icon: {
                                if sorter.keyword == item {
                                    if isMACOS {
                                        Image(systemName: "checkmark")
                                    } else {
                                        Image(systemName: sorter.direction == .ascending ? "chevron.up" : "chevron.down")
                                    }
                                }
                            })
                        })
                    }
                }
            }
            #if os(macOS)
            Section {
                Button(action: {
                    sorter.direction = .ascending
                }, label: {
                    Label(title: {
                        Text(sorter.localizedDirectionName(direction: .ascending))
                    }, icon: {
                        if sorter.direction == .ascending {
                            Image(systemName: "checkmark")
                        }
                    })
                })
                Button(action: {
                    sorter.direction = .descending
                }, label: {
                    Label(title: {
                        Text(sorter.localizedDirectionName(direction: .descending))
                    }, icon: {
                        if sorter.direction == .descending {
                            Image(systemName: "checkmark")
                        }
                    })
                })

            }
            #endif
        }, label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        })
        .menuIndicator(.hidden)
    }
}
