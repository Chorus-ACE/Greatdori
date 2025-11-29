//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventSearchView.swift
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

// MARK: EventSearchView
struct EventSearchView: View {
    let gridLayoutItemWidth: CGFloat = 225
    
    @Namespace var eventNamespace
    var body: some View {
        SearchViewBase(forType: PreviewEvent.self, initialLayout: true, layoutOptions: bannerLayouts) { showDetails, elements, content, eachContent in
            ViewThatFits {
                LazyVStack(spacing: showDetails ? nil : 15) {
                    let events = elements.chunked(into: 2)
                    ForEach(events, id: \.self) { eventGroup in
                        HStack {
                            Spacer(minLength: 0)
                            ForEach(eventGroup) { event in
                                eachContent(event)
                                if eventGroup.count == 1 && events[0].count != 1 {
                                    Rectangle()
                                        .frame(maxWidth: 420, maxHeight: 140)
                                        .opacity(0)
                                }
                            }
                            Spacer(minLength: 0)
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
                .frame(maxWidth: bannerWidth)
        } destination: { element, list in
            EventDetailView(id: element.id, allEvents: list)
        }
        .resultCountDescription { count in
            "Event.count.\(count)"
        }
    }
}
