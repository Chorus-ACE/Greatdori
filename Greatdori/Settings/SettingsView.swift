//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsView.swift
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

// Settings.

import SwiftUI
import DoriKit
import EventKit
import WidgetKit
import UserNotifications

let birthdayTimeZoneNameDict: [BirthdayTimeZone: LocalizedStringResource] = [.adaptive: "Settings.birthday-time-zone.name.adaptive", .JST: "Settings.birthday-time-zone.name.JST", .UTC: "Settings.birthday-time-zone.name.UTC", .CST: "Settings.birthday-time-zone.name.CST", .PT: "Settings.birthday-time-zone.name.PT"]
let showBirthdayDateDefaultValue = 1

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    @State var selectionItem: Int = 0
    var usedAsSheet: Bool = false
    
    let SettingsTabs: [(LocalizedStringResource, )] = []
    var body: some View {
        #if os(iOS)
        NavigationStack {
            Form {
                SettingsLocaleView()
                SettingsHomeView()
                SettingsPermissionsView()
                SettingsWidgetsView()
                SettingsFontsView()
                SettingsOfflineDataView()
                SettingsAboutView()
                if AppFlag.DEBUG {
                    SettingsDebugView()
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .wrapIf(usedAsSheet, in: { content in
                content
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            DismissButton(action: dismiss.callAsFunction) {
                                Image(systemName: "xmark")
                            }
                        }
                    }
            })
        }
        #else
        NavigationSplitView(sidebar: {
            List(selection: $selectionItem, content: {
                Label("Settings.locale", systemImage: "globe")
                    .tag(0)
                Label("Settings.home-edit", systemImage: "rectangle.3.group")
                    .tag(1)
                Label("Settings.permissions", systemImage: "bell.badge")
                    .tag(2)
                Label("Settings.widgets", systemImage: "widget.small")
                    .tag(3)
                Label("Settings.fonts", systemImage: "textformat")
                    .tag(10)
                Label("Settings.advanced", systemImage: "hammer")
                    .tag(20)
                Label("Settings.about", systemImage: "info.circle")
                    .tag(21)
                if AppFlag.DEBUG {
                    Label("Settings.debug", systemImage: "ant")
                        .tag(23)
                }
            })
//            .toolbar(removing: .sidebarToggle)
        }, detail: {
            NavigationStack {
                switch selectionItem {
                case 0:
                    Form {
                        SettingsLocaleView()
                    }
                    .formStyle(.grouped)
                case 1:
                    Form {
                        SettingsHomeView()
                    }
                    .formStyle(.grouped)
                case 2:
                    Form {
                        SettingsPermissionsView()
                    }
                    .formStyle(.grouped)
                case 3:
                    Form {
                        SettingsWidgetsView()
                    }
                    .formStyle(.grouped)
                case 10:
                    SettingsFontsView()
                case 20:
                    Form {
                        SettingsAdvancedView()
                    }
                    .formStyle(.grouped)
                case 21:
                    SettingsAboutView()
                case 23:
                    Form {
                        SettingsDebugView()
                    }
                    .formStyle(.grouped)
                default:
                    ProgressView()
                }
            }
        })
        //        .toolbar(removing: .sidebarToggle)
        #endif
    }
}






struct SettingsOfflineDataView: View {
    @State var dataSourcePreference: DataSourcePreference = .hybrid
    var body: some View {
        Section(content: {
            Picker("Settings.offline-data.source-preference", selection: $dataSourcePreference, content: {
                Text("Settings.offline-data.source-preference.selection.hybrid")
                    .tag(DataSourcePreference.hybrid)
                Text("Settings.offline-data.source-preference.selection.internet")
                    .tag(DataSourcePreference.useInternet)
                Text("Settings.offline-data.source-preference.selection.local")
                    .tag(DataSourcePreference.useLocal)
            })
            .onChange(of: dataSourcePreference, {
                UserDefaults.standard.setValue(dataSourcePreference.rawValue, forKey: "DataSourcePreference")
            })
        }, header: {
            Text("Settings.offline-data")
        })
        .onAppear {
            dataSourcePreference = DataSourcePreference(rawValue: UserDefaults.standard.string(forKey: "DataSourcePreference") ?? "hybrid") ?? .hybrid
        }
    }
}

/*
struct SettingsAboutView: View {
    @State var showDebugVerificationAlert = false
    @State var password = ""
    @State var showDebugUnlockAlert = false
    @AppStorage("lastDebugPassword") var lastDebugPassword = ""
    var body: some View {
        Section(content: {
            Text(verbatim: "Greatdori!")
                .onTapGesture(count: 3, perform: {
                    showDebugVerificationAlert = true
                })
                .alert("Settings.debug.activate-alert.title", isPresented: $showDebugVerificationAlert, actions: {
#if os(iOS)
                    TextField("Settings.debug.activate-alert.prompt", text: $password)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .fontDesign(.monospaced)
#else
                    TextField("Settings.debug.activate-alert.prompt", text: $password)
                        .autocorrectionDisabled()
                    //                        .textInputSuggestions(nil)
                        .fontDesign(.monospaced)
#endif
                    Button(action: {
                        if password == correctDebugPassword {
                            lastDebugPassword = password
                            AppFlag.set(true, forKey: "DEBUG")
                            showDebugVerificationAlert = false
                            showDebugUnlockAlert = true
                        }
                        password = ""
                    }, label: {
                        Text("Settings.debug.activate-alert.confirm")
                    })
                    .keyboardShortcut(.defaultAction)
                    Button(role: .cancel, action: {}, label: {
                        Text("Settings.debug.activate-alert.cancel")
                    })
                }, message: {
                    Text("Settings.debug.activate-alert.message")
                })
                .alert("Settings.debug.activate-alert.succeed", isPresented: $showDebugUnlockAlert, actions: {})
            NavigationLink(destination: {
                SettingsAdvancedView()
            }, label: {
                Text("Settings.advanced")
            })
        }, header: {
            Text("Settings.about")
        })
    }
}
 */

enum DataSourcePreference: String, CaseIterable {
    case useInternet
    case hybrid
    case useLocal
}





