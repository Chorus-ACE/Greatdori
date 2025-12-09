//===---*- Greatdori! -*---------------------------------------------------===//
//
// ComicDetailView.swift
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

struct ComicDetailView: View {
    var id: Int
    var allComics: [Comic]? = nil
    var body: some View {
        DetailViewBase(forType: Comic.self, previewList: allComics, initialID: id) { information in
            ComicDetailOverviewView(information: information)
            ComicDetailComicView(information: information)
            
            DetailArtsSection {
                ArtsTab("Comic.arts.thumb", ratio: 192/140) {
                    for locale in DoriLocale.allCases {
                        if let url = information.thumbImageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url)
                        }
                    }
                }
                ArtsTab("Comic.arts.comic", ratio: 600/436) {
                    for locale in DoriLocale.allCases {
                        if let url = information.imageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url)
                        }
                    }
                }
            }
            
            ExternalLinksSection(links: [ExternalLink(name: "External-link.bestdori", url: URL(string: "https://bestdori.com/info/comics/\(id)")!)])
        } switcherDestination: {
            ComicSearchView()
        }
    }
}

