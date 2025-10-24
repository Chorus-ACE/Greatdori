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
    @State private var storyType = StoryType.event
    @State var displayingStories: [DoriAPI.Story] = []
    @State var informationIsAvailable = true
    
    @State var selectedEvent: PreviewEvent?
    @State var allEventStories: [DoriAPI.Events.EventStory]?
    
    var body: some View {
        ScrollView {
            HStack {
                Spacer(minLength: 0)
                VStack {
                    Section {
                        CustomGroupBox {
                            VStack {
                                Group {
                                    ListItemView(title: {
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
                                    
                                }
                                switch storyType {
                                case .event:
                                    ListItemView(title: {
                                        Text("Tools.story-viewer.type.event")
                                            .bold()
                                    }, value: {
                                        ItemSelectorButton(selection: $selectedEvent)
                                    })
                                case .main:
                                    EmptyView()
                                case .band:
                                    EmptyView()
                                case .card:
                                    EmptyView()
                                case .actionSet:
                                    EmptyView()
                                case .afterLive:
                                    EmptyView()
                                }
                            }
                        }
                        .frame(maxWidth: 600)
                        /*
                        switch storyType {
                        case .event:
                            ListItemView {
                                Text("Tools.story-viewer.type.event")
                                    .bold()
                            } value: {
                                Button(action: {
                                    eventSelectorIsPresented = true
                                }, label: {
                                    if let selectedEvent {
                                        Text(selectedEvent.eventName.forPreferredLocale() ?? "")
                                    } else {
                                        Text("选择活动…")
                                    }
                                })
                                .window(isPresented: $eventSelectorIsPresented) {
                                    EventSelector(selection: .init { [selectedEvent].compactMap { $0 } } set: { selectedEvent = $0.first })
                                        .selectorDisablesMultipleSelection()
                                }
                            }
                        case .main:
                            EmptyView()
                        case .band:
                            EmptyView()
                        case .card:
                            EmptyView()
                        case .actionSet:
                            EmptyView()
                        case .afterLive:
                            EmptyView()
                        }
                         */
                    }
                    
                    DetailSectionsSpacer(height: 15)
                }
                .padding()
                Spacer(minLength: 0)
            }
        }
        .withSystemBackground()
        .navigationTitle("Tools.story-viewer")
        .onAppear {
            Task {
                await updateStories()
            }
        }
        .onChange(of: storyType) {
            Task {
                await updateStories()
            }
        }
    }
    
    func updateStories() async {
        informationIsAvailable = true
        
        switch storyType {
        case .event:
            if allEventStories == nil {
                withDoriCache(id: "EventStories") {
                    await DoriAPI.Events.allStories()
                }.onUpdate {
                    if let stories = $0 {
                        self.allEventStories = stories
                    } else {
                        informationIsAvailable = false
                    }
                }
            }
//        case .main:
//        case .band:
//        case .card:
//        case .actionSet:
//        case .afterLive:
        default:
            print("1")
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
        case .event: "Tools.story-viewer.type.event"
        case .main: "Tools.story-viewer.type.main"
        case .band: "Tools.story-viewer.type.band"
        case .card: "Tools.story-viewer.type.card"
        case .actionSet: "Tools.story-viewer.type.action-set"
        case .afterLive: "Tools.story-viewer.type.after-live"
        }
    }
}

/*
struct EventStoryViewer: View {
    @State var isEventSelectorPresented = false
    @State var selectedEvent: PreviewEvent?
    @State var stories: [DoriAPI.Event.EventStory]?
    @State var storyAvailability = true
    var body: some View {
        ListItemView {
            Text("Tools.story-viewer.type.event")
                .bold()
        } value: {
//            Button(action: {
//                isEventSelectorPresented = true
//            }, label: {
//                if let selectedEvent {
//                    Text(selectedEvent.eventName.forPreferredLocale() ?? "")
//                } else {
//                    Text("选择活动…")
//                }
//            })
//            .window(isPresented: $isEventSelectorPresented) {
//                EventSelector(selection: .init { [selectedEvent].compactMap { $0 } } set: { selectedEvent = $0.first })
//                    .selectorDisablesMultipleSelection()
//            }
        }
        .task {
            if stories == nil {
                await getStories()
            }
        }
        if let selectedEvent {
            NavigationLink(destination: { EventDetailView(id: selectedEvent.id) }) {
                EventInfo(selectedEvent)
            }
            .buttonStyle(.plain)
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
                        ContentUnavailableView("Tools.story-viewer.type.event.unavailable", systemImage: "text.rectangle.page")
                        Spacer()
                    }
                }
            } else {
                if storyAvailability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
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
    }
    
    func getStories() async {
        storyAvailability = true
        withDoriCache(id: "EventStories") {
            await DoriAPI.Event.allStories()
        }.onUpdate {
            if let stories = $0 {
                self.stories = stories
            } else {
                storyAvailability = false
            }
        }
    }
}



extension StoryViewerView {
    
    struct MainStoryViewer: View {
        @State var isFirstShowing = true
        @State var stories: [DoriAPI.Story]?
        @State var storyAvailability = true
        var body: some View {
            if let stories {
                Section {
                    ForEach(Array(stories.enumerated()), id: \.element.id) { (index, story) in
                        StoryCardView(story: story, type: .main, locale: DoriAPI.preferredLocale, unsafeAssociatedID: String(index + 1))
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
            DoriCache.withCache(id: "MainStories") {
                await DoriAPI.Misc.mainStories()
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
        @State var bands: [DoriAPI.Band.Band]?
        @State var selectedBand: DoriAPI.Band.Band?
        @State var stories: [DoriAPI.Misc.BandStory]?
        @State var storyAvailability = true
        @State var selectedStoryGroup: DoriAPI.Misc.BandStory?
        var body: some View {
            if let bands, let stories {
                ListItemView {
                    Text("乐队")
                        .bold()
                } value: {
                    Picker("Tools.story-viewer.type.band", selection: $selectedBand) {
                        Text("Tools.story-viewer.type.band.prompt").tag(Optional<DoriAPI.Band.Band>.none)
                        ForEach(bands) { band in
                            Text(band.bandName.forPreferredLocale() ?? "").tag(band)
                        }
                    }
                    .onChange(of: selectedBand) {
                        selectedStoryGroup = nil
                    }
                }
                if let selectedBand {
                    ListItemView {
                        Text("章节")
                    } value: {
                        Picker("Tools.story-viewer.story", selection: $selectedStoryGroup) {
                            Text("Tools.story-viewer.story.prompt").tag(Optional<DoriAPI.Misc.BandStory>.none)
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
            Task {
                DoriCache.withCache(id: "BandList") {
                    await DoriAPI.Band.main()
                }.onUpdate {
                    self.bands = $0
                }
            }
            DoriCache.withCache(id: "BandStories") {
                await DoriAPI.Misc.bandStories()
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
        @State var selectedCard: DoriFrontend.Card.PreviewCard?
        @State var selectedCardDetail: DoriFrontend.Card.ExtendedCard?
        @State var cardDetailAvailability = true
        @State var isCardSelectorPresented = false
        var body: some View {
            VStack {
                ListItemView {
                    Text("卡牌")
                        .bold()
                } value: {
                    Button(action: {
                        isCardSelectorPresented = true
                    }, label: {
                        if let selectedCard, let name = selectedCard.prefix.forPreferredLocale() {
                            Text(name)
                        } else {
                            Text("选择卡牌…")
                        }
                    })
                    .buttonStyle(.borderless)
                    .window(isPresented: $isCardSelectorPresented) {
                        CardSelector(selection: .init { [selectedCard].compactMap { $0 } } set: { selectedCard = $0.first })
                            .selectorDisablesMultipleSelection()
                    }
                }
                .onChange(of: selectedCard) {
                    Task {
                        await loadCardDetail()
                    }
                }
                if let selectedCard {
                    NavigationLink(destination: { CardDetailView(id: selectedCard.id) }) {
                        CardInfo(selectedCard)
                    }
                    .buttonStyle(.plain)
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
                                        CustomGroupBox {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Group {
                                                        switch episode.episodeType {
                                                        case .standard:
                                                            Text("Tools.story-viewer.story.standard")
                                                        case .memorial:
                                                            Text("Tools.story-viewer.story.memorial")
                                                        }
                                                    }
                                                    .font(.system(size: 14))
                                                    .foregroundStyle(.gray)
                                                    Text(episode.title.forPreferredLocale() ?? "")
                                                }
                                                Spacer()
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    } else {
                        HStack {
                            Spacer()
                            ContentUnavailableView("Tools.story-viewer.story.unavailable", systemImage: "text.rectangle.page")
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
                        ExtendedConstraints {
                            ContentUnavailableView("Tools.story-viewer.error", systemImage: "text.rectangle.page")
                                .onTapGesture {
                                    Task {
                                        await loadCardDetail()
                                    }
                                }
                        }
                    }
                }
            }
        }
        
        func loadCardDetail() async {
            if let selectedCard {
                cardDetailAvailability = true
                DoriCache.withCache(id: "CardDetail_\(selectedCard.id)") {
                    await DoriFrontend.Card.extendedInformation(of: selectedCard.id)
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
        @State var filter = DoriFrontend.Filter()
        @State var isFilterSettingsPresented = false
        @State var characters: [DoriFrontend.Character.PreviewCharacter]?
        @State var actionSets: [DoriAPI.Misc.ActionSet]?
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
                                locale: DoriAPI.preferredLocale,
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
                    await DoriFrontend.Character.categorizedCharacters()
                }.onUpdate {
                    self.characters = $0?.values.flatMap { $0 }
                }
            }
            DoriCache.withCache(id: "ActionSet") {
                await DoriAPI.Misc.actionSets()
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
        @State var stories: [DoriAPI.Misc.AfterLiveTalk]?
        @State var storyAvailability = true
        @State var filter = DoriFrontend.Filter()
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
                                locale: DoriAPI.preferredLocale,
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
                await DoriAPI.Misc.afterLiveTalks()
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
    var story: DoriAPI.Story
    var type: StoryType
    var locale: DoriAPI.Locale
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
            CustomGroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        Text(verbatim: "\(story.caption.forPreferredLocale() ?? ""): \(story.title.forPreferredLocale() ?? "")")
                            .font(.headline)
                        Text(story.synopsis.forPreferredLocale() ?? "")
                            .foregroundStyle(.gray)
                    }
                    Spacer()
                }
            }
        }
        .buttonStyle(.plain)
    }
}

private struct StoryDetailView: View {
    var title: String
    var scenarioID: String
    var voiceAssetBundleName: String?
    var type: StoryType
    var locale: DoriAPI.Locale
    var unsafeAssociatedID: String // WTF
    var unsafeSecondaryAssociatedID: String?
    @State var asset: DoriAPI.Misc.StoryAsset?
    @State var transcript: [DoriAPI.Misc.StoryAsset.Transcript]?
    @State var audioPlayer = AVPlayer()
    @State var interactiveViewer = false
    var body: some View {
        if !interactiveViewer {
            ScrollView {
                HStack {
                    Spacer(minLength: 0)
                    VStack {
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
                                    .padding(.vertical)
                                case .talk(let talk):
                                    CustomGroupBox {
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
                                                audioPlayer.replaceCurrentItem(with: .init(url: .init(string: url)!))
                                                audioPlayer.play()
                                            }
                                        }, label: {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    HStack {
                                                        WebImage(url: talk.characterIconImageURL)
                                                            .resizable()
                                                            .frame(width: 20, height: 20)
                                                        Text(talk.characterName)
                                                            .font(.headline)
                                                    }
                                                    Text(talk.text)
                                                        .font(.body)
                                                        .multilineTextAlignment(.leading)
                                                }
                                                Spacer()
                                            }
                                            .foregroundStyle(Color.primary)
                                        })
                                        .buttonStyle(.borderless)
                                    }
                                    #if os(macOS)
                                    .wrapIf(true) { content in
                                        if #available(macOS 15.0, *) {
                                            content
                                                .pointerStyle(.link)
                                        } else {
                                            content
                                        }
                                    }
                                    #endif
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
                    .frame(maxWidth: 600)
                    .padding()
                    Spacer(minLength: 0)
                }
            }
            .navigationTitle(title)
            .task {
                await loadTranscript()
            }
            .toolbar {
                Toggle(isOn: $interactiveViewer, label: {
                    Image(systemName: "exclamationmark.triangle.fill")
                })
            }
        } else if let asset {
            InteractiveStoryView(asset: asset, voiceBundleURL: URL(string: {
                switch type {
                case .event:
                    "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/eventstory\(unsafeAssociatedID)_\(unsafeSecondaryAssociatedID!)"
                case .main:
                    "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/mainstory\(unsafeAssociatedID)"
                case .band:
                    "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/\(voiceAssetBundleName!)"
                case .card:
                    "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/resourceset/\(unsafeAssociatedID)"
                case .actionSet:
                    "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/actionset/actionset\(Int(floor(Double(unsafeAssociatedID)! / 200) * 10))"
                case .afterLive:
                    "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/afterlivetalk/group\(Int(floor(Double(unsafeAssociatedID)! / 100)))"
                }
            }())!, locale: locale)
        }
    }
    
    func loadTranscript() async {
        asset = switch type {
        case .event:
            await DoriAPI.Misc.eventStoryAsset(
                eventID: Int(unsafeAssociatedID)!,
                scenarioID: scenarioID,
                locale: locale
            )
        case .main:
            await DoriAPI.Misc.mainStoryAsset(
                scenarioID: scenarioID,
                locale: locale
            )
        case .band:
            await DoriAPI.Misc.bandStoryAsset(
                bandID: Int(unsafeAssociatedID)!,
                scenarioID: scenarioID,
                locale: locale
            )
        case .card:
            await DoriAPI.Misc.cardStoryAsset(
                resourceSetName: unsafeAssociatedID,
                scenarioID: scenarioID,
                locale: locale
            )
        case .actionSet:
            await DoriAPI.Misc.actionSetStoryAsset(
                actionSetID: Int(unsafeAssociatedID)!,
                locale: locale
            )
        case .afterLive:
            await DoriAPI.Misc.afterLiveStoryAsset(
                talkID: Int(unsafeAssociatedID)!,
                scenarioID: scenarioID,
                locale: locale
            )
        }
        transcript = asset?.transcript
    }
}
*/
