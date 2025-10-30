//===---*- Greatdori! -*---------------------------------------------------===//
//
// StoryViewerView.swift
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

struct StoryViewerView: View {
    @State private var storyType = StoryType.event
    var body: some View {
        List {
            Section {
                Picker("故事类型", selection: $storyType) {
                    ForEach(StoryType.allCases, id: \.self) { type in
                        Text(type.name).tag(type)
                    }
                }
                .onChange(of: storyType) {
                    UserDefaults.standard.set(storyType.rawValue, forKey: "StoryViewerSelectedStoryType")
                }
            }
            switch storyType {
            case .event:
                EventStoryViewer()
            case .main:
                MainStoryViewer()
            case .band:
                BandStoryViewer()
            case .card:
                CardStoryViewer()
            case .actionSet:
                ActionSetStoryViewer()
            case .afterLive:
                AfterLiveStoryViewer()
            }
        }
        .navigationTitle("故事浏览器")
        .onAppear {
            storyType = .init(rawValue: UserDefaults.standard.string(forKey: "StoryViewerSelectedStoryType") ?? "event") ?? .event
        }
    }
}

private enum StoryType: String, CaseIterable, Hashable {
    case event
    case main
    case band
    case card
    case actionSet
    case afterLive
    
    var name: LocalizedStringKey {
        switch self {
        case .event: "活动"
        case .main: "主线故事"
        case .band: "乐团故事"
        case .card: "卡牌故事"
        case .actionSet: "区域对话"
        case .afterLive: "Live后对话"
        }
    }
}

extension StoryViewerView {
    struct EventStoryViewer: View {
        @State var isFirstShowing = true
        @State var eventList: [PreviewEvent]?
        @State var eventListAvailability = true
        @State var selectedEvent: PreviewEvent?
        @State var stories: [_DoriAPI.Events.EventStory]?
        @State var storyAvailability = true
        var body: some View {
            if let eventList {
                Section {
                    Picker("活动", selection: $selectedEvent) {
                        ForEach(eventList) { event in
                            Text(event.eventName.forPreferredLocale() ?? "").tag(event)
                        }
                    }
                    .onChange(of: selectedEvent) {
                        UserDefaults.standard.set(selectedEvent?.id, forKey: "StoryViewerSelectedEventID")
                    }
                    if let selectedEvent {
                        NavigationLink(destination: { EventDetailView(id: selectedEvent.id) }) {
                            EventCardView(selectedEvent, inLocale: nil)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                }
                if let selectedEvent {
                    if let stories {
                        if let story = stories.first(where: { $0.id == selectedEvent.id }),
                           let locale = story.eventName.availableLocale() {
                            ForEach(Array(story.stories.enumerated()), id: \.element.id) { (index, story) in
                                StoryCardView(story: story, type: .event, locale: locale, unsafeAssociatedID: String(selectedEvent.id), unsafeSecondaryAssociatedID: String(index))
                            }
                        } else {
                            HStack {
                                Spacer()
                                ContentUnavailableView("故事不可用", systemImage: "text.rectangle.page")
                                Spacer()
                            }
                            .listRowBackground(Color.clear)
                        }
                    } else {
                        if storyAvailability {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        } else {
                            UnavailableView("载入故事时出错", systemImage: "text.rectangle.page", retryHandler: getStories)
                        }
                    }
                }
            } else {
                if eventListAvailability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .task {
                        if isFirstShowing {
                            isFirstShowing = false
                            Task {
                                await getStories()
                            }
                            await getEvents()
                        }
                    }
                } else {
                    UnavailableView("载入活动时出错", systemImage: "star.hexagon.fill", retryHandler: getEvents)
                }
            }
        }
        
        func getEvents() async {
            eventListAvailability = true
            withDoriCache(id: "EventList") {
                await PreviewEvent.all()
            }.onUpdate {
                if let events = $0 {
                    self.eventList = events
                    let storedEventID = UserDefaults.standard.integer(forKey: "StoryViewerSelectedEventID")
                    if storedEventID > 0, let event = events.first(where: { $0.id == storedEventID }) {
                        self.selectedEvent = event
                    } else {
                        self.selectedEvent = events.last
                    }
                } else {
                    eventListAvailability = false
                }
            }
        }
        func getStories() async {
            storyAvailability = true
            withDoriCache(id: "EventStories") {
                await _DoriAPI.Events.allStories()
            }.onUpdate {
                if let stories = $0 {
                    self.stories = stories
                } else {
                    storyAvailability = false
                }
            }
        }
    }
    
