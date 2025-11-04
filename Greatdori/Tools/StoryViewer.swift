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
    @State var displayingStories: LocalizedData<[CustomStory]> = LocalizedData<[CustomStory]>(forEveryLocale: [])
    @State var informationIsAvailable = true
    @State var locale: DoriLocale = DoriLocale.primaryLocale
    @State var sectionTitle: String = "" // Deprecated?
    
    @State var allEventStories: [_DoriAPI.Events.EventStory] = []
    @State var allMainStories: [_DoriAPI.Story] = []
    @State var allBandStories: [_DoriAPI.Misc.BandStory] = []
    @State var allMainBands: [Band] = DoriCache.preCache.mainBands
    
    @State var selectedEvent: PreviewEvent?
    @State var selectedBandStory: _DoriAPI.Misc.BandStory?
    @State var selectedBand: Band? = DoriCache.preCache.mainBands.first
    @State var selectedCard: PreviewCard?
    
    var body: some View {
        ScrollView {
            HStack {
                Spacer(minLength: 0)
                VStack {
                    CustomGroupBox(cornerRadius: 20) {
                        VStack {
                            Group {
                                ListItem(title: {
                                    Text("Tools.story-viewer.type")
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
                                Divider()
                            }
                            
                            switch storyType {
                            case .event:
                                ListItem(title: {
                                    Text("Tools.story-viewer.type.event")
                                        .bold()
                                }, value: {
                                    ItemSelectorButton(selection: $selectedEvent)
                                })
                                Divider()
                            case .main:
                                EmptyView()
                            case .band:
                                ListItem(title: {
                                    Text("Tools.story-viewer.band")
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
                                Divider()
                                
                                ListItem(title: {
                                    Text("Tools.story-viewer.story")
                                        .bold()
                                }, value: {
                                    let availableBandStories: [_DoriAPI.Misc.BandStory] = allBandStories.filter({ $0.bandID == selectedBand?.id }).sorted { $0.chapterNumber < $1.chapterNumber }
                                    Picker(selection: $selectedBandStory, content: {
                                        ForEach(availableBandStories, id: \.self) { item in
                                            Text(verbatim: "\(item.mainTitle.forLocale(locale) ?? "")\(getLocalizedColon(forLocale: locale))\(item.subTitle.forLocale(locale) ?? "")")
                                                .tag(item)
                                        }
                                    }, label: {
                                        EmptyView()
                                    }, optionalCurrentValueLabel: {
                                        if let item = selectedBandStory {
                                            Text(verbatim: "\(item.mainTitle.forLocale(locale) ?? "")\(getLocalizedColon(forLocale: locale))\(item.subTitle.forLocale(locale) ?? "")")
                                        } else {
                                            Text("Tools.story-viewer.story.select")
                                        }
                                    })
                                    .labelsHidden()
                                })
                                Divider()
                            case .card:
                                ListItem(title: {
                                    Text("Tools.story-viewer.type.card")
                                        .bold()
                                }, value: {
                                    ItemSelectorButton(selection: $selectedCard)
                                })
                                Divider()
                            case .actionSet:
                                EmptyView()
                            case .afterLive:
                                EmptyView()
                            }
                            
                            ListItem(title: {
                                Text("Tools.story-viewer.locale")
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
                                    //                                case .actionSet:
                                    //                                    <#code#>
                                    //                                case .afterLive:
                                    //                                    <#code#>
                                default:
                                    EmptyView()
                                }
                            }
                        } else {
                            if selectionIsMeaningful() {
                                CustomGroupBox {
                                    HStack {
                                        Spacer()
                                        if informationIsAvailable || (displayingStories.forLocale(locale)?.isEmpty ?? true) {
                                            ProgressView()
                                        } else {
                                            Text("Tools.story-viewer.unavailable")
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
        .navigationTitle("Tools.story-viewer")
        .onAppear {
            informationIsAvailable = true
            DoriCache.withCache(id: "EventStories") {
                await _DoriAPI.Events.allStories()
            } .onUpdate {
                if let stories = $0 {
                    self.allEventStories = stories
                } else {
                    informationIsAvailable = false
                }
            }
            Task {
                await getStories()
            }
        }
        .onChange(of: locale, storyType, selectedEvent, selectedBand, selectedBandStory, selectedCard) {
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
                } .onUpdate {
                    if let stories = $0 {
                        self.allEventStories = stories
                    } else {
                        informationIsAvailable = false
                    }
                }
            }
            let eventStory = allEventStories.first(where: { $0.id == (selectedEvent?.id ?? -1) })
            displayingStories = eventStory?.stories.convertToLocalizedData() ?? LocalizedData<[CustomStory]>(forEveryLocale: [])
        case .main:
            if allMainStories.isEmpty {
                DoriCache.withCache(id: "MainStories") {
                    await _DoriAPI.Misc.mainStories()
                } .onUpdate {
                    if let stories = $0 {
                        self.allMainStories = stories
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
                } .onUpdate {
                    if let bands = $0 {
                        self.allBandStories = bands
                    } else {
                        informationIsAvailable = false
                    }
                }
            }
            displayingStories = selectedBandStory?.stories.convertToLocalizedData() ?? LocalizedData<[CustomStory]>(forEveryLocale: [])
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
            //        case .actionSet:
            //            <#code#>
            //        case .afterLive:
            //            <#code#>
        default:
            doNothing()
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
                        Button("Tools.story-viewer.filter", systemImage: "line.3.horizontal.decrease") {
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
                        ContentUnavailableView("Tools.story-viewer.error", systemImage: "text.rectangle.page")
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
                        Button("Tools.story-viewer.filter", systemImage: "line.3.horizontal.decrease") {
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
                        ContentUnavailableView("Tools.story-viewer.error", systemImage: "text.rectangle.page")
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

struct StoryCardView: View {
    var scenarioID: String
    var caption: String
    var title: String
    var synopsis: String
    var voiceAssetBundleName: String?
    
    var type: StoryType
    var locale: _DoriAPI.Locale
    var unsafeAssociatedID: String
    var unsafeSecondaryAssociatedID: String?
    
    init(story: _DoriAPI.Story, type: StoryType, locale: _DoriAPI.Locale, unsafeAssociatedID: String, unsafeSecondaryAssociatedID: String? = nil) {
        self.scenarioID = story.scenarioID
        self.caption = story.caption.forLocale(locale) ?? ""
        self.title = story.title.forLocale(locale) ?? ""
        self.synopsis = story.synopsis.forLocale(locale) ?? ""
        self.voiceAssetBundleName = story.voiceAssetBundleName
        self.type = type
        self.locale = locale
        self.unsafeAssociatedID = unsafeAssociatedID
        self.unsafeSecondaryAssociatedID = unsafeSecondaryAssociatedID
    }
    init(story: CustomStory, type: StoryType, locale: _DoriAPI.Locale, unsafeAssociatedID: String, unsafeSecondaryAssociatedID: String? = nil) {
        self.scenarioID = story.scenarioID
        self.caption = story.caption
        self.title = story.title
        self.synopsis = story.synopsis
        self.voiceAssetBundleName = story.voiceAssetBundleName
        self.type = type
        self.locale = locale
        self.unsafeAssociatedID = unsafeAssociatedID
        self.unsafeSecondaryAssociatedID = unsafeSecondaryAssociatedID
    }
    var body: some View {
        NavigationLink(destination: {
            StoryDetailView(
                title: title,
                scenarioID: scenarioID,
                voiceAssetBundleName: voiceAssetBundleName,
                type: type,
                locale: locale,
                unsafeAssociatedID: unsafeAssociatedID,
                unsafeSecondaryAssociatedID: unsafeSecondaryAssociatedID
            )
        }) {
            CustomGroupBox(cornerRadius: 20) {
                HStack {
                    VStack(alignment: .leading) {
                        if !["standard", "memorial"].contains(caption) {
                            Text(verbatim: "\(caption)\(getLocalizedColon(forLocale: locale))\(title)")
                                .font(.headline)
                            Text(synopsis)
                                .foregroundStyle(.gray)
                        } else {
                            Text(caption == "memorial" ? "Tools.story-viewer.card.memorial" : "Tools.story-viewer.card.standard")
                            Text(title)
                                .bold()
                                .font(.title3)
                        }
                    }
                    Spacer()
                }
            }
            .typesettingLanguage(locale.nsLocale().language)
        }
        .buttonStyle(.plain)
    }
}

enum StoryType: String, CaseIterable, Hashable {
    case event
    case main
    case band
    case card
    case actionSet
    case afterLive
    
    var name: LocalizedStringKey {
        switch self {
        case .event: "Tools.story-viewer.type.event"
        case .main: "Tools.story-viewer.type.main"
        case .band: "Tools.story-viewer.type.band"
        case .card: "Tools.story-viewer.type.card"
        case .actionSet: "Tools.story-viewer.type.action-set"
        case .afterLive: "Tools.story-viewer.type.after-live"
        }
    }
}

public struct CustomStory: Sendable, Identifiable, Hashable, DoriCache.Cacheable, Equatable {
    public var scenarioID: String
    public var caption: String
    public var title: String
    public var synopsis: String
    public var voiceAssetBundleName: String?
    
    public var id: String { scenarioID }
}

extension _DoriAPI.Story {
    func convertToLocalizedData() -> LocalizedData<CustomStory> {
        var result = LocalizedData<CustomStory>()
        for locale in DoriLocale.allCases {
            if self.title.availableInLocale(locale) {
                result._set(CustomStory(scenarioID: self.scenarioID, caption: self.caption.forLocale(locale) ?? "", title: self.title.forLocale(locale) ?? "", synopsis: self.synopsis.forLocale(locale) ?? "", voiceAssetBundleName: self.voiceAssetBundleName), forLocale: locale)
            }
        }
        return result
    }
}

extension Array<_DoriAPI.Story> {
    func convertToLocalizedData() -> LocalizedData<[CustomStory]> {
        var result = LocalizedData<[CustomStory]>()
        for story in self {
            for locale in DoriLocale.allCases {
                if story.title.availableInLocale(locale) {
                    result._set((result.forLocale(locale) ?? []) + [CustomStory(scenarioID: story.scenarioID, caption: story.caption.forLocale(locale) ?? "", title: story.title.forLocale(locale) ?? "", synopsis: story.synopsis.forLocale(locale) ?? "", voiceAssetBundleName: story.voiceAssetBundleName)], forLocale: locale)
                }
            }
        }
        return result
    }
}
