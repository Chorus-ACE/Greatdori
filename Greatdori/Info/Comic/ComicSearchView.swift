//===---*- Greatdori! -*---------------------------------------------------===//
//
// ComicSearchView.swift
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


// MARK: ComicSearchView
struct ComicSearchView: View {
    let gridLayoutItemWidth: CGFloat = 260*0.9
    var body: some View {
        SearchViewBase(forType: Comic.self, initialLayout: SummaryLayout.horizontal, layoutOptions: verticalAndHorizontalLayouts) { layout, _, content, _ in
            if layout == .horizontal {
                LazyVStack {
                    content
                }
                .frame(maxWidth: 600)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: gridLayoutItemWidth, maximum: gridLayoutItemWidth))]) {
                    content
                }
            }
        } eachContent: { layout, element in
            ComicInfo(element, layout: layout)
        } destination: { element, list in
            ComicDetailView(id: element.id, allComics: list)
        }
        .resultCountDescription { count in
            "Comic.count.\(count)"
        }
    }
}
