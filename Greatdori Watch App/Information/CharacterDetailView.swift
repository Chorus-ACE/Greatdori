//===---*- Greatdori! -*---------------------------------------------------===//
//
// CharacterDetailView.swift
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

struct CharacterDetailView: View {
    var id: Int
    @State var information: ExtendedCharacter?
    @State var randomCard: PreviewCard?
    @State var availability = true
    var body: some View {
        List {
            if let information {
                if let randomCard {
                    Section {
                        NavigationLink(destination: { CardDetailView(id: randomCard.id) }) {
                            CardCardView(randomCard)
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        Button("随机卡牌", systemImage: "arrow.clockwise") {
                            self.randomCard = information.randomCard()
                        }
                    }
                }
                Section {
                    InfoTextView("名字", text: information.character.characterName)
                    InfoTextView("配音", text: information.character.profile?.characterVoice)
                    if let color = information.character.color {
                        InfoTextView("颜色") {
                            HStack {
                                RoundedRectangle(cornerRadius: 3)
                                    .fill(color)
                                    .frame(width: 20, height: 20)
                                Text(String(color.description.dropLast(2)))
                                    .opacity(0.6)
                            }
                        }
                    }
                    if let band = information.band {
                        InfoTextView("乐团") {
                            HStack {
                                WebImage(url: band.iconImageURL)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text(band.bandName.forPreferredLocale() ?? "")
                                    .opacity(0.6)
                            }
                        }
                    }
                    InfoTextView("位置", text: information.character.profile?.part.localizedString)
                    if let birthday = information.character.profile?.birthday {
                        InfoTextView("生日", text: birthdayDateFormatter.string(from: birthday))
                    }
                    InfoTextView("星座", text: information.character.profile?.constellation.localizedString)
                    if let height = information.character.profile?.height {
                        InfoTextView("身高", text: "\(height) cm")
                    }
                    InfoTextView("学校", text: information.character.profile?.school)
                    if let year = information.character.profile?.schoolYear.forPreferredLocale(),
                       let `class` = information.character.profile?.schoolClass.forPreferredLocale() {
                        InfoTextView("年 - 班", text: "\(year) - \(`class`)")
                    }
                    InfoTextView("喜欢的食物", text: information.character.profile?.favoriteFood)
                    InfoTextView("讨厌的食物", text: information.character.profile?.hatedFood)
                    InfoTextView("爱好", text: information.character.profile?.hobby)
                    InfoTextView("介绍", text: information.character.profile?.selfIntroduction)
                    InfoTextView(verbatim: "ID", text: String(id))
                }
                .listRowBackground(Color.clear)
                if !information.cards.isEmpty {
                    Section {
                        FoldableList(information.cards.reversed()) { card in
                            NavigationLink(destination: { CardDetailView(id: card.id) }) {
                                ThumbCardCardView(card)
                            }
                        }
                    } header: {
                        Text("卡牌")
                    }
                }
                if !information.costumes.isEmpty {
                    Section {
                        FoldableList(information.costumes.reversed()) { costume in
                            NavigationLink(destination: { CostumeLive2DViewer(id: costume.id).ignoresSafeArea() }) {
                                ThumbCostumeCardView(costume)
                            }
                        }
                    } header: {
                        Text("服装")
                    }
                }
                if !information.events.isEmpty {
                    Section {
                        FoldableList(information.events.reversed()) { event in
                            NavigationLink(destination: { EventDetailView(id: event.id) }) {
                                EventCardView(event, inLocale: nil)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }
                    } header: {
                        Text("活动")
                    }
                }
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
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入角色时出错", systemImage: "person.fill", retryHandler: getInformation)
                }
            }
        }
        .navigationTitle(information?.character.characterName.forPreferredLocale() ?? String(localized: "正在载入角色..."))
        .task {
            await getInformation()
        }
    }
    
    var birthdayDateFormatter: DateFormatter {
        let result = DateFormatter()
        result.locale = Locale.current
        result.setLocalizedDateFormatFromTemplate("MMMd")
        result.timeZone = .init(identifier: "Asia/Tokyo")
        return result
    }
    
    func getInformation() async {
        availability = true
        withDoriCache(id: "CharacterDetail_\(id)") {
            await ExtendedCharacter(id: id)
        }.onUpdate {
            if let information = $0 {
                self.information = information
                randomCard = information.randomCard()
                prefetchImages(
                    information.cards.map(\.thumbNormalImageURL)
                    + information.cards.compactMap(\.thumbAfterTrainingImageURL)
                    + information.costumes.map(\.thumbImageURL)
                    + information.events.map(\.bannerImageURL)
                    + information.gacha.map(\.bannerImageURL)
                )
            } else {
                availability = false
            }
        }
    }
}
