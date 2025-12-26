//===---*- Greatdori! -*---------------------------------------------------===//
//
// GachaDetailCardsView.swift
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

// MARK: GachaDetailCardsView
struct GachaDetailCardsView: View {
    var information: ExtendedGacha
    @State var locale: DoriLocale = .primaryLocale
    @State var raritySectionIsExpanded: [Int: Bool] = [:]
    @State var showAsTrained = false
    var body: some View {
        Section {
            VStack {
                if !information.cardDetails.isEmpty, let rates = information.gacha.rates.forLocale(locale) {
                    let rarities = rates.keys.sorted(by: >)
                    ForEach(rarities, id: \.self) { rarity in
                        if rates[rarity]!.weightTotal > 0 {
                            CustomGroupBox {
                                VStack {
                                    HStack {
                                        Text(verbatim: "\(rates[rarity]!.rate)%")
                                            .bold()
                                        HStack(spacing: 1) {
                                            ForEach(1...rarity, id: \.self) { _ in
                                                Image(rarity > 2 ? .trainedStar : .star)
                                                    .resizable()
                                                    .frame(width: 16, height: 16)
                                            }
                                        }
                                        Spacer()
                                        if let cardsCount = information.gacha.details.forLocale(locale)?.filter({ $0.value.rarityIndex == rarity }).count {
                                            Text("\(cardsCount)")
                                                .foregroundStyle(.secondary)
                                        }
                                        Image(systemName: "chevron.forward")
                                            .foregroundStyle(.secondary)
                                            .rotationEffect(Angle(degrees: (raritySectionIsExpanded[rarity] ?? false) ? 90 : 0))
                                            .font(isMACOS ? .body : .caption)
                                    }
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        withAnimation {
                                            _ = raritySectionIsExpanded.updateValue(raritySectionIsExpanded[rarity]?.reversed() ?? true, forKey: rarity)
                                        }
                                    }
                                    
                                    if raritySectionIsExpanded[rarity] ?? false {
                                        if let _details = information.gacha.details.forPreferredLocale() {
                                            let details = _details.filter { $0.value.rarityIndex == rarity }
                                            ForEach(Set(details.values.map { $0.weight }).sorted(by: >), id: \.self) { weight in
                                                Divider()
                                                let pickups = details.filter { $0.value.weight == weight }
                                                HStack(alignment: .top) {
                                                    VStack(alignment: .leading) {
                                                        Text(verbatim: "\(unsafe String(format: "%.2f", Double(pickups.first!.value.weight) / Double(rates[rarity]!.weightTotal) * rates[rarity]!.rate))%")
                                                            .frame(width: 60, alignment: .leading)
                                                    }
                                                    CardImageGridContent(cards: information.cardDetails[rarity]!.filter { details[$0.id]?.weight == weight }, showAsTrained: showAsTrained)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: infoContentMaxWidth)
        } header: {
            HStack {
                Text("Gacha.cards")
                    .font(.title2)
                    .bold()
                DetailSectionOptionPicker(selection: $locale, options: DoriLocale.allCases)
                Spacer()
                Button(action: {
                    showAsTrained.toggle()
                }, label: {
                    Text("Gacha.cards.show-as-trained")
                        .foregroundStyle(showAsTrained ? .accent : .secondary)
                })
                .buttonStyle(.plain)
            }
            .frame(maxWidth: 615)
            .detailSectionHeader()
        }
    }
    
    struct CardImageGridContent: View {
        var cards: [PreviewCard]
        var showAsTrained: Bool = false
        @State var isExpanded = false
        var body: some View {
            VStack(alignment: .trailing) {
                WrappingHStack(alignment: .trailing, contentWidth: 60) {
                    ForEach(isExpanded ? cards : Array(cards.prefix(20))) { card in
                        CardPreviewImage(card, showTrainedVersion: showAsTrained, sideLength: 60)
                    }
                }
                if cards.count > 20 {
                    Button(action: {
                        isExpanded.toggle()
                    }, label: {
                        //                        HStack {
                        //                            Spacer()
                        if isExpanded {
                            Label("Gacha.cards.collapse", systemImage: "chevron.up")
                        } else {
                            Label("Gacha.cards.expand.\(cards.count)", systemImage: "chevron.down")
                        }
                    })
                    .buttonStyle(.borderless)
                }
            }
        }
    }
}
