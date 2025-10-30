//===---*- Greatdori! -*---------------------------------------------------===//
//
// NavigationListView.swift
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

struct NavigationListView: View {
    @Binding var navigation: NavigationPage?
    @State var isSettingsPresented = false
    var body: some View {
        List(selection: $navigation) {
            if !DoriCache.PreCache.isAvailable {
                Section {
                    Label {
                        Text(verbatim: "Building without pre-cache, some features may unavailable. ")
                        + Text(verbatim: "Do not ship!!!!!").underline()
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.yellow)
                    }
                }
            }
            Section {
                NavigationLink(value: NavigationPage.home) {
                    Label {
                        Text("主页")
                    } icon: {
                        Image(_internalSystemName: "home.fill")
                            .foregroundStyle(.accent)
                    }
                }
            }
            Section {
                NavigationLink(value: NavigationPage.post) {
                    Label {
                        Text("帖子")
                    } icon: {
                        Image(systemName: "richtext.page.fill")
                            .foregroundStyle(.accent)
                    }
                }
                NavigationLink(value: NavigationPage.story) {
                    Label {
                        Text("故事")
                    } icon: {
                        Image(systemName: "book.pages.fill")
                            .foregroundStyle(.accent)
                    }
                }
            } header: {
                Text("社区")
            }
            Section {
                NavigationLink(value: NavigationPage.character) {
                    Label {
                        Text("角色")
                    } icon: {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.accent)
                    }
                }
                NavigationLink(value: NavigationPage.card) {
                    Label {
                        Text("卡牌")
                    } icon: {
                        Image(systemName: "person.text.rectangle.fill")
                            .foregroundStyle(.accent)
                    }
                }
                NavigationLink(value: NavigationPage.costume) {
                    Label {
                        Text("服装")
                    } icon: {
                        Image(systemName: "tshirt.fill")
                            .foregroundStyle(.accent)
                    }
                }
                NavigationLink(value: NavigationPage.event) {
                    Label {
                        Text("活动")
                    } icon: {
                        Image(systemName: "star.hexagon.fill")
                            .foregroundStyle(.accent)
                    }
                }
                NavigationLink(value: NavigationPage.gacha) {
                    Label {
                        Text("招募")
                    } icon: {
                        Image(systemName: "line.horizontal.star.fill.line.horizontal")
                            .foregroundStyle(.accent)
                    }
                }
                NavigationLink(value: NavigationPage.song) {
                    Label {
                        Text("歌曲")
                    } icon: {
                        Image(_internalSystemName: "music")
                            .foregroundStyle(.accent)
                    }
                }
                NavigationLink(value: NavigationPage.songMeta) {
                    Label {
                        Text("歌曲 Meta")
                    } icon: {
                        Image(systemName: "music.pages.fill")
                            .foregroundStyle(.accent)
                    }
                }
                NavigationLink(value: NavigationPage.loginCampaign) {
                    Label {
                        Text("登录奖励")
                    } icon: {
                        Image(_internalSystemName: "calendar.badge.ring.closed")
                            .foregroundStyle(.accent)
                    }
                }
                NavigationLink(value: NavigationPage.miracleTicket) {
                    Label {
                        Text("自选券")
                    } icon: {
                        Image(systemName: "ticket.fill")
                            .foregroundStyle(.accent)
                    }
                }
                NavigationLink(value: NavigationPage.comic) {
                    Label {
                        Text("漫画")
                    } icon: {
                        Image(systemName: "photo.on.rectangle.angled.fill")
                            .foregroundStyle(.accent)
                    }
                }
            } header: {
                Text("信息")
            }
            Section {
                NavigationLink(value: NavigationPage.eventTracker) {
                    Label {
                        Text("活动Pt&排名追踪器")
                    } icon: {
                        Image(systemName: "chart.xyaxis.line")
                            .foregroundStyle(.accent)
                    }
                }
                NavigationLink(value: NavigationPage.playerSearch) {
                    Label {
                        Text("玩家查询")
                    } icon: {
                        Image(systemName: "person.crop.badge.magnifyingglass.fill")
                            .foregroundStyle(.accent)
                    }
                }
                NavigationLink(value: NavigationPage.storyViewer) {
                    Label {
                        Text("故事浏览器")
                    } icon: {
                        Image(systemName: "text.rectangle.page")
                            .foregroundStyle(.accent)
                    }
                }
            } header: {
                Text("工具")
            }
        }
        .navigationTitle("Greatdori!")
        .sheet(isPresented: $isSettingsPresented) {
            NavigationStack {
                SettingsView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    isSettingsPresented = true
                }, label: {
                    Image(systemName: "gear")
                })
            }
        }
    }
}
