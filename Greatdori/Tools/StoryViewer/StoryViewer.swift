//===---*- Greatdori! -*---------------------------------------------------===//
//
// StoryViewer.swift
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

import AVKit
import DoriKit
import SwiftUI
import SDWebImageSwiftUI

struct StoryViewerView: View {
    @State var storyType = StoryType.event
    @State var displayingStories: LocalizedData<[CustomStory]> = LocalizedData<[CustomStory]>(repeating: [])
    @State var informationIsAvailable = true
    @State var locale: DoriLocale = DoriLocale.primaryLocale
    @State var sectionTitle: String = "" // Deprecated?
    
    @State var allEventStories: [_DoriAPI.Events.EventStory] = []
    @State var allMainStories: [_DoriAPI.Story] = []
    @State var allBandStories: [_DoriAPI.Misc.BandStory] = []
    @State var allMainBands: [Band] = DoriCache.preCache.mainBands
    @State var allActionSets: [_DoriAPI.Misc.ActionSet] = []
    @State var allConversationAreas: [_DoriAPI.Misc.Area] = []
    @State var allAfterLiveTalks: [_DoriAPI.Misc.AfterLiveTalk] = []
    
    @State var selectedEvent: PreviewEvent?
    @State var selectedBandStory: _DoriAPI.Misc.BandStory?
    @State var selectedBand: Band? = DoriCache.preCache.mainBands.first
    @State var selectedCard: PreviewCard?
    
    @State var conversationFilter = DoriFilter()
    @State var conversationArea: _DoriAPI.Misc.Area? = nil
    @State var conversationType: _DoriAPI.Misc.ActionSet.ActionSetType? = nil
    
    @State var afterLiveFilter = DoriFilter(characterMatchesOthers: .excludeOthers)
    
