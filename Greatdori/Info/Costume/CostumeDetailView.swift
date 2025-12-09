//===---*- Greatdori! -*---------------------------------------------------===//
//
// CostumeDetailView.swift
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

// MARK: CostumeDetailView
struct CostumeDetailView: View {
    var id: Int
    var allCostumes: [PreviewCostume]? = nil
    var body: some View {
        DetailViewBase(previewList: allCostumes, initialID: id) { information in
            CostumeDetailOverviewView(information: information)
            if !information.cards.isEmpty {
                DetailsCardsSection(cards: information.cards)
            }
            DetailArtsSection {
                ArtsTab("Costume.arts.thumb", ratio: 1) {
                    ArtsItem(title: "Costume.arts.thumb", url: information.costume.thumbImageURL)
                }
            }
            ExternalLinksSection(links: [ExternalLink(name: "External-link.bestdori", url: URL(string: "https://bestdori.com/info/costumes/\(id)")!)])
        } switcherDestination: {
            CostumeSearchView()
        }
    }
}
