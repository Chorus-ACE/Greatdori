//===---*- Greatdori! -*---------------------------------------------------===//
//
// GachaDetailView.swift
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

struct GachaDetailView: View {
    var id: Int
    @State var information: ExtendedGacha?
    @State var availability = true
    @State var cardListPresentation: [PreviewCard]?
    @State var cardDetailPresentation: Int?
    var body: some View {
        List {
            if let information {
                Section {
                    WebImage(url: information.gacha.bannerImageURL)
                        .resizable()
                        .scaledToFit()
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init())
                }
                Section {
                    InfoTextView("标题", text: information.gacha.gachaName)
                    InfoTextView("种类", text: information.gacha.type.localizedString)
                    if let publishedDate = information.gacha.publishedAt.forPreferredLocale(),
                       let closedDate = information.gacha.closedAt.forPreferredLocale() {
                        InfoTextView("倒计时") {
                            Group {
                                if publishedDate > .now {
                                    Text("\(Text(publishedDate, style: .relative))后开始")
                                } else if closedDate > .now {
                                    Text("\(Text(closedDate, style: .relative))后结束")
                                } else {
                                    Text("已完结")
                                }
                            }
                            .opacity(0.6)
                        }
                    }
                    InfoTextView("发布日期", date: information.gacha.publishedAt)
                    InfoTextView("结束日期", date: information.gacha.closedAt)
                    if !information.pickupCards.isEmpty {
                        InfoTextView("PICK UP 成员卡牌") {
                            ScrollView(.horizontal) {
                                HStack {
                                    ForEach(information.pickupCards) { card in
                                        CardIconView(card)
                                    }
                                }
                            }
                            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                            .scrollIndicators(.never)
                        }
                    }
                    InfoTextView("说明", text: information.gacha.description)
                }
                .listRowBackground(Color.clear)
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
                if !information.cardDetails.isEmpty, let rates = information.gacha.rates.forPreferredLocale() {
                    Section {
                        let keys = rates.keys.sorted(by: >)
                        ForEach(keys, id: \.self) { key in
                            if rates[key]!.weightTotal > 0 {
                                HStack {
                                    Text(verbatim: "\(rates[key]!.rate)%")
                                    HStack(spacing: 1) {
                                        ForEach(1...key, id: \.self) { _ in
                                            Image(key > 2 ? .trainedStar : .star)
                                                .resizable()
                                                .frame(width: 16, height: 16)
                                        }
                                    }
                                    Spacer()
                                }
                                .listRowBackground(Color.clear)
                                if let _details = information.gacha.details.forPreferredLocale() {
                                    let details = _details.filter { $0.value.rarityIndex == key }
                                    ForEach(Set(details.values.map { $0.weight }).sorted(by: >), id: \.self) { weight in
                                        let pickups = details.filter { $0.value.weight == weight }
                                        Button(action: {
                                            if pickups.count > 1 {
                                                cardListPresentation = information.cardDetails[key]!.filter { pickups.map { $0.key }.contains($0.id) }
                                            } else {
                                                cardDetailPresentation = pickups.first!.key
                                            }
                                        }, label: {
                                            HStack {
                                                VStack(alignment: .leading) {
                                                    Text(verbatim: "\(unsafe String(format: "%.2f", Double(pickups.first!.value.weight) / Double(rates[key]!.weightTotal) * rates[key]!.rate))%")
                                                    Spacer()
                                                    Text("\(pickups.count)张")
                                                        .font(.system(size: 13))
                                                        .opacity(0.6)
                                                }
                                                Spacer()
                                                CardIconView(information.cardDetails[key]!.first(where: { $0.id == pickups.first!.key })!)
                                            }
                                        })
                                    }
                                }
                            }
                        }
                    } header: {
                        Text("卡牌")
                    }
                }
                if !information.gacha.paymentMethods.isEmpty {
                    Section {
                        ForEach(information.gacha.paymentMethods, id: \.self) { paymentMethod in
                            VStack(alignment: .leading) {
                                Text("\(paymentMethod.count)次抽卡")
                                    .font(.system(size: 16, weight: .medium))
                                HStack {
                                    WebImage(url: paymentMethod.paymentMethod.iconImageURL)
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                    Text(verbatim: "\(paymentMethod.paymentMethod.localizedString) x\(paymentMethod.count)")
                                        .font(.system(size: 14))
                                        .opacity(0.6)
                                }
                                if paymentMethod.behavior != .normal {
                                    Text(verbatim: "\(paymentMethod.behavior.localizedString)" + (paymentMethod.maxSpinLimit != nil ? ", " + String(localized: "最多\(paymentMethod.maxSpinLimit!)次") : ""))
                                        .font(.system(size: 13))
                                        .opacity(0.6)
                                }
                            }
                        }
                    } header: {
                        Text("消耗星石")
                    }
                    .listRowBackground(Color.clear)
                }
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入招募时出错", systemImage: "line.horizontal.star.fill.line.horizontal", retryHandler: getInformation)
                }
            }
        }
        .navigationTitle(information?.gacha.gachaName.forPreferredLocale() ?? String(localized: "正在载入招募..."))
        .task {
            await getInformation()
        }
        .navigationDestination(item: $cardDetailPresentation) { id in
            CardDetailView(id: id)
        }
        .sheet(item: $cardListPresentation) { cards in
            List {
                ForEach(cards) { card in
                    Button(action: {
                        cardListPresentation = nil
                        cardDetailPresentation = card.id
                    }, label: {
                        ThumbCardCardView(card)
                    })
                }
            }
        }
    }
    
    func getInformation() async {
        availability = true
        withDoriCache(id: "GachaDetail_\(id)") {
            await ExtendedGacha(id: id)
        }.onUpdate {
            if let information = $0 {
                self.information = information
                prefetchImages(
                    information.cardDetails.flatMap(\.value).map(\.thumbNormalImageURL)
                    + information.cardDetails.flatMap(\.value).compactMap(\.thumbAfterTrainingImageURL)
                    + information.events.map(\.bannerImageURL)
                    + information.pickupCards.map(\.thumbNormalImageURL)
                    + information.pickupCards.compactMap(\.thumbAfterTrainingImageURL)
                )
            } else {
                availability = false
            }
        }
    }
}

extension Array<PreviewCard>: @retroactive Identifiable {
    public var id: String {
        self.reduce(into: "") { partialResult, card in
            partialResult += String(card.id)
        }
    }
}
