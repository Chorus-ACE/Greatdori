//===---*- Greatdori! -*---------------------------------------------------===//
//
// CampaignDetailView.swift
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

struct CampaignDetailView: View {
    var id: Int
    @State var information: LoginCampaign?
    @State var availability = true
    var body: some View {
        List {
            if let information {
                Section {
                    HStack {
                        Spacer()
                        WebImage(url: information.backgroundImageURL)
                            .resizable()
                            .aspectRatio(480 / 288, contentMode: .fit)
                            .cornerRadius(8)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init())
                }
                Section {
                    InfoTextView("标题", text: information.caption)
                    InfoTextView("种类", text: information.loginBonusType.localizedString)
                    InfoTextView("开始日期", date: information.publishedAt)
                    InfoTextView("结束日期", date: information.closedAt)
                    InfoTextView(verbatim: "ID", text: String(information.id))
                }
                .listRowBackground(Color.clear)
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入登录奖励时出错", systemImage: "_calendar.badge.ring.closed", retryHandler: getInformation)
                }
            }
        }
        .navigationTitle(information?.caption.forPreferredLocale() ?? String(localized: "正在载入登录奖励..."))
        .task {
            await getInformation()
        }
    }
    
    func getInformation() async {
        availability = true
        withDoriCache(id: "CampaignDetail_\(id)") {
            await LoginCampaign(id: id)
        }.onUpdate {
            if let information = $0 {
                self.information = information
            } else {
                availability = false
            }
        }
    }
}
