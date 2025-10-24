//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventDetailView.swift
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

struct EventDetailView: View {
    var id: Int
    @State var information: ExtendedEvent?
    @State var availability = true
    var body: some View {
        List {
            if let information {
                Section {
                    WebImage(url: information.event.bannerImageURL)
                        .resizable()
                        .scaledToFit()
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init())
                }
                Section {
                    InfoTextView("标题", text: information.event.eventName)
                    InfoTextView("种类", text: information.event.eventType.localizedString)
                    if let startDate = information.event.startAt.forPreferredLocale(),
                       let endDate = information.event.endAt.forPreferredLocale(),
                       let aggregateEndDate = information.event.aggregateEndAt.forPreferredLocale(),
                       let distributionStartDate = information.event.distributionStartAt.forPreferredLocale() {
                        InfoTextView("倒计时") {
                            Group {
                                if startDate > .now {
                                    Text("\(Text(startDate, style: .relative))后开始")
                                } else if endDate > .now {
                                    Text("\(Text(endDate, style: .relative))后结束")
                                } else if aggregateEndDate > .now {
                                    Text("结果公布于\(Text(endDate, style: .relative))后")
                                } else if distributionStartDate > .now {
                                    Text("奖励颁发于\(Text(endDate, style: .relative))后")
                                } else {
                                    Text("已完结")
                                }
                            }
                            .opacity(0.6)
                        }
                    }
                    InfoTextView("开始日期", date: information.event.startAt)
                    InfoTextView("结束日期", date: information.event.endAt)
                    InfoTextView("属性") {
                        ForEach(information.event.attributes, id: \.attribute.rawValue) { attribute in
                            HStack {
                                WebImage(url: attribute.attribute.iconImageURL)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text(verbatim: "+\(attribute.percent)%")
                                    .opacity(0.6)
                            }
                        }
                    }
                    InfoTextView("角色") {
                        ForEach(information.characters) { character in
                            HStack {
                                WebImage(url: character.iconImageURL)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                if let percent = information.event.characters.first(where: { $0.characterID == character.id })?.percent {
                                    Text(verbatim: "+\(percent)%")
                                        .opacity(0.6)
                                }
                            }
                        }
                    }
                    InfoTextView("卡牌") {
                        ForEach(information.cards) { card in
                            // if the card is contained in `members`, it is a card that has bonus in this event.
                            // if not, it should be shown in rewards section (the next one).
                            if let percent = information.event.members.first(where: { $0.situationID == card.id })?.percent {
                                HStack {
                                    NavigationLink(destination: { CardDetailView(id: card.id) }) {
                                        CardIconView(card)
                                    }
                                    .buttonStyle(.borderless)
                                    Text(verbatim: "+\(percent)%")
                                        .opacity(0.6)
                                }
                            }
                        }
                    }
                    InfoTextView("奖励") {
                        HStack {
                            ForEach(information.cards) { card in
                                if information.event.rewardCards.contains(card.id) {
                                    NavigationLink(destination: { CardDetailView(id: card.id) }) {
                                        CardIconView(card)
                                    }
                                    .buttonStyle(.borderless)
                                }
                            }
                        }
                    }
                    InfoTextView(verbatim: "ID", text: String(id))
                }
                .listRowBackground(Color.clear)
                if !information.gacha.isEmpty {
                    Section {
                        FoldableList(information.gacha.reversed()) { gacha in
                            NavigationLink(destination: { GachaDetailView(id: gacha.id) }) {
                                GachaCardView(gacha)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }
                    } header: {
                        Text("招募")
                    }
                }
                if !information.songs.isEmpty {
                    Section {
                        FoldableList(information.songs.reversed()) { song in
                            NavigationLink(destination: { SongDetailView(id: song.id) }) {
                                SongCardView(song)
                            }
                        }
                    } header: {
                        Text("歌曲")
                    }
                }
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入活动时出错", systemImage: "star.hexagon.fill", retryHandler: getInformation)
                }
            }
        }
        .navigationTitle(information?.event.eventName.forPreferredLocale() ?? String(localized: "正在载入活动..."))
        .task {
            await getInformation()
        }
    }
    
    func getInformation() async {
        availability = true
        withDoriCache(id: "EventDetail_\(id)") {
            await ExtendedEvent(id: id)
        }.onUpdate {
            if let information = $0 {
                self.information = information
                prefetchImages(
                    information.cards.map(\.thumbNormalImageURL)
                    + information.cards.compactMap(\.thumbAfterTrainingImageURL)
                    + information.gacha.map(\.bannerImageURL)
                    + information.songs.map(\.jacketImageURL)
                    + information.characters.map(\.iconImageURL)
                )
            } else {
                availability = false
            }
        }
    }
}
