//===---*- Greatdori! -*---------------------------------------------------===//
//
// DetailsCardsSection.swift
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
import SDWebImageSwiftUI
import SwiftUI


// MARK: DetailsCardsSection
struct DetailsCardsSection: View {
    var cards: [PreviewCard]
    var body: some View {
        DetailSectionBase("Details.cards", elements: cards.sorted {
            compare($0.releasedAt.forLocale(.jp)?.corrected(), $1.releasedAt.forLocale(.jp)?.corrected())
        }) { item in
            NavigationLink(destination: {
                CardDetailView(id: item.id)
            }, label: {
                CardInfo(item)
            })
        }
        .contentUnavailablePrompt("Details.cards.unavailable")
        .contentUnavailableImage(systemName: "person.crop.square.on.square.angled")
    }
}
