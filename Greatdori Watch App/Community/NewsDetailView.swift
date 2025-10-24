//===---*- Greatdori! -*---------------------------------------------------===//
//
// NewsDetailView.swift
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

struct NewsDetailView: View {
    var item: NewsListItem
    var body: some View {
        switch item.type {
        case .article:
            NewsArticleView(id: item.relatedID)
        case .song:
            SongDetailView(id: item.relatedID)
        case .loginCampaign:
            EmptyView() // FIXME
        case .event:
            EventDetailView(id: item.relatedID)
        case .gacha:
            GachaDetailView(id: item.relatedID)
        @unknown default:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.yellow)
        }
    }
}

private struct NewsArticleView: View {
    var id: Int
    @State var detail: NewsItem?
    @State var availability = true
    var body: some View {
        ScrollView {
            VStack {
                if let detail {
                    RichContentView(detail.content.forRichRendering)
                } else {
                    if availability {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        UnavailableView("载入资讯时出错", systemImage: "newspaper.fill", retryHandler: getDetail)
                    }
                }
            }
        }
        .task {
            await getDetail()
        }
    }
    
    func getDetail() async {
        availability = true
        withDoriCache(id: "NewsArticleDetail_\(id)") {
            await NewsItem(id: id)
        }.onUpdate {
            if let detail = $0 {
                self.detail = detail
            } else {
                availability = false
            }
        }
    }
}
