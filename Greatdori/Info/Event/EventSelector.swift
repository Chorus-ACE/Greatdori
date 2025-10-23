//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventSelector.swift
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
import SwiftUI

struct MultiEventSelector: View {
    @Binding var selection: [PreviewEvent]
    var body: some View {
        ItemSelectorView("Events", selection: $selection, initialLayout: true, layoutOptions: [("Filter.view.banner-and-details", "text.below.rectangle", true)]) { showDetails, elements, content, eachContent in
            ViewThatFits {
                LazyVStack(spacing: showDetails ? nil : 15) {
                    let events = elements.chunked(into: 2)
                    ForEach(events, id: \.self) { eventGroup in
                        HStack(spacing: showDetails ? nil : 0) {
                            ForEach(eventGroup) { event in
                                eachContent(event)
                                if eventGroup.count == 1 && events[0].count != 1 {
                                    Rectangle()
                                        .frame(maxWidth: 420, maxHeight: 140)
                                        .opacity(0)
                                }
                            }
                        }
                    }
                }
                .frame(width: bannerWidth * 2 + bannerSpacing)
                LazyVStack(spacing: showDetails ? nil : bannerSpacing) {
                    content
                }
                .frame(maxWidth: bannerWidth)
            }
            .animation(.spring(duration: 0.3, bounce: 0.1, blendDuration: 0), value: showDetails)
        } eachContent: { showDetails, element in
            EventInfo(element, showDetails: showDetails)
        }
        .contentUnavailableImage(systemName: "star.hexagon")
        .resultCountDescription { count in
            "Event.count.\(count)"
        }
    }
}

struct EventSelector: View {
    @Binding var selection: PreviewEvent?
    var body: some View {
        MultiEventSelector(selection: .init { [selection].compactMap { $0 } } set: { selection = $0.first })
            .selectorDisablesMultipleSelection()
    }
}