    struct MainStoryViewer: View {
        @State var isFirstShowing = true
        @State var stories: [_DoriAPI.Story]?
        @State var storyAvailability = true
        var body: some View {
            if let stories {
                Section {
                    ForEach(Array(stories.enumerated()), id: \.element.id) { (index, story) in
                        StoryCardView(story: story, type: .main, locale: _DoriAPI.preferredLocale, unsafeAssociatedID: String(index + 1))
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
                    UnavailableView("载入故事时出错", systemImage: "text.rectangle.page", retryHandler: getStories)
                }
            }
        }
        
        func getStories() async {
            storyAvailability = true
            DoriCache.withCache(id: "MainStories") {
                await _DoriAPI.Misc.mainStories()
            }.onUpdate {
                if let stories = $0 {
                    self.stories = stories
                } else {
                    storyAvailability = false
                }
            }
        }
    }
    
    struct BandStoryViewer: View {
        @State var isFirstShowing = true
        @State var bands: [_DoriAPI.Bands.Band]?
        @State var selectedBand: _DoriAPI.Bands.Band?
        @State var stories: [_DoriAPI.Misc.BandStory]?
        @State var storyAvailability = true
        @State var selectedStoryGroup: _DoriAPI.Misc.BandStory?
        var body: some View {
            if let bands, let stories {
                Section {
                    Picker("乐团", selection: $selectedBand) {
                        Text("(选择乐团)").tag(Optional<_DoriAPI.Bands.Band>.none)
                        ForEach(bands) { band in
                            Text(band.bandName.forPreferredLocale() ?? "").tag(band)
                        }
                    }
                    .onChange(of: selectedBand) {
                        selectedStoryGroup = nil
                    }
                    if let selectedBand {
                        Picker("故事", selection: $selectedStoryGroup) {
                            Text("(选择故事)").tag(Optional<_DoriAPI.Misc.BandStory>.none)
                            ForEach(stories.filter { $0.bandID == selectedBand.id }) { story in
                                Text(verbatim: "\(story.mainTitle.forPreferredLocale() ?? ""): \(story.subTitle.forPreferredLocale() ?? "")").tag(story)
                            }
                        }
                    }
                }
                if let selectedStoryGroup, let locale = selectedStoryGroup.publishedAt.availableLocale() {
                    ForEach(selectedStoryGroup.stories) { story in
                        StoryCardView(story: story, type: .band, locale: locale, unsafeAssociatedID: String(selectedStoryGroup.bandID))
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
                    UnavailableView("载入故事时出错", systemImage: "text.rectangle.page", retryHandler: getStories)
                }
            }
        }
        
        func getStories() async {
            storyAvailability = true
            Task {
                DoriCache.withCache(id: "BandList") {
                    await _DoriAPI.Bands.main()
                }.onUpdate {
                    self.bands = $0
                }
            }
            DoriCache.withCache(id: "BandStories") {
                await _DoriAPI.Misc.bandStories()
            }.onUpdate {
                if let stories = $0 {
                    self.stories = stories
                } else {
                    storyAvailability = false
                }
            }
        }
    }
    
