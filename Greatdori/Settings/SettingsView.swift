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
import SymbolAvailability

let birthdayTimeZoneNameDict: [BirthdayTimeZone: LocalizedStringResource] = [.adaptive: "Settings.birthday-time-zone.name.adaptive", .JST: "Settings.birthday-time-zone.name.JST", .UTC: "Settings.birthday-time-zone.name.UTC", .CST: "Settings.birthday-time-zone.name.CST", .PT: "Settings.birthday-time-zone.name.PT"]
let showBirthdayDateDefaultValue = 1

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.horizontalSizeClass) var sizeClass
    @State var selectionItem: String = "locale"
    var usedAsSheet: Bool = false
    
    var body: some View {
        #if !os(macOS)
        NavigationStack {
            Form {
                ForEach(settingsTabs, id: \.self) { item in
                    if item.isDisplayable {
                        NavigationLink(destination: {
                            settingsDestination(forTab: item.destination, note: item.note ?? "")
                                .navigationBarTitleDisplayMode(.inline)
                        }, label: {
                            Label(item.name, systemImage: item.symbol)
                                .tag(item.destination)
                        })
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Settings")
            .wrapIf(usedAsSheet, in: { content in
                content
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            DismissButton(action: dismiss.callAsFunction) {
                                Image(systemName: .xmark)
                            }
                        }
                    }
            })
        }
        #else
        NavigationSplitView(sidebar: {
            List(selection: $selectionItem, content: {
                ForEach(settingsTabs, id: \.self) { item in
                    if item.isDisplayable {
                        Label(item.name, systemImage: item.symbol)
                            .tag(item.destination)
                    }
                }
            })
//            .toolbar(removing: .sidebarToggle)
        }, detail: {
            NavigationStack {
                settingsDestination(forTab: selectionItem, note: settingsTabs.first(where: { $0.destination == selectionItem })?.note ?? "")
            }
        })
        //        .toolbar(removing: .sidebarToggle)
        #endif
    }
    
    @ViewBuilder
    func settingsDestination(forTab tab: String, note: String) -> some View {
        Group {
            switch tab {
            case "locale":
                SettingsLocaleView()
            case "home":
                SettingsHomeView()
            case "story":
                SettingsStoryView()
            case "permission":
                SettingsPermissionsView()
            case "widget":
                if #available(visionOS 26.0, *) {
                    SettingsWidgetsView()
                }
            case "font":
                SettingsFontsView()
            case "account":
                SettingsAccountsView()
            case "advanced":
                SettingsAdvancedView()
            case "about":
                SettingsAboutView()
            case "debug":
                SettingsDebugView()
            default:
                ProgressView()
            }
        }
        .wrapIf(note != "NO-FORM") { content in
            Form {
                content
            }
            .formStyle(.grouped)
        }
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

enum DataSourcePreference: String, CaseIterable {
    case useInternet
    case hybrid
    case useLocal
}

struct SettingsTab: Hashable {
    var symbol: String
    var name: LocalizedStringResource
    var destination: String
    var note: String?
    
    var isDisplayable: Bool {
        !((self.note == "DEBUG" && !AppFlag.DEBUG) || (self.note == "HIDDEN"))
    }
}

let settingsTabs: [SettingsTab] = [
    .init(symbol: "globe", name: "Settings.locale", destination: "locale"),
    .init(symbol: "rectangle.3.group", name: "Settings.home-edit", destination: "home"),
    .init(symbol: "books.vertical", name: "Settings.story-viewer", destination: "story"),
    .init(symbol: "bell.badge", name: "Settings.permissions", destination: "permission"),
    {
        if #available(visionOS 26.0, *) {
            .init(symbol: "widget.small", name: "Settings.widgets", destination: "widget")
        } else {
            nil
        }
    }(),
    .init(symbol: "person.crop.circle", name: "Settings.account", destination: "account", note: "NO-FORM"),
    .init(symbol: "textformat", name: "Settings.fonts", destination: "font", note: "NO-FORM"),
    .init(symbol: "hammer", name: "Settings.advanced", destination: "advanced"),
    .init(symbol: "info.circle", name: "Settings.about", destination: "about", note: "NO-FORM"),
    .init(symbol: "ant", name: "Settings.debug", destination: "debug", note: "DEBUG")
].compactMap { $0 }
