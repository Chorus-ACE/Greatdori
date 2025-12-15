//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventDetailRewardsView.swift
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

struct EventDetailRewardsView: View {
    var information: ExtendedEvent
    @State private var locale: DoriLocale = .primaryLocale // FIXME: primaryLocale
    @State private var isExpanded = false
    @State private var selectedCategory = RewardCategory.point
    @State private var itemList: [_DoriFrontend.ExtendedItem]?
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section {
                if let itemList {
                    switch selectedCategory {
                    case .point:
                        if let rewards = information.event.pointRewards.forLocale(locale), !rewards.isEmpty {
                            let rewardPointsList = rewards.enumerated().filter { isExpanded || (rewards.contains(where: { $0.reward.type == .situation || $0.reward.type == .stamp }) ? [.situation, .stamp].contains($0.element.reward.type) : $0.offset < 5) }.map { $0.element }
                            LazyVGrid(columns: [.init(.adaptive(minimum: 200))], spacing: 10) {
                                ForEach(rewardPointsList, id: \.point) { _reward in
                                    if let reward = itemList.first(where: { $0.item == _reward.reward }) {
                                        EventDetailRewardsPointsItemUnit(reward: reward, _reward: _reward, locale: locale)
                                    }
                                }
                            }
                        } else {
                            DetailUnavailableView(title: "Details.unavailable.rewards", symbol: "gift")
                        }
                    case .ranking:
                        if let rewards = information.event.rankingRewards.forLocale(locale), !rewards.isEmpty {
                            VStack {
                                ForEach(rewards.grouped().prefix(isExpanded ? .max : 1), id: \.rankRange) { range, rewards in
                                    CustomGroupBox {
                                        HStack(alignment: .top) {
                                            Text(verbatim: "#\(range.lowerBound.formatted())\(range.upperBound > range.lowerBound ? " - \(range.upperBound.formatted())" : "")")
                                                .bold()
                                            Spacer()
                                            WrappingHStack(alignment: .trailing) {
                                                ForEach(rewards, id: \.self) { _reward in
                                                    if let reward = itemList.first(where: { $0.item == _reward.reward }) {
                                                        EventDetailRewardsRankItemUnit(reward: reward, locale: locale, range: range)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            DetailUnavailableView(title: "Details.unavailable.rewards", symbol: "gift")
                        }
                    case .musicRanking:
                        if let musics = information.event.musics?.forLocale(locale), !musics.isEmpty {
                            let allElementsEqual = musics.allEqual(by: \.rankingRewards)
                            CustomGroupBox(showGroupBox: !allElementsEqual) {
                                ForEach(musics.prefix(allElementsEqual ? 1 : .max)) { music in
                                        VStack {
                                            if !allElementsEqual {
                                                if let song = information.eventSongs?.forLocale(locale)?.first(where: { $0.id == music.id }),
                                                   let title = song.musicTitle.forLocale(locale) {
                                                    HStack {
                                                        Text(title)
                                                            .bold()
                                                        Spacer()
                                                    }
                                                }
                                            }
                                            ForEach(music.rankingRewards.grouped().prefix(isExpanded ? .max : 1), id: \.rankRange) { range, rewards in
                                                if !allElementsEqual {
                                                    Divider()
                                                }
                                                CustomGroupBox(showGroupBox: allElementsEqual) {
                                                    HStack(alignment: .top) {
                                                        Text(verbatim: "#\(range.lowerBound)\(range.upperBound > range.lowerBound ? " - \(range.upperBound)" : "")")
                                                            .bold()
                                                        Spacer()
                                                        WrappingHStack(alignment: .trailing) {
                                                            ForEach(rewards, id: \.self) { _reward in
                                                                if let reward = itemList.first(where: { $0.item == _reward.reward }) {
                                                                    EventDetailRewardsRankItemUnit(reward: reward, locale: locale, range: range)
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                }
                            }
                        } else {
                            DetailUnavailableView(title: "Details.unavailable.rewards", symbol: "gift")
                        }
                    case .team:
                        if let rewards = information.event.teamRewards, !rewards.isEmpty {
                            VStack {
                                ForEach(rewards.grouped(), id: \.result) { result, rewards in
                                    CustomGroupBox {
                                        HStack(alignment: .top) {
                                            Text(result.localizedString)
                                                .bold()
                                            Spacer()
                                            WrappingHStack(alignment: .trailing) {
                                                ForEach(rewards, id: \.self) { _reward in
                                                    if let reward = itemList.first(where: { $0.item == _reward.item }) {
                                                        EventDetailRewardsRankItemUnit(reward: reward, locale: locale)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            DetailUnavailableView(title: "Details.unavailable.rewards", symbol: "gift")
                        }
                    }
                } else {
                    CustomGroupBox {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    }
                }
            } header: {
                HStack(spacing: 7) {
                    Text("Event.rewards")
                        .font(.title2)
                        .bold()
                    DetailSectionOptionPicker(selection: $selectedCategory, options: [.point, .ranking, information.event.musics != nil ? .musicRanking : nil, information.event.teamRewards != nil ? .team : nil].compactMap { $0 }, labels: [.point: String(localized: "Event.rewards.point"), .ranking: String(localized: "Event.rewards.ranking"), .musicRanking: String(localized: "Event.rewards.music-ranking"), .team: String(localized: "Event.rewards.team")])
                    DetailSectionOptionPicker(selection: $locale, options: DoriLocale.allCases)
                        .offset(x: -5)
                    Spacer()
                    Button(action: {
                        isExpanded.toggle()
                    }, label: {
                        Text(isExpanded ? "Details.show-less" : "Details.show-all")
                            .foregroundStyle(.secondary)
                    })
                    .buttonStyle(.plain)
                    .disabled(selectedCategory == .team)
                }
            }
        }
        .frame(maxWidth: infoContentMaxWidth)
        .onAppear {
            if itemList == nil {
                var partialResult: [_DoriAPI.Item] = []
                for locale in DoriLocale.allCases {
                    partialResult += information.event.pointRewards.forLocale(locale)?.map {
                        $0.reward
                    } ?? []
                    partialResult += information.event.rankingRewards.forLocale(locale)?.map {
                        $0.reward
                    } ?? []
                    partialResult += information.event.musics?.forLocale(locale)?.flatMap {
                        $0.rankingRewards.map { $0.reward }
                    } ?? []
                }
                partialResult += information.event.teamRewards?.map {
                    $0.item
                } ?? []
                
                let resultSet = Set(partialResult)
                partialResult = Array(resultSet)
                
                var hasher = StableHasher()
                var hash = 0
                for member in resultSet {
                    var hasher = StableHasher()
                    var _id = member.id
                    _id.withUTF8 { buffer in
                        unsafe hasher.combine(bytes: UnsafeRawBufferPointer(buffer))
                    }
                    hasher.combine(UInt(truncatingIfNeeded: member.itemID ?? 0))
                    hasher.combine(UInt(truncatingIfNeeded: member.quantity))
                    hash ^= hasher.finalize()
                }
                hasher.combine(UInt(truncatingIfNeeded: hash))
                let itemHash = hasher.finalize()
                
                withDoriCache(id: "ExtendedItems_\(itemHash)") {
                    await _DoriFrontend.Misc.extendedItems(from: partialResult)
                }.onUpdate {
                    if let items = $0 {
                        itemList = items
                    }
                }
            }
        }
    }
    
    private enum RewardCategory {
        case point
        case ranking
        case musicRanking
        case team
    }
}

struct EventDetailRewardsPointsItemUnit: View {
    var reward: _DoriFrontend.ExtendedItem
    var _reward: Event.PointReward
    var locale: DoriLocale
    var body: some View {
        CustomGroupBox {
            HStack {
                VStack {
                    if case .card(let card) = reward.relatedItemSource {
                        CardPreviewImage(card, sideLength: 50)
                    } else if let url = reward.iconImageURL {
                        WebImage(url: url.localeReplaced(to: locale), content: { $0 }, placeholder: {
                            RoundedRectangle(cornerRadius: 5)
                                .foregroundStyle(.placeholder)
                        })
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    } else {
                        RoundedRectangle(cornerRadius: 5)
                            .foregroundStyle(.placeholder)
                            .frame(width: 50, height: 50)
                    }
                }
                .iconBadge(reward.item.quantity, ignoreOne: true)
                Spacer()
                VStack {
                    if let text = reward.text,
                       let name = text.name.forPreferredLocale() {
                        Text(name)
                    } else {
                        Text("\(reward.item.type)")
                            .fontDesign(.monospaced)
                    }
                    Text("Event.rewards.points.\(_reward.point)")
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                Spacer()
            }
        }
        .wrapIf(true) { content in
            if case .card(let card) = reward.relatedItemSource {
                NavigationLink(destination: { CardDetailView(id: card.id) }) {
                    content
                }
                .buttonStyle(.plain)
            } else {
                content
            }
        }
    }
}

struct EventDetailRewardsRankItemUnit: View {
    var reward: _DoriFrontend.ExtendedItem
    var locale: DoriLocale
    
    var range: ClosedRange<Int>?
    
    var popoverTitle = ""
    var popoverSubtitle = ""
    @State private var isHovering = false
    @State private var audioPlayer: AVPlayer?
    
    init(reward: _DoriFrontend.ExtendedItem, locale: DoriLocale, range: ClosedRange<Int>? = nil) {
        self.reward = reward
        self.locale = locale
        self.range = range
        self.popoverTitle = reward.text?.name.forLocale(locale) ?? "\(reward.item.type)"
        self.popoverSubtitle = "\(reward.item.quantity)×"
    }
    
    var body: some View {
        Group {
            WebImage(url: reward.iconImageURL?.localeReplaced(to: locale), content: { $0 }, placeholder: {
                    RoundedRectangle(cornerRadius: 2)
                        .foregroundStyle(.placeholder)
                })
                .resizable()
                .scaledToFit()
                .frame(width: 50, height: 50)
        }
        .wrapIf(reward.item.type == .degree && range != nil) { content in
            let lowerBound = range!.lowerBound
            let upperBound = range!.upperBound
            if upperBound > lowerBound {
                content.iconBadge("T\(upperBound >= 1000 ? "\(upperBound / 1000)K" : "\(upperBound)")")
            } else {
                let labelForTops: String = {
                    switch locale {
                    case .jp:
                        return "\(lowerBound)位"
                    case .en:
                        return lowerBound == 1 ? "\(lowerBound)st" : (lowerBound == 2 ? "\(lowerBound)nd" : (lowerBound == 3 ? "\(lowerBound)rd" : "\(lowerBound)th"))
                    case .tw:
                        return "第\(lowerBound)名"
                    case .cn:
                        return "\(lowerBound)位"
                    case .kr:
                        return "\(lowerBound)위"
                    }
                }()
                content.iconBadge(labelForTops)
            }
        } else: { content in
            content.iconBadge(reward.item.quantity, ignoreOne: true)
        }
        .wrapIf(true) { content in
            #if os(iOS)
            content
                .contextMenu {
                    VStack {
                        Button(action: {}, label: {
                            Group {
                                Text(popoverTitle)
                                Text(popoverSubtitle)
                                    .font(.caption)
                            }
                        })
                        if let playVoice {
                            Button("播放语音", systemImage: "play.fill") {
                                playVoice()
                            }
                        }
                    }
                }
            #else
            let sumimi = HereTheWorld(arguments: (popoverTitle, popoverSubtitle)) { title, subtitle in
                VStack {
                    Group {
                        Text(title)
                        Text(subtitle)
                            .font(.caption)
                    }
                }
                .padding()
            }
            content
                .onHover { isHovering in
                    self.isHovering = isHovering
                }
                .popover(isPresented: $isHovering, arrowEdge: .bottom) {
                    sumimi
                }
                .onChange(of: popoverTitle) {
                    sumimi.updateArguments((popoverTitle, popoverSubtitle))
                }
                .onChange(of: popoverSubtitle) {
                    sumimi.updateArguments((popoverTitle, popoverSubtitle))
                }
            #endif
        }
        .wrapIf(true) { content in
            if let playVoice {
                Button(action: {
                    playVoice()
                }, label: {
                    content
                })
                .buttonStyle(.plain)
            } else {
                content
            }
        }
    }
    
    private var playVoice: (() -> Void)? {
        if case .stampVoice(let url) = reward.relatedItemSource {
            {
                audioPlayer = .init(url: url)
                unsafe audioPlayer.unsafelyUnwrapped.play()
            }
        } else {
            nil
        }
    }
}

/*
 ViewThatFits {
     LazyVStack(spacing: showDetails ? nil : 15) {
         let events = elements.chunked(into: 2)
         ForEach(events, id: \.self) { eventGroup in
             HStack {
                 Spacer(minLength: 0)
                 ForEach(eventGroup) { event in
                     eachContent(event)
                     if eventGroup.count == 1 && events[0].count != 1 {
                         Rectangle()
                             .frame(maxWidth: 420, maxHeight: 140)
                             .opacity(0)
                     }
                 }
                 Spacer(minLength: 0)
             }
         }
     }
     .frame(width: bannerWidth * 2 + bannerSpacing)
     LazyVStack(spacing: showDetails ? nil : bannerSpacing) {
         content
     }
     .frame(maxWidth: bannerWidth)
 }
 */

extension Array<Event.RankingReward> {
    fileprivate func grouped() -> [(rankRange: ClosedRange<Int>, reward: [Event.RankingReward])] {
        self.reduce(into: [(ClosedRange<Int>, [Event.RankingReward])]()) { partialResult, reward in
            if let last = partialResult.last, last.0 == reward.rankRange {
                partialResult[partialResult.count - 1].1.append(reward)
            } else {
                partialResult.append((reward.rankRange, [reward]))
            }
        }
    }
}
extension Array<Event.FestivalTeamReward> {
    fileprivate func grouped() -> [(result: Event.FestivalResult, reward: [Event.FestivalTeamReward])] {
        self.reduce(into: [(Event.FestivalResult, [Event.FestivalTeamReward])]()) { partialResult, reward in
            if let last = partialResult.last, last.0 == reward.festivalResult {
                partialResult[partialResult.count - 1].1.append(reward)
            } else {
                partialResult.append((reward.festivalResult, [reward]))
            }
        }.sorted { $0.0.rawValue > $1.0.rawValue }
    }
}

struct IconBadgeModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    let count: Int
    let text: String?
    let backgroundColor: Color?
    let foregroundColor: Color
    let height: CGFloat
    let ignoreOne: Bool
    
    init(count: Int, backgroundColor: Color?, foregroundColor: Color, height: CGFloat, ignoreOne: Bool) {
        self.count = count
        self.text = nil
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.height = height
        self.ignoreOne = ignoreOne
    }
    
    init(text: String, backgroundColor: Color?, foregroundColor: Color, height: CGFloat) {
        self.count = 0
        self.text = text
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.height = height
        self.ignoreOne = false
    }

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                if (count > 0 && (!ignoreOne || count > 1)) || text != nil {
                    Group {
                        if let text {
                            Text(text)
                        } else {
                            Text(count, format: .number.notation(.compactName))
                        }
                    }
                        .lineLimit(1)
                        .font(.system(size: height * 0.6, weight: .semibold))
                        .foregroundColor(foregroundColor)
                        .padding(.horizontal, height * 0.35)
                        .frame(minWidth: height, minHeight: height)
                        .background(
                            Capsule()
                                .fill(backgroundColor ?? (colorScheme == .dark ? .black : .white))
                                .shadow(radius: 2)
                        )
                        // 微调位置，贴近图标角
                        .offset(x: height * 0.35, y: -height * 0.35)
                        .accessibilityLabel("\(count)")
                }
            }
    }
}

extension View {
    func iconBadge(
        _ count: Int,
        backgroundColor: Color? = nil,
        foregroundColor: Color = .primary,
        height: CGFloat = 18,
        ignoreOne: Bool = false
    ) -> some View {
        modifier(
            IconBadgeModifier(
                count: count,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                height: height,
                ignoreOne: ignoreOne
            )
        )
    }
    
    func iconBadge(
        _ text: String,
        backgroundColor: Color? = nil,
        foregroundColor: Color = .primary,
        height: CGFloat = 18,
        ignoreOne: Bool = false
    ) -> some View {
        modifier(
            IconBadgeModifier(
                text: text,
                backgroundColor: backgroundColor,
                foregroundColor: foregroundColor,
                height: height
            )
        )
    }
}
