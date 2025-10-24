//===---*- Greatdori! -*---------------------------------------------------===//
//
// NewsListView.swift
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
import SwiftUI

struct NewsListView: View {
    @State var news: [NewsListItem]?
    @State var filter: NewsListFilter?
    @State var availability = true
    @State var isFilterPresented = false
    var body: some View {
        Form {
            if let news {
                ForEach(news, id: \.self) { item in
                    NavigationLink(destination: { NewsDetailView(item: item) }) {
                        VStack(alignment: .leading) {
                            Text(item.title)
                                .font(.system(size: 14, weight: .semibold))
                            Text({
                                let df = DateFormatter()
                                df.dateStyle = .medium
                                df.timeStyle = .short
                                return df.string(from: item.timestamp)
                            }())
                            .font(.system(size: 12))
                            .opacity(0.6)
                        }
                    }
                }
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入资讯时出错", systemImage: "newspaper.fill", retryHandler: getNews)
                }
            }
        }
        .navigationTitle("资讯")
        .task {
            await getNews()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    isFilterPresented = true
                }, label: {
                    Image(systemName: "line.3.horizontal.decrease")
                })
                .tint(filter != nil ? .accent : nil)
            }
        }
        .sheet(isPresented: $isFilterPresented) {
            news = nil
            Task {
                await getNews()
            }
        } content: {
            NewsListFilterView(filter: $filter)
        }
    }
    
    func getNews() async {
        availability = true
        withDoriCache(id: "NewsList_\(filter.identity)", trait: .realTime) {
            await NewsListItem.all(filter: filter)
        }.onUpdate {
            if let news = $0 {
                self.news = news
            } else {
                availability = false
            }
        }
    }
}

private struct NewsListFilterView: View {
    @Binding var filter: NewsListFilter?
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach([type(of: filter).none, .bestdori, .article, .patchNote, .update]
                            + DoriLocale.allCases.map { .locale($0) }, id: \.self) { selection in
                        Button(action: {
                            filter = selection
                        }, label: {
                            HStack {
                                switch selection {
                                case .none: Text("全部")
                                case .bestdori: Text(verbatim: "Bestdori!")
                                case .article: Text("文章")
                                case .patchNote: Text("更新日志")
                                case .update: Text("更新")
                                case .locale(let locale):
                                    Text(locale.rawValue.uppercased())
                                @unknown default:
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundStyle(.yellow)
                                }
                                Spacer()
                                if filter == selection {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.accent)
                                }
                            }
                        })
                    }
                }
            }
            .navigationTitle("筛选")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

extension NewsListFilter? {
    var identity: String {
        switch self {
        case .none: "None"
        case .bestdori: "Bestdori"
        case .article: "Article"
        case .patchNote: "Patch_Note"
        case .update: "Update"
        case .locale(let locale): "In_\(locale.rawValue)"
        @unknown default: "Unknown"
        }
    }
}
