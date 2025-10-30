//===---*- Greatdori! -*---------------------------------------------------===//
//
// PlayerSearchView.swift
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

struct PlayerSearchView: View {
    @AppStorage("PlayerSearchPlayerIDInput") var playerID = ""
    @State var selectedLocale = DoriLocale.primaryLocale
    @State var profile: _DoriFrontend.Misc.ExtendedPlayerProfile?
    @State var isLoading = false
    var body: some View {
        List {
            Section {
                Picker("服务器", selection: $selectedLocale) {
                    ForEach(_DoriAPI.Locale.allCases, id: \.rawValue) { locale in
                        Text(locale.rawValue.uppercased()).tag(locale)
                    }
                }
                TextField("玩家ID", text: $playerID)
                Button("查询", systemImage: "magnifyingglass") {
                    profile = nil
                    isLoading = true
                    Task {
                        if let id = Int(playerID) {
                            profile = await _DoriFrontend.Misc.extendedPlayerProfile(of: id, in: selectedLocale)
                        }
                        isLoading = false
                    }
                }
            }
            if let profile {
                Section {
                    WebImage(url: profile.profile.userProfileSituation.illust == "normal" ? profile.keyVisualCard.trimmedNormalImageURL : (profile.keyVisualCard.trimmedAfterTrainingImageURL ?? profile.keyVisualCard.trimmedNormalImageURL))
                        .resizable()
                        .scaledToFit()
                        .listRowInsets(.init())
                        .listRowBackground(Color.clear)
                    HStack {
                        Spacer()
                        VStack {
                            Text(profile.profile.userName)
                                .font(.system(size: 16, weight: .bold))
                            Text("等级 \(profile.profile.rank)")
                                .font(.system(size: 14))
                            Text(profile.profile.introduction)
                                .font(.system(size: 13))
                                .opacity(0.6)
                        }
                        Spacer()
                    }
                }
                Section {
                    ForEach(profile.mainDeckCards) { card in
                        NavigationLink(destination: { CardDetailView(id: card.id) }) {
                            ThumbCardCardView(card)
                        }
                    }
                } header: {
                    Text("主乐队")
                }
            } else {
                if isLoading {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("玩家查询")
    }
}
