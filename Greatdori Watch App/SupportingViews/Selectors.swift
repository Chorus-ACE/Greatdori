//===---*- Greatdori! -*---------------------------------------------------===//
//
// Selectors.swift
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

struct CardSelector: View {
    @Binding var selection: CardWithBand?
    @State private var isFirstShowing = true
    @State private var cardList: [CardWithBand]?
    @State private var searchedCardList: [CardWithBand]?
    @State private var availability = true
    @State private var isSelectorPresented = false
    @State private var isFilterSettingsPresented = false
    @State private var filter = DoriFilter.recoverable(id: "CardSelector")
    @State private var sorter = DoriSorter.recoverable(id: "CardSelector")
    @State private var searchInput = ""
    var body: some View {
        Button(action: {
            isSelectorPresented = true
        }, label: {
            VStack(alignment: .leading) {
                Text("卡牌")
                if let selection {
                    Text(selection.card.cardName.forPreferredLocale() ?? "")
                        .font(.system(size: 12))
                        .opacity(0.6)
                }
            }
        })
        .task {
            if isFirstShowing {
                isFirstShowing = false
                await getCards()
            }
        }
        .sheet(isPresented: $isSelectorPresented) {
            NavigationStack {
                if let cardList = searchedCardList ?? cardList {
                    List {
                        ForEach(cardList) { card in
                            Button(action: {
                                selection = card
                                UserDefaults.standard.set(card.id, forKey: "SelectorSelectedCardID")
                                isSelectorPresented = false
                            }, label: {
                                ThumbCardCardView(card.card)
                            })
                        }
                    }
                    .sheet(isPresented: $isFilterSettingsPresented) {
                        Task {
                            self.cardList = nil
                            await getCards()
                        }
                    } content: {
                        FilterView(filter: $filter, sorter: $sorter, includingKeys: [
                            .band,
                            .attribute,
                            .rarity,
                            .character,
                            .server,
                            .released,
                            .cardType,
                            .skill
                        ], includingKeywords: [
                            .releaseDate(in: .jp),
                            .releaseDate(in: .en),
                            .releaseDate(in: .tw),
                            .releaseDate(in: .cn),
                            .releaseDate(in: .kr),
                            .rarity,
                            .maximumStat,
                            .id
                        ]) {
                            SearchView(items: cardList, text: $searchInput) { result in
                                searchedCardList = result
                            }
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                isFilterSettingsPresented = true
                            }, label: {
                                Image(systemName: "line.3.horizontal.decrease")
                            })
                            .tint(filter.isFiltered || !searchInput.isEmpty ? .accent : nil)
                        }
                    }
                } else {
                    if availability {
                        ProgressView()
                            .controlSize(.large)
                    } else {
                        UnavailableView("载入卡牌时出错", systemImage: "person.text.rectangle.fill", retryHandler: getCards)
                    }
                }
            }
        }
    }
    
    private func getCards() async {
        availability = true
        withDoriCache(id: "CardList_\(filter.identity)") {
            await Card.allWithBand()?
                .filter(withDoriFilter: filter)
                .sorted(withDoriSorter: sorter)
        }.onUpdate {
            if let cards = $0 {
                self.cardList = cards
                let storedCardID = UserDefaults.standard.integer(forKey: "SelectorSelectedCardID")
                if storedCardID > 0, let card = cards.first(where: { $0.id == storedCardID }) {
                    self.selection = card
                } else {
                    self.selection = cards.last
                }
            } else {
                availability = false
            }
        }
    }
}
