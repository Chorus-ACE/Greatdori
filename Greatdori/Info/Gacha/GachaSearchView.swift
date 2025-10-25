//===---*- Greatdori! -*---------------------------------------------------===//
//
// GachaSearchView.swift
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


// MARK: GachaSearchView
struct GachaSearchView: View {
    var body: some View {
        SearchViewBase(forType: PreviewGacha.self, initialLayout: true, layoutOptions: bannerLayouts) { layout, elements, content, eachContent in
            ViewThatFits {
                LazyVStack(spacing: layout ? nil : 15) {
                    let gachas = elements.chunked(into: 2)
                    ForEach(gachas, id: \.self) { gachaGroup in
                        HStack(spacing: layout ? nil : 0) {
                            Spacer(minLength: 0)
                            ForEach(gachaGroup) { gacha in
                                eachContent(gacha)
                                if gachaGroup.count == 1 && gachas[0].count != 1 {
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
                LazyVStack(spacing: layout ? nil : bannerSpacing) {
                    content
                }
                .frame(maxWidth: bannerWidth)
            }
            .animation(.spring(duration: 0.3, bounce: 0.1, blendDuration: 0), value: layout)
        } eachContent: { layout, element in
            GachaInfo(element, showDetails: layout)
                .frame(maxWidth: bannerWidth)
        } destination: { element, list in
            GachaDetailView(id: element.id, allGachas: list)
        }
        .resultCountDescription { count in
            "Gacha.count.\(count)"
        }
    }
}