    var body: some View {
        ScrollView {
            HStack {
                Spacer(minLength: 0)
                LazyVStack {
                    CustomGroupBox(cornerRadius: 20) {
                        VStack {
                            Group {
                                ListItem(title: {
                                    Text("Story-viewer.type")
                                        .bold()
                                }, value: {
                                    Picker(selection: $storyType) {
                                        ForEach(StoryType.allCases, id: \.self) { type in
                                            Text(type.name).tag(type)
                                        }
                                    } label: {
                                        EmptyView()
                                    }
                                    .labelsHidden()
                                })
                                
                                switch storyType {
                                case .event:
                                    ListItem(title: {
                                        Text("Story-viewer.event")
                                            .bold()
                                    }, value: {
                                        ItemSelectorButton(selection: $selectedEvent)
                                    })
                                case .main:
                                    EmptyView()
                                case .band:
                                    ListItem(title: {
                                        Text("Story-viewer.band")
                                            .bold()
                                    }, value: {
                                        Picker(selection: $selectedBand, content: {
                                            ForEach(allMainBands, id: \.self) { item in
                                                Text(item.bandName.forLocale(locale) ?? "")
                                                    .tag(item)
                                            }
                                        }, label: {
                                            EmptyView()
                                        })
                                        .labelsHidden()
                                    })
                                    ListItem(title: {
                                        Text("Story-viewer.story")
                                            .bold()
                                    }, value: {
                                        Picker(selection: $selectedBandStory) {
                                            ForEach(allBandStories.filter({ $0.bandID == selectedBand?.id }).sorted { $0.chapterNumber < $1.chapterNumber }, id: \.self) { item in
                                                Text(verbatim: "\(item.mainTitle.forLocale(locale) ?? "")\(getLocalizedColon(forLocale: locale))\(item.subTitle.forLocale(locale) ?? "")")
                                                    .tag(item)
                                            }
                                        } label: {
                                            EmptyView()
                                        } optionalCurrentValueLabel: {
                                            if let item = selectedBandStory {
                                                Text(verbatim: "\(item.mainTitle.forLocale(locale) ?? "")\(getLocalizedColon(forLocale: locale))\(item.subTitle.forLocale(locale) ?? "")")
                                            } else {
                                                Text("Story-viewer.story.select")
                                            }
                                        }
                                        .labelsHidden()
                                        .id(allBandStories)
                                    })
                                case .card:
                                    ListItem(title: {
                                        Text("Story-viewer.card")
                                            .bold()
                                    }, value: {
                                        ItemSelectorButton(selection: $selectedCard)
                                    })
                                case .actionSet:
                                    ListItem(title: {
                                        Text("Story-viewer.character")
                                            .bold()
                                    }, value: {
                                        MultiCharacterSelectorButton(filter: $conversationFilter, characterMatchesOthers: true)
                                    })
                                    ListItem(title: {
                                        Text("Story-viewer.area")
                                            .bold()
                                    }, value: {
                                        Picker(selection: $conversationArea, content: {
                                            ForEach([nil] + allConversationAreas, id: \.self) { item in
                                                Text(verbatim: item?.areaName.forLocale(locale) ?? String(localized: "Story-viewer.area.any"))
                                                    .tag(item)
                                            }
                                        }, label: {
                                            EmptyView()
                                        })
                                        .labelsHidden()
                                        .id(conversationArea)
                                    })
                                    ListItem(title: {
                                        Text("Story-viewer.type")
                                            .bold()
                                    }, value: {
                                        Picker(selection: $conversationType, content: {
                                            ForEach([nil] + (_DoriAPI.Misc.ActionSet.ActionSetType.allCases as [_DoriAPI.Misc.ActionSet.ActionSetType?]), id: \.self) { item in
                                                Text(item?.localizedString ?? String(localized: "Story-viewer.type.any"))
                                                    .tag(item)
                                            }
                                        }, label: {
                                            EmptyView()
                                        })
                                        .labelsHidden()
                                    })
                                case .afterLive:
                                    ListItem(title: {
                                        Text("Story-viewer.character")
                                            .bold()
                                    }, value: {
                                        MultiCharacterSelectorButton(filter: $afterLiveFilter)
                                    })
                                }
                                
                                ListItem(title: {
                                    Text("Story-viewer.locale")
                                        .bold()
                                }, value: {
                                    Picker(selection: $locale) {
                                        ForEach(DoriLocale.allCases, id: \.self) { item in
                                            Text(item.rawValue.uppercased()).tag(item)
                                        }
                                    } label: {
                                        EmptyView()
                                    }
                                    .labelsHidden()
                                })
                            }
                            .insert {
                                Divider()
                            }
                        }
                    }
                    DetailSectionsSpacer(height: 15)
                    
                    Section(content: {
                        if let localizedStories = displayingStories.forLocale(locale), !localizedStories.isEmpty {
                            ForEach(Array(localizedStories.enumerated()), id: \.element.self) { (index, item) in
                                switch storyType {
                                case .event:
                                    StoryCardView(story: item, type: storyType, locale: locale, unsafeAssociatedID: String(selectedEvent?.id ?? -1), unsafeSecondaryAssociatedID: String(index))
                                case .main:
                                    StoryCardView(story: item, type: storyType, locale: _DoriAPI.preferredLocale, unsafeAssociatedID: String(index + 1))
                                case .band:
                                    StoryCardView(story: item, type: storyType, locale: locale, unsafeAssociatedID: String(selectedBand?.id ?? -1))
                                case .card:
                                    StoryCardView(story: item, type: storyType, locale: locale, unsafeAssociatedID: selectedCard?.resourceSetName ?? "")
                                case .actionSet:
                                    let areaID = Int(item.note!)!
                                    StoryCardView(
                                        story: item,
                                        type: storyType,
                                        locale: locale,
                                        unsafeAssociatedID: item.scenarioID,
                                        images: [
                                            URL(string: "https://bestdori.com/assets/\(locale.rawValue)/worldmap_rip/area_icon\(unsafe String(format: "%03d", areaID)).png")!,
                                            URL(string: "https://bestdori.com/assets/\(locale.rawValue)/map/area_icon/area_icon\(unsafe String(format: "%03d", areaID))_rip/area_icon\(unsafe String(format: "%03d", areaID)).png")!
                                        ],
                                        characterIDs: item.characterIDs
                                    )
                                case .afterLive:
                                    StoryCardView(
                                        story: item,
                                        type: storyType,
                                        locale: locale,
                                        unsafeAssociatedID: item.note!
                                    )
                                }
                            }
                        } else {
                            if selectionIsMeaningful() {
                                CustomGroupBox {
                                    HStack {
                                        Spacer()
                                        if informationIsAvailable && !(displayingStories.forLocale(locale)?.isEmpty ?? true) {
                                            ProgressView()
                                        } else {
                                            Text("Story-viewer.unavailable")
                                                .bold()
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                    }
                                }
                                .onTapGesture {
                                    if !informationIsAvailable {
                                        Task {
                                            await getStories()
                                        }
                                    }
                                }
                            }
                        }
                    })
                }
                .padding()
                .frame(maxWidth: infoContentMaxWidth)
                Spacer(minLength: 0)
            }
        }
        .withSystemBackground()
        .navigationTitle("Story-viewer")
        .onAppear {
            Task {
                await getStories()
            }
        }
        .onChange(
            of: locale,
            storyType,
            selectedEvent,
            selectedBand,
            selectedBandStory,
            selectedCard,
            conversationFilter,
            conversationArea,
            conversationType,
            afterLiveFilter
        ) {
            Task {
                await getStories()
            }
        }
        .onChange(of: selectedBand) {
            selectedBandStory = nil
        }
    }
    
    func getStories() async {
        displayingStories = LocalizedData()
        informationIsAvailable = true
        switch storyType {
        case .event:
            if allEventStories.isEmpty {
                DoriCache.withCache(id: "EventStories") {
                    await _DoriAPI.Events.allStories()
                }.onUpdate {
                    if let stories = $0 {
                        self.allEventStories = stories
                    } else {
                        informationIsAvailable = false
                    }
                }
            }
            let eventStory = allEventStories.first {
                $0.id == (selectedEvent?.id ?? -1)
            }
            displayingStories = eventStory?.stories.convertToLocalizedData() ?? LocalizedData<[CustomStory]>(repeating: [])
        case .main:
            if allMainStories.isEmpty {
                DoriCache.withCache(id: "MainStories") {
                    await _DoriAPI.Misc.mainStories()
                }.onUpdate {
                    if let stories = $0 {
                        allMainStories = stories
                    } else {
                        informationIsAvailable = false
                    }
                }
            }
            displayingStories = allMainStories.convertToLocalizedData()
        case .band:
            if allBandStories.isEmpty {
                DoriCache.withCache(id: "BandStories") {
                    await _DoriAPI.Misc.bandStories()
                }.onUpdate {
                    if let bands = $0 {
                        self.allBandStories = bands
                        displayingStories = selectedBandStory?.stories.convertToLocalizedData() ?? LocalizedData<[CustomStory]>(repeating: [])
                    } else {
                        informationIsAvailable = false
                    }
                }
            }
            displayingStories = selectedBandStory?.stories.convertToLocalizedData() ?? LocalizedData<[CustomStory]>(repeating: [])
        case .card:
            if let selectedCard {
                DoriCache.withCache(id: "CardDetail_\(selectedCard.id)") {
                    await _DoriFrontend.Cards.extendedInformation(of: selectedCard.id)
                }.onUpdate {
                    if let information = $0 {
                        self.displayingStories = information!.card.episodes.map { $0.standardized() }.convertToLocalizedData()
                    } else {
                        informationIsAvailable = false
                    }
                }
            }
        case .actionSet:
            func updateActionSets() {
                self.displayingStories = LocalizedData<[CustomStory]>(repeating: allActionSets.filter({ convo in
                    (conversationArea == nil ? true : convo.areaID == conversationArea!.id) && (conversationType == nil ? true : convo.actionSetType == conversationType!)
                }).filter({ convo in
                    guard conversationFilter.character != Set(DoriFilter.Character.allCases) else { return true }
                    if conversationFilter.characterRequiresMatchAll {
                        return convo.characterIDs.allSatisfy { convoCharaID in
                            if _fastPath(DoriFilter.Character.allCases.contains(where: { $0.rawValue == convoCharaID })) {
                                conversationFilter.character.contains { character in
                                    character.rawValue == convoCharaID
                                }
                            } else {
                                conversationFilter.characterMatchesOthers == .includeOthers
                            }
                        }
                    } else {
                        return convo.characterIDs.contains { convoCharaID in
                            if _fastPath(DoriFilter.Character.allCases.contains(where: { $0.rawValue == convoCharaID })) {
                                conversationFilter.character.contains { $0.rawValue == convoCharaID }
                            } else {
                                conversationFilter.characterMatchesOthers == .includeOthers
                            }
                        }
                    }
                }).map({ convo in
                    return CustomStory(scenarioID: "\(convo.id)", caption: "#\(convo.id)", title: LocalizedData(builder: { locale in
                        guard !convo.characterIDs.isEmpty else { return String(localized: "Story-viewer.area-conversation.no-character") }
                        return convo.characterIDs
                            .map({ char in DoriCache.preCache.characters.first(where: { $0.id == char }) })
                            .map({ $0?.characterName.forLocale(locale) ?? $0?.characterName.forPreferredLocale() ?? "???" })
                            .joined(separator: "×")
                    }), synopsis: convo.actionSetType.localizedString, note: "\(convo.areaID)", characterIDs: convo.characterIDs)
                }))
            }
            
            if allActionSets.isEmpty {
                DoriCache.withCache(id: "ActionSet") {
                    await _DoriAPI.Misc.actionSets()
                } .onUpdate {
                    if let info = $0 {
                        self.allActionSets = info
                        updateActionSets()
                    } else {
                        informationIsAvailable = false
                    }
                }
            }
            if allConversationAreas.isEmpty {
                DoriCache.withCache(id: "AllAreas") {
                    await _DoriAPI.Misc.areas()
                }.onUpdate {
                    if let info = $0 {
                        allConversationAreas = info
                        updateActionSets()
                    } else {
                        informationIsAvailable = false
                    }
                }
            }
            updateActionSets()
        case .afterLive:
            func updateAfterLiveTalks() {
                self.displayingStories = LocalizedData<[CustomStory]>(
                    repeating: allAfterLiveTalks.compactMap { (talk) -> CustomStory? in
                        guard let locale = talk.description.availableLocale(prefer: .jp) else {
                            return nil
                        }
                        let someDescription = talk.description.forLocale(locale)!
                        outerIf: if afterLiveFilter.characterRequiresMatchAll {
                            for character in afterLiveFilter.character {
                                guard let chara = PreCache.current.characters.first(where: { $0.id == character.rawValue }) else {
                                    continue
                                }
                                if !someDescription.contains(chara.characterName.forLocale(locale)?.split(separator: " ").last ?? "😋") {
                                    return nil
                                }
                            }
                        } else {
                            for character in afterLiveFilter.character {
                                guard let chara = PreCache.current.characters.first(where: { $0.id == character.rawValue }) else {
                                    continue
                                }
                                if someDescription.contains(chara.characterName.forLocale(locale)?.split(separator: " ").last ?? "😋") {
                                    break outerIf
                                }
                            }
                            return nil
                        }
                        
                        return CustomStory(
                            scenarioID: talk.scenarioID,
                            caption: "#\(talk.id)",
                            title: talk.description,
                            synopsis: "",
                            note: String(talk.id)
                        )
                    }
                )
            }
            
            if allAfterLiveTalks.isEmpty {
                DoriCache.withCache(id: "AfterLiveStories") {
                    await _DoriAPI.Misc.afterLiveTalks()
                }.onUpdate {
                    if let stories = $0 {
                        allAfterLiveTalks = stories
                        updateAfterLiveTalks()
                    } else {
                        informationIsAvailable = false
                    }
                }
            } else {
                updateAfterLiveTalks()
            }
        }
    }
    
    func selectionIsMeaningful() -> Bool {
        switch storyType {
        case .event:
            return selectedEvent != nil
        case .band:
            return selectedBandStory != nil
        case .card:
            return selectedCard != nil
        default:
            return true
        }
    }
}

extension StoryViewerView {
    struct ActionSetStoryViewer: View {
        @State var isFirstShowing = true
        @State var filter = _DoriFrontend.Filter()
        @State var isFilterSettingsPresented = false
        @State var characters: [_DoriFrontend.Characters.PreviewCharacter]?
        @State var actionSets: [_DoriAPI.Misc.ActionSet]?
        @State var actionSetAvailability = true
        var body: some View {
            if let actionSets, let characters {
                LazyVStack {
                    ForEach(actionSets) { actionSet in
                        NavigationLink(destination: {
                            StoryDetailView(
                                title: characters.filter { actionSet.characterIDs.contains($0.id) }.map { $0.characterName.forPreferredLocale() ?? "" }.joined(separator: "×"),
                                scenarioID: "",
                                type: .actionSet,
                                locale: _DoriAPI.preferredLocale,
                                unsafeAssociatedID: String(actionSet.id)
                            )
                        }) {
                            CustomGroupBox {
                                HStack {
                                    Text(verbatim: "#\(actionSet.id): \(characters.filter { actionSet.characterIDs.contains($0.id) }.map { $0.characterName.forPreferredLocale() ?? "" }.joined(separator: "×"))")
                                    Spacer()
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .toolbar {
                    ToolbarItem {
                        Button("Story-viewer.filter", systemImage: "line.3.horizontal.decrease") {
                            isFilterSettingsPresented = true
                        }
                        .foregroundColor(filter.isFiltered ? .accent : nil)
                        .sheet(isPresented: $isFilterSettingsPresented) {
                            Task {
                                self.actionSets = nil
                                await getActionSets()
                            }
                        } content: {
                            FilterView(filter: $filter, includingKeys: [
                                .character
                            ])
                        }
                    }
                }
            } else {
                if actionSetAvailability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .task {
                        if isFirstShowing {
                            isFirstShowing = false
                            await getActionSets()
                        }
                    }
                } else {
                    ExtendedConstraints {
                        ContentUnavailableView("Story-viewer.error", systemImage: "text.rectangle.page")
                            .onTapGesture {
                                Task {
                                    await getActionSets()
                                }
                            }
                    }
                }
            }
        }
        
        func getActionSets() async {
            actionSetAvailability = true
            Task {
                DoriCache.withCache(id: "CharacterList") {
                    await _DoriFrontend.Characters.categorizedCharacters()
                }.onUpdate {
                    self.characters = $0?.values.flatMap { $0 }
                }
            }
            DoriCache.withCache(id: "ActionSet") {
                await _DoriAPI.Misc.actionSets()
            }.onUpdate {
                if let actionSets = $0 {
                    self.actionSets = actionSets.filter {
                        $0.characterIDs.contains { filter.character.map { $0.rawValue }.contains($0) }
                    }
                } else {
                    actionSetAvailability = false
                }
            }
        }
    }
    
    struct AfterLiveStoryViewer: View {
        @State var isFirstShowing = true
        @State var stories: [_DoriAPI.Misc.AfterLiveTalk]?
        @State var storyAvailability = true
        @State var filter = _DoriFrontend.Filter()
        @State var isFilterSettingsPresented = false
        var body: some View {
            if let stories {
                LazyVStack {
                    ForEach(stories) { story in
                        NavigationLink(destination: {
                            StoryDetailView(
                                title: story.description.forPreferredLocale() ?? "",
                                scenarioID: story.scenarioID,
                                type: .afterLive,
                                locale: _DoriAPI.preferredLocale,
                                unsafeAssociatedID: String(story.id)
                            )
                        }) {
                            CustomGroupBox {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(verbatim: "#\(story.id)")
                                            .font(.system(size: 14))
                                            .foregroundStyle(.gray)
                                        Text(story.description.forPreferredLocale() ?? "")
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .toolbar {
                    ToolbarItem {
                        Button("Story-viewer.filter", systemImage: "line.3.horizontal.decrease") {
                            isFilterSettingsPresented = true
                        }
                        .foregroundColor(filter.isFiltered ? .accent : nil)
                        .sheet(isPresented: $isFilterSettingsPresented) {
                            Task {
                                self.stories = nil
                                await getStories()
                            }
                        } content: {
                            FilterView(filter: $filter, includingKeys: [
                                .character
                            ])
                        }
                    }
                }
            } else {
                if storyAvailability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .task {
                        if isFirstShowing {
                            isFirstShowing = false
                            await getStories()
                        }
                    }
                } else {
                    ExtendedConstraints {
                        ContentUnavailableView("Story-viewer.error", systemImage: "text.rectangle.page")
                            .onTapGesture {
                                Task {
                                    await getStories()
                                }
                            }
                    }
                }
            }
        }
        
        func getStories() async {
            storyAvailability = true
            DoriCache.withCache(id: "AfterLiveStories") {
                await _DoriAPI.Misc.afterLiveTalks()
            }.onUpdate {
                if let stories = $0 {
                    self.stories = stories.filter {
                        for id in filter.character.map({ $0.rawValue }) {
                            let character = DoriCache.preCache.characterDetails[id]
                            if let character, $0.description.jp?.contains(character.firstName.jp ?? "") ?? false {
                                return true
                            }
                        }
                        return false
                    }
                } else {
                    storyAvailability = false
                }
            }
        }
    }
}
