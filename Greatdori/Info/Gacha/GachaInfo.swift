//===---*- Greatdori! -*---------------------------------------------------===//
//
// GachaInfo.swift
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

// MARK: GachaInfo
struct GachaInfo: View {
    @State var attributedType: AttributedString? = AttributedString("")
    var subtitle: LocalizedStringKey? = nil
    var showDetails: Bool
    @Environment(\.searchedKeyword) private var searchedKeyword: Binding<String>?
    @State var information: PreviewGacha
    
    init(_ gacha: PreviewGacha, subtitle: LocalizedStringKey? = nil, showDetails: Bool = true) {
        self.information = gacha
        self.subtitle = subtitle
        self.showDetails = showDetails
    }
    init(_ gacha: Gacha, subtitle: LocalizedStringKey? = nil, showDetails: Bool = true) {
        self.information = PreviewGacha(gacha)
        self.subtitle = subtitle
        self.showDetails = showDetails
    }
    
    var body: some View {
        SummaryViewBase(.vertical(hidesDetail: !showDetails), source: information) {
            WebImage(url: information.bannerImageURL) { image in
                image
                    .resizable()
                    .antialiased(true)
                    .scaledToFit()
                    .aspectRatio(3.0, contentMode: .fit)
                    .frame(maxWidth: 420, maxHeight: 140)
            } placeholder: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(getPlaceholderColor())
                    .aspectRatio(3.0, contentMode: .fill)
                    .frame(maxWidth: 420, maxHeight: 140)
            }
            .interpolation(.high)
            .cornerRadius(10)
        } detail: {
            HighlightableText(information.type.localizedString)
            
            if let subtitle {
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

