//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsStoryView.swift
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

struct SettingsStoryView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject private var fontManager = FontManager.shared
    @AppStorage("ISVStyleTestFlag") var isvStyleTestFlag = 0
    @AppStorage("ISVAlwaysFullScreen") var isvAlwaysFullScreen = false
    @State var storyViewerFonts: [DoriLocale: String] = [:]
    @State var storyViewerUpdateIndex: Int = 0
    var body: some View {
        Group {
            if isvStyleTestFlag > 0 { // See the initializer in AppDelegate
                Section(content: {
                    HStack {
                        Spacer()
                        Image("LayoutDemo-\(isvAlwaysFullScreen ? "F" : "P")-\(colorScheme == .dark ? "D" : "L")")
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .animation(.easeInOut, value: isvAlwaysFullScreen)
                        Spacer()
                    }
                    
                    Picker("Settings.story-viewer.layout", selection: $isvAlwaysFullScreen) {
                        ForEach(isvStyleTestFlag == 2 ? [true, false] : [false, true], id: \.self) { item in
                            VStack(alignment: .leading) {
                                Text(item ? "Settings.story-viewer.layout.always-full-screen" : "Settings.story-viewer.layout.resizable")
                                Text(item ? "Settings.story-viewer.layout.always-full-screen.description" : "Settings.story-viewer.layout.resizable.description")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(item)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.inline)
                    .onChange(of: isvAlwaysFullScreen) {
                        Task {
                            await submitStats(
                                key: "ISVPreferAlwaysFullScreen",
                                action: isvAlwaysFullScreen
                            )
                        }
                        Task {
                            await submitStats(
                                key: "ISVPreferPreviewable",
                                action: !isvAlwaysFullScreen
                            )
                        }
                    }
                }, header: {
                    Text("Settings.story-viewer.layout")
                })
            }
            
            Section(content: {
                ForEach(DoriLocale.allCases, id: \.self) { locale in
                    NavigationLink(destination: {
                        SettingsFontsPicker(externalUpdateIndex: $storyViewerUpdateIndex, locale: locale)
                    }, label: {
                        HStack {
                            Text("\(locale.rawValue.uppercased())")
                            Spacer()
                            Text(fontManager.getUserFriendlyFontDisplayName(forFontName: storyViewerFonts[locale] ?? "") ?? (storyViewerFonts[locale] ?? ""))
                                .foregroundStyle(.secondary)
                        }
                    })
                }
                if !isMACOS {
                    SettingsDocumentButton(document: "FontSuggestions") {
                        Text("Settings.fonts.learn-more")
                    }
                }
            }, header: {
                Text("Settings.story-viewer.fonts")
            }, footer: {
                if isMACOS {
                    SettingsDocumentButton(document: "FontSuggestions") {
                        Text("Settings.fonts.learn-more")
                    }
                }
            })
            .onChange(of: storyViewerUpdateIndex, initial: true) {
                for locale in DoriLocale.allCases {
                    storyViewerFonts.updateValue(UserDefaults.standard.string(forKey: "StoryViewerFont\(locale.rawValue.uppercased())") ?? storyViewerDefaultFont[locale] ?? ".AppleSystemUIFont", forKey: locale)
                }
            }
        }
        .navigationTitle("Settings.story-viewer")
    }
}