    struct CardStoryViewer: View {
        @State var selectedCard: _DoriFrontend.Cards.CardWithBand?
        @State var selectedCardDetail: _DoriFrontend.Cards.ExtendedCard?
        @State var cardDetailAvailability = true
        var body: some View {
            Section {
                CardSelector(selection: $selectedCard)
                    .onChange(of: selectedCard) {
                        Task {
                            await loadCardDetail()
                        }
                        UserDefaults.standard.set(selectedCard?.id, forKey: "StoryViewerSelectedCardID")
                    }
                if let selectedCard {
                    NavigationLink(destination: { CardDetailView(id: selectedCard.card.id) }) {
                        CardCardView(selectedCard.card)
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                }
            }
            if let selectedCardDetail {
                let episodes = selectedCardDetail.card.episodes
                if !episodes.isEmpty {
                    Section {
                        ForEach(episodes) { episode in
                            if let locale = episode.title.availableLocale() {
                                NavigationLink(destination: {
                                    StoryDetailView(
                                        title: episode.title.forPreferredLocale() ?? "",
                                        scenarioID: episode.scenarioID,
                                        type: .card,
                                        locale: locale,
                                        unsafeAssociatedID: selectedCardDetail.card.resourceSetName
                                    )
                                }) {
                                    VStack(alignment: .leading) {
                                        Group {
                                            switch episode.episodeType {
                                            case .standard:
                                                Text("故事")
                                            case .memorial:
                                                Text("纪念故事")
                                            }
                                        }
                                        .font(.system(size: 14))
                                        .opacity(0.6)
                                        Text(episode.title.forPreferredLocale() ?? "")
                                    }
                                }
                            }
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        ContentUnavailableView("故事不可用", systemImage: "text.rectangle.page")
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }
            } else {
                if cardDetailAvailability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入故事时出错", systemImage: "text.rectangle.page", retryHandler: loadCardDetail)
                }
            }
        }
        
        func loadCardDetail() async {
            if let selectedCard {
                cardDetailAvailability = true
                DoriCache.withCache(id: "CardDetail_\(selectedCard.id)") {
                    await _DoriFrontend.Cards.extendedInformation(of: selectedCard.id)
                }.onUpdate {
                    if let information = $0 {
                        self.selectedCardDetail = information
                    } else {
                        cardDetailAvailability = false
                    }
                }
            }
        }
    }
    
    struct ActionSetStoryViewer: View {
        @State var isFirstShowing = true
        @State var filter = _DoriFrontend.Filter()
        @State var isFilterSettingsPresented = false
        @State var characters: [_DoriFrontend.Characters.PreviewCharacter]?
        @State var actionSets: [_DoriAPI.Misc.ActionSet]?
        @State var actionSetAvailability = true
        var body: some View {
            if let actionSets {
                Section {
                    Button("过滤", systemImage: "line.3.horizontal.decrease") {
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
                if let characters {
                    Section {
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
                                Text(verbatim: "#\(actionSet.id): \(characters.filter { actionSet.characterIDs.contains($0.id) }.map { $0.characterName.forPreferredLocale() ?? "" }.joined(separator: "×"))")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.2)
                            }
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
                    UnavailableView("载入故事时出错", systemImage: "text.rectangle.page", retryHandler: getActionSets)
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
                Section {
                    Button("过滤", systemImage: "line.3.horizontal.decrease") {
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
                Section {
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
                            VStack(alignment: .leading) {
                                Text(verbatim: "#\(story.id)")
                                    .font(.system(size: 12))
                                    .opacity(0.6)
                                Text(story.description.forPreferredLocale() ?? "")
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.2)
                            }
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
                    UnavailableView("载入故事时出错", systemImage: "text.rectangle.page", retryHandler: getStories)
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

private struct StoryCardView: View {
    var story: _DoriAPI.Story
    var type: StoryType
    var locale: _DoriAPI.Locale
    var unsafeAssociatedID: String
    var unsafeSecondaryAssociatedID: String?
    var body: some View {
        NavigationLink(destination: {
            StoryDetailView(
                title: story.title.forLocale(locale) ?? "",
                scenarioID: story.scenarioID,
                voiceAssetBundleName: story.voiceAssetBundleName,
                type: type,
                locale: locale,
                unsafeAssociatedID: unsafeAssociatedID,
                unsafeSecondaryAssociatedID: unsafeSecondaryAssociatedID
            )
        }) {
            VStack(alignment: .leading) {
                Text(verbatim: "\(story.caption.forPreferredLocale() ?? ""): \(story.title.forPreferredLocale() ?? "")")
                    .font(.headline)
                Text(story.synopsis.forPreferredLocale() ?? "")
                    .font(.system(size: 12))
                    .opacity(0.6)
            }
        }
    }
}

private struct StoryDetailView: View {
    var title: String
    var scenarioID: String
    var voiceAssetBundleName: String?
    var type: StoryType
    var locale: _DoriAPI.Locale
    var unsafeAssociatedID: String // WTF
    var unsafeSecondaryAssociatedID: String?
    @State var transcript: [_DoriAPI.Misc.StoryAsset.Transcript]?
    var body: some View {
        Form {
            if let transcript {
                ForEach(transcript, id: \.self) { transcript in
                    switch transcript {
                    case .notation(let content):
                        HStack {
                            Spacer()
                            Text(content)
                                .underline()
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .listRowBackground(Color.clear)
                    case .talk(let talk):
                        Button(action: {
                            if let voiceID = talk.voiceID {
                                let url = switch type {
                                case .event:
                                    "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/eventstory\(unsafeAssociatedID)_\(unsafeSecondaryAssociatedID!)_rip/\(voiceID).mp3"
                                case .main:
                                    "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/mainstory\(unsafeAssociatedID)_rip/\(voiceID).mp3"
                                case .band:
                                    "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/\(voiceAssetBundleName!)_rip/\(voiceID).mp3"
                                case .card:
                                    "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/resourceset/\(unsafeAssociatedID)_rip/\(voiceID).mp3"
                                case .actionSet:
                                    "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/actionset/actionset\(Int(floor(Double(unsafeAssociatedID)! / 200) * 10))_rip/\(voiceID).mp3"
                                case .afterLive:
                                    "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/afterlivetalk/group\(Int(floor(Double(unsafeAssociatedID)! / 100)))_rip/\(voiceID).mp3"
                                }
                                playAudio(url: URL(string: url)!)
                            }
                        }, label: {
                            VStack(alignment: .leading) {
                                HStack {
                                    WebImage(url: talk.characterIconImageURL)
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                    Text(talk.characterName)
                                }
                                Text(talk.text)
                                    .font(.system(size: 15))
                            }
                        })
                    @unknown default:
                        EmptyView()
                    }
                }
            } else {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            }
        }
        .navigationTitle(title)
        .task {
            await loadTranscript()
        }
    }
    
    func loadTranscript() async {
        let asset = switch type {
        case .event:
            await _DoriAPI.Misc.eventStoryAsset(
                eventID: Int(unsafeAssociatedID)!,
                scenarioID: scenarioID,
                locale: locale
            )
        case .main:
            await _DoriAPI.Misc.mainStoryAsset(
                scenarioID: scenarioID,
                locale: locale
            )
        case .band:
            await _DoriAPI.Misc.bandStoryAsset(
                bandID: Int(unsafeAssociatedID)!,
                scenarioID: scenarioID,
                locale: locale
            )
        case .card:
            await _DoriAPI.Misc.cardStoryAsset(
                resourceSetName: unsafeAssociatedID,
                scenarioID: scenarioID,
                locale: locale
            )
        case .actionSet:
            await _DoriAPI.Misc.actionSetStoryAsset(
                actionSetID: Int(unsafeAssociatedID)!,
                locale: locale
            )
        case .afterLive:
            await _DoriAPI.Misc.afterLiveStoryAsset(
                talkID: Int(unsafeAssociatedID)!,
                scenarioID: scenarioID,
                locale: locale
            )
        }
        transcript = asset?.transcript
    }
}
