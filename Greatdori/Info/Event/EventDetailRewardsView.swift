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

import DoriKit
import SwiftUI
import SDWebImageSwiftUI

struct EventDetailRewardsView: View {
    var information: ExtendedEvent
    @State private var locale = DoriLocale.jp // FIXME: primaryLocale
    @State private var isExpanded = false
    @State private var selectedCategory = RewardCategory.point
    @State private var itemList: [_DoriFrontend.ExtendedItem]?
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section {
                if let itemList {
                    switch selectedCategory {
                    case .point:
                        if let rewards = information.event.pointRewards.forLocale(locale) {
                            WrappingHStack(rowSpacing: 10, contentWidth: 240) {
                                ForEach(rewards.enumerated().filter { isExpanded || (rewards.contains(where: { $0.reward.type == .situation || $0.reward.type == .stamp }) ? [.situation, .stamp].contains($0.element.reward.type) : $0.offset < 5) }.map { $0.element }, id: \.point) { _reward in
                                    if let reward = itemList.first(where: { $0.item == _reward.reward }) {
                                        CustomGroupBox(useExtenedConstraints: true) {
                                            HStack {
                                                VStack {
                                                    if case .card(let card) = reward.relatedItemSource {
                                                        CardPreviewImage(card, sideLength: 50)
                                                    } else if let url = reward.iconImageURL {
                                                        WebImage(url: url.localeReplaced(to: locale))
                                                            .resizable()
                                                            .scaledToFit()
                                                            .frame(width: 50, height: 50)
                                                    }
                                                    if reward.item.quantity > 1 {
                                                        Text(verbatim: "x\(String(reward.item.quantity))")
                                                    }
                                                }
                                                Spacer()
                                                VStack {
                                                    if let text = reward.text,
                                                       let name = text.name.forPreferredLocale() {
                                                        Text(name)
                                                    } else {
                                                        // FIXME: Text style
                                                        Text(verbatim: "some \(reward.item.type)")
                                                    }
                                                    Text(verbatim: "\(_reward.point) PT")
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
                                        .frame(width: 240)
                                    }
                                }
                            }
                        } else {
                            DetailUnavailableView(title: "Details.unavailable.reward", symbol: "star.square.on.square")
                        }
                    case .ranking:
                        if let rewards = information.event.rankingRewards.forLocale(locale) {
                            CustomGroupBox {
                                VStack {
                                    ForEach(rewards.grouped().prefix(isExpanded ? .max : 1), id: \.rankRange) { range, rewards in
                                        HStack(alignment: .top) {
                                            Text(verbatim: "#\(range.lowerBound)\(range.upperBound > range.lowerBound ? " - \(range.upperBound)" : "")")
                                                .bold()
                                            Spacer()
                                            VStack(alignment: .leading) {
                                                ForEach(rewards, id: \.self) { _reward in
                                                    if let reward = itemList.first(where: { $0.item == _reward.reward }) {
                                                        HStack {
                                                            if let url = reward.iconImageURL {
                                                                WebImage(url: url.localeReplaced(to: locale))
                                                                    .resizable()
                                                                    .scaledToFit()
                                                                    .frame(width: 30, height: 30)
                                                            }
                                                            if let text = reward.text,
                                                               let name = text.name.forPreferredLocale() {
                                                                Text(verbatim: "\(name) x\(reward.item.quantity)")
                                                            } else {
                                                                // FIXME: Text style
                                                                Text(verbatim: "some \(reward.item.type) x\(reward.item.quantity)")
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .insert {
                                        Divider()
                                    }
                                }
                            }
                        } else {
                            DetailUnavailableView(title: "Details.unavailable.reward", symbol: "star.square.on.square")
                        }
                    case .musicRanking:
                        if let musics = information.event.musics?.forLocale(locale) {
                            CustomGroupBox {
                                ForEach(musics.prefix(isExpanded ? .max : 1)) { music in
                                    VStack {
                                        if let song = information.eventSongs?.forLocale(locale)?.first(where: { $0.id == music.id }),
                                           let title = song.musicTitle.forLocale(locale) {
                                            HStack {
                                                Text(title)
                                                    .bold()
                                                Spacer()
                                            }
                                        }
                                        ForEach(music.rankingRewards.grouped(), id: \.rankRange) { range, rewards in
                                            HStack(alignment: .top) {
                                                Text(verbatim: "#\(range.lowerBound)\(range.upperBound > range.lowerBound ? " - \(range.upperBound)" : "")")
                                                    .bold()
                                                Spacer()
                                                VStack(alignment: .leading) {
                                                    ForEach(rewards, id: \.self) { _reward in
                                                        if let reward = itemList.first(where: { $0.item == _reward.reward }) {
                                                            HStack {
                                                                if let url = reward.iconImageURL {
                                                                    WebImage(url: url.localeReplaced(to: locale))
                                                                        .resizable()
                                                                        .scaledToFit()
                                                                        .frame(width: 30, height: 30)
                                                                }
                                                                if let text = reward.text,
                                                                   let name = text.name.forPreferredLocale() {
                                                                    Text(verbatim: "\(name) x\(reward.item.quantity)")
                                                                } else {
                                                                    // FIXME: Text style
                                                                    Text(verbatim: "some \(reward.item.type) x\(reward.item.quantity)")
                                                                }
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                        .insert {
                                            Divider()
                                        }
                                    }
                                }
                            }
                        } else {
                            DetailUnavailableView(title: "Details.unavailable.reward", symbol: "star.square.on.square")
                        }
                    case .team:
                        if let rewards = information.event.teamRewards {
                            CustomGroupBox {
                                VStack {
                                    ForEach(rewards.grouped(), id: \.result) { result, rewards in
                                        HStack(alignment: .top) {
                                            Text(result.localizedString)
                                            Spacer()
                                            VStack(alignment: .leading) {
                                                ForEach(rewards, id: \.self) { _reward in
                                                    if let reward = itemList.first(where: { $0.item == _reward.item }) {
                                                        HStack {
                                                            if let url = reward.iconImageURL {
                                                                WebImage(url: url.localeReplaced(to: locale))
                                                                    .resizable()
                                                                    .scaledToFit()
                                                                    .frame(width: 30, height: 30)
                                                            }
                                                            if let text = reward.text,
                                                               let name = text.name.forPreferredLocale() {
                                                                Text(verbatim: "\(name) x\(reward.item.quantity)")
                                                            } else {
                                                                // FIXME: Text style
                                                                Text(verbatim: "some \(reward.item.type) x\(reward.item.quantity)")
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    .insert {
                                        Divider()
                                    }
                                }
                            }
                        } else {
                            DetailUnavailableView(title: "Details.unavailable.reward", symbol: "star.square.on.square")
                        }
                    }
                } else {
                    CustomGroupBox(useExtenedConstraints: true) {
                        ProgressView()
                    }
                }
            } header: {
                HStack {
                    Text("Event.reward")
                        .font(.title2)
                        .bold()
                    DetailSectionOptionPicker(
                        selection: $selectedCategory,
                        options: [
                            .point,
                            .ranking,
                            information.event.musics != nil ? .musicRanking : nil,
                            information.event.teamRewards != nil ? .team : nil
                        ].compactMap { $0 }
                    )
                    Spacer()
                    Button(action: {
                        isExpanded.toggle()
                    }, label: {
                        Text(isExpanded ? "Details.show-less" : "Details.show-all")
                            .foregroundStyle(.secondary)
                    })
                    .buttonStyle(.plain)
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
                
                partialResult = Array(Set(partialResult))
                Task {
                    if let items = await _DoriFrontend.Misc.extendedItems(from: partialResult) {
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
