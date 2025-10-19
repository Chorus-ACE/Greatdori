//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsDebugView.swift
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

import DoriKit
import SwiftUI

struct SettingsDebugView: View {
    var body: some View {
        #if os(iOS)
        Section(content: {
          SettingsDebugControlsView()
            .fontDesign(.monospaced)
        }, header: {
            Text("Settings.debug")
        })
#else
        Section {
            SettingsDebugControlsView()
                .fontDesign(.monospaced)
        }
        .navigationTitle("Settings.debug")
#endif
    }
    
    struct SettingsDebugControlsView: View {
        @AppStorage("debugShowHomeBirthdayDatePicker") var debugShowHomeBirthdayDatePicker = false
        @AppStorage("isFirstLaunch") var isFirstLaunch = true
        @AppStorage("isFirstLaunchResettable") var isFirstLaunchResettable = true
        @AppStorage("startUpSucceeded") var startUpSucceeded = true
        @AppStorage("EnableRulerOverlay") var enableRulerOverlay = false
        @State var showDebugDisactivationAlert = false
        
        var body: some View {
            Group {
                Toggle(isOn: $debugShowHomeBirthdayDatePicker, label: {
                    Text(verbatim: "debugShowHomeBirthdayDatePicker")
                        .fontDesign(.monospaced)
                })
                Toggle(isOn: $isFirstLaunch, label: {
                    Text(verbatim: "isFirstLaunch")
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
#if !DORIKIT_ENABLE_PRECACHE
                Text("Settings.debug.pre-cache-unavailable")
                    .foregroundStyle(.red)
                    .fontDesign(.monospaced)
#endif
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
                Button(role: .destructive, action: {
                    DoriCache.invalidateAll()
                }, label: {
                    Text("Settings.debug.clear-cache")
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
            }
        }
    }
}
