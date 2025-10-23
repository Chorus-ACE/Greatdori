//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardInfo.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.memz.top/LICENSE.txt for license information
// See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import Foundation
import DoriKit
import SDWebImageSwiftUI
import SwiftUI

// MARK: CardInfo
struct CardInfo: View {
    var layoutType = 1
    // 1 - List
    // 2 - Grid
    // 3 - Gallery
    
    private var band: Band?
    private var previewCard: PreviewCard
    private var displayType: CardImageDisplayType
    @Environment(\.horizontalSizeClass) var sizeClass
    @State var cardCharacterName: DoriAPI.LocalizedData<String>?
    @State var isNormalCardAvailable = true
    
    init(_ card: PreviewCard, layoutType: Int = 1, displayType: CardImageDisplayType = .both) {
        self.layoutType = layoutType
        self.band = DoriCache.preCache.categorizedCharacters.first(where: { $0.value.contains(where: { $0.id == card.characterID }) })?.key
        self.previewCard = card
        self.displayType = displayType
    }
    init(_ card: Card, layoutType: Int = 1, displayType: CardImageDisplayType = .both) {
        self.layoutType = layoutType
        self.band = DoriCache.preCache.categorizedCharacters.first(where: { $0.value.contains(where: { $0.id == card.characterID }) })?.key
        self.previewCard = PreviewCard(card)
        self.displayType = displayType
    }
    
    var body: some View {
        SummaryViewBase(layoutType == 1 ? .horizontal : .vertical(), source: previewCard) {
            if layoutType != 3 {
                HStack(spacing: 5) {
                    if isNormalCardAvailable && displayType != .trainedOnly {
                        CardPreviewImage(previewCard)
                    }
                    if previewCard.thumbAfterTrainingImageURL != nil && displayType != .normalOnly {
                        CardPreviewImage(previewCard, showTrainedVersion: true)
                    }
                }
                .wrapIf(sizeClass == .regular) { content in
                    content.frame(maxWidth: 200)
                }
            } else {
                CardCoverImage(previewCard, band: band)
                #if !os(macOS)
                    .allowsHitTesting(false)
                #endif
            }
        } detail: {
            Group {
                Text(cardCharacterName?.forPreferredLocale() ?? "nil") + Text("Typography.bold-dot-seperater").bold() + Text(previewCard.type.localizedString)
            }
            .foregroundStyle(.secondary)
            .font(isMACOS ? .body : .caption)
        }
        .onAppear {
            if cardCharacterName == nil { // First appear
                Task {
                    isNormalCardAvailable = await DoriURLValidator.reachability(
                        of: layoutType != 3 ? previewCard.thumbNormalImageURL : previewCard.coverNormalImageURL
                    )
                }
            }
            self.cardCharacterName = DoriCache.preCache.characterDetails[previewCard.characterID]?.characterName
        }
    }
}

enum CardImageDisplayType: Hashable {
    case normalOnly
    case trainedOnly
    case both
}
