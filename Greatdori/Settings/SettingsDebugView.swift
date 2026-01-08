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
        Section {
            SettingsDebugControlsView()
                .fontDesign(.monospaced)
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
            Group {
                Toggle(isOn: $isInitializationRequired, label: {
                    Text(verbatim: "isInitializationRequired")
                        .fontDesign(.monospaced)
                })
                Toggle(isOn: $isFirstLaunchResettable, label: {
                    Text(verbatim: "isFirstLaunchResettable")
                    
                })
                Toggle(isOn: $startUpSucceeded, label: {
                    Text(verbatim: "startUpSucceeded")
                    
                })
                Toggle(isOn: $enableRulerOverlay, label: {
                    Text(verbatim: "enableRulerOverlay")
                })
                Toggle(isOn: $forceDisplayWhatsNewSheet, label: {
                    Text(verbatim: "forceDisplayWhatsNewSheet")
                })
                Toggle(isOn: .init(get: { AppFlag.ISV_DEBUG }, set: { AppFlag.set($0, forKey: "ISV_DEBUG") })) {
                    Text(verbatim: "ISV_DEBUG")
                }
                
                NavigationLink(destination: {
                    DebugBirthdayView()
                }, label: {
                    Text(verbatim: "DebugBirthdayView")
                        .fontDesign(.monospaced)
                })
                NavigationLink(destination: {
                    DebugFilterExperimentView()
                }, label: {
                    Text(verbatim: "DebugFilterExperimentView")
                })
                NavigationLink(destination: {
                    DebugPlaygroundView()
                }, label: {
                    Text(verbatim: "DebugPlaygroundView")
                })
                NavigationLink(destination: {
                    DebugStorageView()
                }, label: {
                    Text(verbatim: "DebugStorageView")
                })
                Button(role: .destructive, action: {
                    
                }, label: {
                    Text("Settings.debug.clean-chart-asset")
                })
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
                ListItem(title: {
                    Text(verbatim: "ISV A/B Test")
                        .bold(false)
                }, value: {
                    Group {
                        switch isvStyleTestFlag {
                        case 1:
                            Text(verbatim: "Default Always Full Screen")
                        case 2:
                            Text(verbatim: "Default Previewable")
                        default:
                            Text(verbatim: "N/A")
                        }
                    }
                    .foregroundStyle(.secondary)
                })
                if let token = UserDefaults.standard.data(forKey: "RemoteNotifDeviceToken") {
                    ListItem {
                        Text(verbatim: "Remote Notification Token")
                            .bold(false)
                    } value: {
                        Text(token.map { unsafe String(format: "%02hhx", $0) }.joined())
                            .fontDesign(.monospaced)
                            .textSelection(.enabled)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
