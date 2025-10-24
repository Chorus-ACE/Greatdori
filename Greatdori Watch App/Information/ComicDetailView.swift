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
    var comic: Comic
    var body: some View {
        List {
            Section {
                InfoTextView("标题", text: comic.title)
                InfoTextView("副标题", text: comic.subTitle)
                InfoTextView("种类", text: comic.type?.localizedString)
                let characters = DoriCache.preCache.characterDetails.filter { comic.characterIDs.contains($0.key) }
                if !characters.isEmpty {
                    InfoTextView("角色") {
                        HStack {
                            ForEach(characters.sorted { $0.key < $1.key }, id: \.key) { (_, character) in
                                WebImage(url: character.iconImageURL)
                                    .resizable()
                                    .clipShape(Circle())
                                    .frame(width: 30, height: 30)
                            }
                        }
                    }
                }
                InfoTextView(verbatim: "ID", text: String(comic.id))
            }
            .listRowBackground(Color.clear)
            Section {
                if let url = comic.imageURL {
                    HStack {
                        Spacer()
                        WebImage(url: url) { image in
                            image.resizable()
                        } placeholder: {
                            ProgressView()
                                .controlSize(.large)
                        }
                        .inspectable()
                        .scaledToFit()
                        .cornerRadius(8)
                        .frame(width: screenBounds.width - 20)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init())
                } else {
                    HStack {
                        Spacer()
                        Text("不可用")
                        Spacer()
                    }
                }
            } header: {
                Text("漫画")
            }
        }
        .navigationTitle(comic.title.forPreferredLocale() ?? "")
    }
}
