//===---*- Greatdori! -*---------------------------------------------------===//
//
// CostumeInfo.swift
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


// MARK: CostumeInfo
struct CostumeInfo: View {
    @State var information: PreviewCostume
    var layout: SummaryLayout
    
    init(_ costume: PreviewCostume, layout: SummaryLayout = .horizontal) {
        self.information = costume
        self.layout = layout
    }
    
    init(_ costume: Costume, layout: SummaryLayout = .horizontal) {
        self.information = PreviewCostume(costume)
        self.layout = layout
    }
    
    let costumeImageSideLength: CGFloat = 96*0.85
    
    var body: some View {
        SummaryViewBase(layout, source: information) {
            WebImage(url: information.thumbImageURL) { image in
                image
                    .resizable()
                    .antialiased(true)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: costumeImageSideLength, height: costumeImageSideLength)
                    .cornerRadius(5)
            } placeholder: {
                RoundedRectangle(cornerRadius: 5)
                    .fill(getPlaceholderColor())
                    .frame(width: costumeImageSideLength, height: costumeImageSideLength)
            }
            .interpolation(.high)
        } detail: {
            Text(DoriCache.preCache.characters.first(where: {$0.id == information.characterID})?.characterName.forPreferredLocale() ?? "nil")
                .font(isMACOS ? .body : .caption)
        }
    }
}
