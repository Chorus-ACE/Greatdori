//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventInfo.swift
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

import DoriKit
import SDWebImageSwiftUI
import SwiftUI

// MARK: EventInfo
struct EventInfo: View {
    var subtitle: LocalizedStringKey? = nil
    var showDetails: Bool
    @State var information: PreviewEvent
    
    init(_ event: PreviewEvent, subtitle: LocalizedStringKey? = nil, showDetails: Bool = true) {
        self.information = event
        self.subtitle = subtitle
        self.showDetails = showDetails
    }
    init(_ event: Event, subtitle: LocalizedStringKey? = nil, showDetails: Bool = true) {
        self.information = PreviewEvent(event)
        self.subtitle = subtitle
        self.showDetails = showDetails
    }
    
    var body: some View {
        SummaryViewBase(.vertical(hidesDetail: !showDetails), source: information) {
            FallbackableWebImage(throughURLs: [information.bannerImageURL, information.homeBannerImageURL]) { image in
                image
                    .resizable()
                    .antialiased(true)
                    .aspectRatio(3.0, contentMode: .fit)
                    .frame(maxWidth: 420, maxHeight: 140)
            } placeholder: {
                RoundedRectangle(cornerRadius: 10)
                    .fill(getPlaceholderColor())
                    .aspectRatio(3.0, contentMode: .fill)
                    .frame(maxWidth: 420, maxHeight: 140)
            }
            .interpolation(.high)
            .upscale { image in
                image
                    .resizable()
                    .antialiased(true)
                    .aspectRatio(3.0, contentMode: .fit)
                    .frame(maxWidth: 420, maxHeight: 140)
            }
            .cornerRadius(10)
        } detail: {
            Group {
                HighlightableText(information.eventType.localizedString, itemID: information.id)
            }
            
            if let subtitle {
                Text(subtitle)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
