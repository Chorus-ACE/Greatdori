//===---*- Greatdori! -*---------------------------------------------------===//
//
// ContentView.swift
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

import OSLog
import DoriKit
import SwiftUI

struct ContentView: View {
    @AppStorage("StartUpSucceeded") var startUpSucceeded = true
    @State var navigation: NavigationPage? = .home
    @State var mainAppShouldBeDisplayed = false
    @State var crashViewShouldBeDisplayed = false
    @State var lastStartUpWasSuccessful = true
    @State var showCrashAlert = false
    var body: some View {
        if mainAppShouldBeDisplayed {
            NavigationSplitView {
                NavigationListView(navigation: $navigation)
            } detail: {
                NavigationStack {
                    switch navigation {
                    case .home:
                        HomeView()
                    case .post:
                        CommunityPostsView()
                    case .story:
                        CommunityStoriesView()
                    case .character:
                        CharacterListView()
                    case .card:
                        CardListView()
                    case .costume:
                        CostumeListView()
                    case .event:
                        EventListView()
                    case .gacha:
                        GachaListView()
                    case .song:
                        SongListView()
                    case .songMeta:
                        SongMetaView()
                    case .loginCampaign:
                        CampaignListView()
                    case .miracleTicket:
                        MiracleTicketView()
                    case .comic:
                        ComicListView()
                    case .eventTracker:
                        EventTrackerView()
                    case .playerSearch:
                        PlayerSearchView()
                    case .storyViewer:
                        StoryViewerView()
                    case nil:
                        EmptyView()
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    startUpSucceeded = true
                }
            }
        } else {
            if crashViewShouldBeDisplayed {
                // Crash View pretended to be the same as loading view below.
                ProgressView()
                    .onAppear {
                        unsafe os_log(.error, "CRASH VIEW HAD BEEN ENTERED")
                        #if DEBUG
                        showCrashAlert = true
                        #else
                        DoriCache.invalidateAll()
                        mainAppShouldBeDisplayed = true
                        #endif
                    }
                    .alert("[INTERNAL] 上次未能正常启动", isPresented: $showCrashAlert, actions: {
                        Button(action: {
                            DoriCache.invalidateAll()
                            mainAppShouldBeDisplayed = true
                        }, label: {
                            Text("无效化缓存并继续")
                        })
                        Button(role: .destructive, action: {
                            mainAppShouldBeDisplayed = true
                        }, label: {
                            Text("不进行操作并继续")
                        })
                    }, message: {
                        Text("上次启动 Greatdori! 时发生了意外。Release 构建不会显示此消息。")
                    })
            } else {
                ProgressView()
                    .onAppear {
                        lastStartUpWasSuccessful = startUpSucceeded
                        startUpSucceeded = false
                        if lastStartUpWasSuccessful {
                            mainAppShouldBeDisplayed = true
                        } else {
                            crashViewShouldBeDisplayed = true
                        }
                    }
            }
        }
    }
}

enum NavigationPage {
    case home
    case post
    case story
    case character
    case card
    case costume
    case event
    case gacha
    case song
    case songMeta
    case loginCampaign
    case miracleTicket
    case comic
    case eventTracker
    case playerSearch
    case storyViewer
}
