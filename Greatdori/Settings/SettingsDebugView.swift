//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsDebugView.swift
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

struct SettingsDebugView: View {
    var body: some View {
        Group {
            SettingsDebugControlsView()
        }
        .navigationTitle("Settings.debug")
    }
    
    struct SettingsDebugControlsView: View {
        @AppStorage("isInitializationRequired") var isInitializationRequired = true
        @AppStorage("isFirstLaunchResettable") var isFirstLaunchResettable = true
        @AppStorage("startUpSucceeded") var startUpSucceeded = true
        @AppStorage("EnableRulerOverlay") var enableRulerOverlay = false
        @AppStorage("forceDisplayWhatsNewSheet") var forceDisplayWhatsNewSheet = false
        @AppStorage("ISVStyleTestFlag") var isvStyleTestFlag = 0
        @State var showDebugDisactivationAlert = false
        var body: some View {
            Section("Settings.debug.initialization") {
                Toggle("Settings.debug.initialization.welcome", isOn: $isInitializationRequired)
                Toggle("Settings.debug.initialization.always-welcome", isOn: $isFirstLaunchResettable.reversed())
                Toggle("Settings.debug.initialization.start-up-failure", isOn: $isFirstLaunchResettable.reversed())
                Toggle("Settings.debug.initialization.force-display-whats-new", isOn: $forceDisplayWhatsNewSheet)
            }
            
            Section("Settings.debug.flags") {
                Toggle("Settings.debug.flags.demo", isOn: AppFlag.bindingValue(forKey: "DEMO"))
                Toggle("Settings.debug.flags.isv-debug", isOn: AppFlag.bindingValue(forKey: "ISV_DEBUG"))
                Toggle("Settings.debug.flags.ruler", isOn: $enableRulerOverlay)
            }
            
            Section("Settings.debug.views") {
                NavigationLink("Settings.debug.views.playground", destination: { DebugPlaygroundView() })
                NavigationLink("Settings.debug.views.birthday", destination: { DebugBirthdayView() })
                NavigationLink("Settings.debug.views.filter", destination: { DebugFilterExperimentView() })
                NavigationLink("Settings.debug.views.storage", destination: { DebugStorageView() })
            }
            
            Section("Settings.debug.values") {
                Group {
                    ListItem(title: {
                        Text("Settings.debug.values.sayuru")
                    }, value: {
                        Text(isSayuruVersion ? "Settings.debug.values.bool.yes" : "Settings.debug.values.bool.no")
                    })
                    
                    if [1, 2].contains(isvStyleTestFlag) {
                        ListItem(title: {
                            Text("Settings.debug.values.isv-ab-test")
                        }, value: {
                            Text(isvStyleTestFlag == 1 ? "Settings.story-viewer.layout.always-full-screen" : "Settings.story-viewer.layout.resizable")
                        })
                        
                    }
                    
                    if let token = UserDefaults.standard.data(forKey: "RemoteNotifDeviceToken") {
                        ListItem(title: {
                            Text("Settings.debug.values.notification-token")
                        }, value: {
                            Text(token.map { unsafe String(format: "%02hhx", $0) }.joined())
                                .fontDesign(.monospaced)
                                .textSelection(.enabled)
                        })
                    }
                }
                .listItemTextStyle(.native)
            }
            
            Section("Settings.debug.actions") {
                Button(role: .destructive, action: {
                    showDebugDisactivationAlert = true
                }, label: {
                    Text("Settings.debug.disable")
                })
                .alert("Settings.debug.disable.title", isPresented: $showDebugDisactivationAlert, actions: {
                    Button(role: .destructive, action: {
                        AppFlag.set(false, forKey: "DEBUG")
                        showDebugDisactivationAlert = false
                    }, label: {
                        Text("Settings.debug.disable.turn-off")
                    })
                })
            }
        }
    }
}
