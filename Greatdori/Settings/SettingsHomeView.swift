//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsHomeView.swift
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

struct SettingsHomeView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @AppStorage("showBirthdayDate") var showBirthdayDate = showBirthdayDateDefaultValue
    let showCurrentDayPickerDescription: [Int: LocalizedStringKey] = [3: "Home.home.show-current-date.selection.always.description", 2: "Home.home.show-current-date.selection.during-birthday.description", 1: "Home.home.show-current-date.selection.automatic.description", 0: "Home.home.show-current-date.selection.never.description"]
    var body: some View {
        #if os(iOS)
        Section(content: {
            HomeEditEventsPicker(id: 1)
            HomeEditEventsPicker(id: 2)
            HomeEditEventsPicker(id: 3)
            HomeEditEventsPicker(id: 4)
            SettingsHomeShowTodayBirthdayPicker()
        }, header: {
            Text("Settings.home-edit")
        }, footer: {
            Text(sizeClass == .compact ? "Settings.home-edit.footer.compact" : "Settings.home-edit.footer")
        })
#else
        Group {
            Section(content: {
                HomeEditEventsPicker(id: 1)
                HomeEditEventsPicker(id: 2)
                HomeEditEventsPicker(id: 3)
                HomeEditEventsPicker(id: 4)
            }, footer: {
                Text("Settings.home-edit.footer")
            })
            Section(content: {
                SettingsHomeShowTodayBirthdayPicker()
            }, footer: {
                Text(showCurrentDayPickerDescription[showBirthdayDate]!)
            })
        }
        .navigationTitle("Settings.home-edit")
        #endif
    }
    
    struct HomeEditEventsPicker: View {
        @AppStorage("homeEventServer1") var homeEventServer1 = "jp"
        @AppStorage("homeEventServer2") var homeEventServer2 = "cn"
        @AppStorage("homeEventServer3") var homeEventServer3 = "tw"
        @AppStorage("homeEventServer4") var homeEventServer4 = "en"
        var id: Int = 1
        init(id: Int = 1) {
            self.id = id
        }
        var body: some View {
            Picker(selection: (id == 1) ? $homeEventServer1 : ((id == 2) ? $homeEventServer2 : ((id == 3) ? $homeEventServer3 : $homeEventServer4)), content: {
                Text("Home.servers.selection.jp")
                    .tag("jp")
                Text("Home.servers.selection.en")
                    .tag("en")
                Text("Home.servers.selection.cn")
                    .tag("cn")
                Text("Home.servers.selection.tw")
                    .tag("tw")
            }, label: {
                Text("Home.servers.slot.\(id)")
            })
        }
    }
    
    struct SettingsHomeShowTodayBirthdayPicker: View {
        @AppStorage("showBirthdayDate") var showBirthdayDate = showBirthdayDateDefaultValue
        let showCurrentDayPickerLabel: [Int: LocalizedStringKey] = [3: "Home.home.show-current-date.selection.always", 2: "Home.home.show-current-date.selection.during-birthday", 1: "Home.home.show-current-date.selection.automatic", 0: "Home.home.show-current-date.selection.never"]
        let showCurrentDayPickerDescription: [Int: LocalizedStringKey] = [3: "Home.home.show-current-date.selection.always.description", 2: "Home.home.show-current-date.selection.during-birthday.description", 1: "Home.home.show-current-date.selection.automatic.description", 0: "Home.home.show-current-date.selection.never.description"]
        
        var body: some View {
            Picker(selection: $showBirthdayDate, content: {
                ForEach([3, 2, 1, 0], id: \.self) { index in
                    VStack(alignment: .leading) {
                        Text(showCurrentDayPickerLabel[index]!)
                        Text(showCurrentDayPickerDescription[index]!)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .tag(index)
                }
            }, label: {
                Text("Home.home.show-current-date")
            }, optionalCurrentValueLabel: {
                Text(showCurrentDayPickerLabel[showBirthdayDate]!)
                    .multilineTextAlignment(.trailing)
            })
            .wrapIf(!isMACOS, in: { content in
#if os(iOS)
                content
                    .pickerStyle(.navigationLink)
#endif
            })
        }
    }
}
