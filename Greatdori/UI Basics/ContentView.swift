//===---*- Greatdori! -*---------------------------------------------------===//
//
// ContentView.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.memz.top/LICENSE.txt for license information
// See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

// This file is the root of the navigation system for the whole cross-platform, multi-system-version app.

// MARK: This file is root-navigation-related items only.

import DoriKit
import os
import SwiftUI


//MARK: ContentView
struct ContentView: View {
    @State private var selection: AppSection? = .home
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.scenePhase) var scenePhase
    @Environment(\.platform) var platform
    @AppStorage("isFirstLaunch") var isFirstLaunch = true
    @AppStorage("isFirstLaunchResettable") var isFirstLaunchResettable = true
    @AppStorage("startUpSucceeded") var startUpSucceeded = true
    @AppStorage("lastDebugPassword") var lastDebugPassword = ""
    @State var mainAppShouldBeDisplayed = false
    @State var crashViewShouldBeDisplayed = false
    @State var lastStartUpWasSuccessful = true
    @State var showWelcomeScreen = false
    @State var showPreCacheAlert = false
    @State var showCrashAlert = false
    
    var body: some View {
        if mainAppShouldBeDisplayed {
            Group {
                if #available(macOS 15.0, iOS 18.0, *) {
                    // MARK: Currently Used Version
                    TabView(selection: $selection) {
                        Tab("App.home", systemImage: "house", value: .home) {
                            HomeView()
                        }
                        Tab("App.community", systemImage: "at", value: .community) {
                            CommunityView()
                        }
                        
                        if sizeClass == .regular {
                            TabSection(content: {
                                ForEach(0..<allInfoDestinationItems.count, id: \.self) { itemIndex in
                                    Tab(value: AppSection.info(allInfoDestinationItems[itemIndex].tabValue), content: {
                                        NavigationStack {
                                            allInfoDestinationItems[itemIndex].destination()
                                                .handlesExternalView()
                                        }
                                    }, label: {
                                        Label(title: {
                                            Text(allInfoDestinationItems[itemIndex].title)
                                        }, icon: {
                                            Image(_internalSystemName: allInfoDestinationItems[itemIndex].symbol)
                                        })
                                    })
                                }
                            }, header: {
                                Text("App.info")
                            })
                        } else {
                            Tab("App.info", systemImage: "rectangle.stack", value: .info(.home)) {
                                InfoView()
                            }
                        }
                        
                        if sizeClass == .regular {
                            TabSection(content: {
                                ForEach(0..<allToolsDestinationItems.count, id: \.self) { itemIndex in
                                    Tab(value: AppSection.tools(allToolsDestinationItems[itemIndex].tabValue), content: {
                                        NavigationStack {
                                            allToolsDestinationItems[itemIndex].destination()
                                                .handlesExternalView()
                                        }
                                    }, label: {
                                        Label(title: {
                                            Text(allToolsDestinationItems[itemIndex].title)
                                        }, icon: {
                                            Image(_internalSystemName: allToolsDestinationItems[itemIndex].symbol)
                                        })
                                    })
                                }
                            }, header: {
                                Text("App.tools")
                            })
                            
                        } else {
                            Tab("App.tools", systemImage: "slider.horizontal.3", value: .tools(.home)) {
                                ToolsView()
                            }
                        }
#if os(iOS)
                        if sizeClass == .regular {
                            Tab("App.settings", systemImage: "gear", value: .settings) {
                                SettingsView()
                            }
                        }
#endif
                    }
                    .tabViewStyle(.sidebarAdaptable)
                    .wrapIf(true, in: { content in
                        if #available(iOS 26.0, *) {
                            #if os(iOS)
                            content
                                .tabBarMinimizeBehavior(.onScrollDown)
                            #else
                            content
                            #endif
                        } else {
                            content
                        }
                    })
                } else {
                    // MARK: Fallback for Older Versions
                    if platform == .mac || sizeClass == .regular {
                        NavigationSplitView {
                            List(selection: $selection) {
                                Label("App.home", systemImage: "house").tag(AppSection.home)
                                Label("App.community", systemImage: "at").tag(AppSection.community)
                                
                                Section("App.info", content: {
                                    ForEach(0..<allInfoDestinationItems.count, id: \.self) { itemIndex in
                                        Label(allInfoDestinationItems[itemIndex].title, systemImage: allInfoDestinationItems[itemIndex].symbol).tag(AppSection.info(allInfoDestinationItems[itemIndex].tabValue))
                                    }
                                })
                                Section("App.tools", content: {
                                    ForEach(0..<allToolsDestinationItems.count, id: \.self) { itemIndex in
                                        Label(allToolsDestinationItems[itemIndex].title, systemImage: allToolsDestinationItems[itemIndex].symbol).tag(AppSection.tools(allToolsDestinationItems[itemIndex].tabValue))
                                    }
                                })
#if os(iOS)
                                Label("App.settings", systemImage: "gear").tag(AppSection.settings)
#endif
                            }
                            .navigationTitle("Greatdori!")
                        } detail: {
                            detailView(for: selection)
                        }
                    } else {
                        TabView(selection: $selection) {
                            detailView(for: .home)
                                .tabItem { Label("App.home", systemImage: "house") }
                                .tag(AppSection.home)
                            
                            detailView(for: .community)
                                .tabItem { Label("App.community", systemImage: "at") }
                                .tag(AppSection.community)
                            
                            detailView(for: .info(.home))
                                .tabItem { Label("App.info", systemImage: "rectangle.stack") }
                                .tag(AppSection.info(.home))
                            
                            detailView(for: .tools(.home))
                                .tabItem { Label("App.tools", systemImage: "slider.horizontal.3") }
                                .tag(AppSection.tools(.home))
                        }
                    }
                }
            }
            .onAppear {
                if isFirstLaunch {
                    showWelcomeScreen = true
                    isFirstLaunch = !isFirstLaunchResettable
                }
#if !DORIKIT_ENABLE_PRECACHE
                showPreCacheAlert = true
#endif
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    startUpSucceeded = true
                }
                
                if !lastDebugPassword.isEmpty && lastDebugPassword != correctDebugPassword {
                    lastDebugPassword = ""
                    AppFlag.set(false, forKey: "DEBUG")
                }
            }
            .sheet(isPresented: $showWelcomeScreen, content: {
                WelcomeView(showWelcomeScreen: $showWelcomeScreen)
            })
            .alert("Home.banner.no-pre-cahce.title", isPresented: $showPreCacheAlert, actions: {
            }, message: {
                Text("Home.banner.no-pre-cahce.subtitle")
            })
            
        } else {
            if crashViewShouldBeDisplayed {
                // Crash View pretended to be the same as loading view below.
                ProgressView()
                    .onAppear {
                        os_log("CRASH VIEW HAD BEEN ENTERED")
                        if AppFlag.DEBUG {
                            showCrashAlert = true
                        } else {
                            resetAllAdvancedSettings()
                            DoriCache.invalidateAll()
                            UserDefaults.standard.set(true, forKey: "AdvancedSettingsHaveReset")
                            mainAppShouldBeDisplayed = true
                        }
                    }
                    .alert("Debug.crash-detected.title", isPresented: $showCrashAlert, actions: {
                        Button(role: .destructive, action: {
                            resetAllAdvancedSettings()
                            DoriCache.invalidateAll()
                            mainAppShouldBeDisplayed = true
                        }, label: {
                            Text("Debug.crash-detected.invalidate-cache-enter")
                        })
                        Button(role: .destructive, action: {
                            mainAppShouldBeDisplayed = true
                        }, label: {
                            Text("Debug.crash-detected.direct-enter")
                        })
                    }, message: {
                        Text("Debug.crash-detected.message")
                    })
            } else {
                ProgressView()
                    .onAppear {
                        lastStartUpWasSuccessful = startUpSucceeded
                        startUpSucceeded = false
                        if lastStartUpWasSuccessful {
                            mainAppShouldBeDisplayed = true
                            UserDefaults.standard.set(false, forKey: "AdvancedSettingsHaveReset")
                        } else {
                            crashViewShouldBeDisplayed = true
                        }
                    }
            }
        }
    }
    
    @ViewBuilder
    func detailView(for section: AppSection?) -> some View {
        switch section {
        case .home: HomeView()
        case .community: CommunityView()
//        case .leaderboard: HomeView()
        case .info(let destination):
            if destination == .home {
                InfoView()
            } else if let item = allInfoDestinationItems.first(where: { $0.tabValue == destination }) {
                item.destination()
            } else {
                InfoView()
            }
        case .tools(let destination):
            if destination == .home {
                ToolsView()
            } else if let item = allToolsDestinationItems.first(where: { $0.tabValue == destination }) {
                item.destination()
            } else {
                ToolsView()
            }
        case .settings: SettingsView()
        case nil: EmptyView()
        }
    }
}

enum AppSection: Hashable {
    case home, community, info(InfoTab), tools(ToolTab), settings
}

enum InfoTab: Hashable {
    case home, characters, cards, costumes, events, gacha, songs, songMeta, miracleTicket, comics
}

enum ToolTab: Hashable {
    case home, eventTracker, chartSimulator, storyViewer, live2dViewer, assetExplorer
}

enum Platform {
    case iOS, mac, tv, watch, unknown
}

// [?]
struct PlatformKey: EnvironmentKey {
    static let defaultValue: Platform = {
#if os(iOS)
        return .iOS
#elseif os(macOS)
        return .mac
#elseif os(tvOS)
        return .tv
#elseif os(watchOS)
        return .watch
#else
        return .unknown
#endif
    }()
}

extension EnvironmentValues {
    var platform: Platform {
        self[PlatformKey.self]
    }
}
