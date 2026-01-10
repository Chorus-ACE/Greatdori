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
    var hasSelectedLayout: Binding<Bool>?
    @StateObject private var fontManager = FontManager.shared
    @AppStorage("ISVStyleTestFlag") private var isvStyleTestFlag = 0
    @AppStorage("ISVAlwaysFullScreen") private var isvAlwaysFullScreen = false
    @State private var selectedLayout: Bool? // isFullScreen
    @State private var storyViewerFonts: [DoriLocale: String] = [:]
    @State private var storyViewerUpdateIndex: Int = 0
    @State private var demoHeight: CGFloat = 400
    @State private var isDemoRotated = false
    @State private var isDemoTouchPressed = false
    @State private var isDemoTouchVisible = true
    @State private var isDemoReplayAvailable = false
    var body: some View {
        Group {
            if isvStyleTestFlag > 0 { // See the initializer in AppDelegate
                Section(content: {
                    ZStack(alignment: .topTrailing) {
                        HStack {
                            Spacer()
                            ZStack(alignment: .topTrailing) {
                                Image("LayoutDemo-\(isDemoRotated ? "Rotated" : isvAlwaysFullScreen ? "FullScreen" : "Previewable")")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: demoHeight)
                                    .mask(alignment: .top) {
                                        if !isDemoRotated {
                                            Rectangle()
                                                .frame(height: demoHeight / 4 * 3)
                                        } else {
                                            Rectangle()
                                        }
                                    }
                                    .rotationEffect(.degrees(isDemoRotated ? -90 : 0))
                                    .padding(.bottom, -demoHeight / 4)
                                    .offset(y: isDemoRotated ? -demoHeight / 8 : 0)
                                    .animation(.easeInOut, value: isvAlwaysFullScreen)
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.5))
                                        .frame(width: demoHeight / 16 * (isDemoTouchPressed ? 0.8 : 1), height: demoHeight / 16 * (isDemoTouchPressed ? 0.8 : 1))
                                    Circle()
                                        .fill(Color.white.opacity(0.5))
                                        .frame(width: demoHeight / 16 * 0.8 * (isDemoTouchPressed ? 0.8 : 1), height: demoHeight / 16 * 0.8 * (isDemoTouchPressed ? 0.8 : 1))
                                }
                                .frame(width: demoHeight / 16, height: demoHeight / 16)
                                .padding(demoHeight / 17)
                                .padding(.vertical, demoHeight / 27)
                                .opacity(isDemoTouchVisible ? 1 : 0)
                            }
                            Spacer()
                        }
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            min(proxy.size.width, 400)
                        } action: { newValue in
                            demoHeight = newValue
                        }

                        if isDemoReplayAvailable {
                            Button("Settings.story-viewer.demo.replay", systemImage: "arrow.clockwise") {
                                playDemoAnimation()
                            }
                            .wrapIf(true) { content in
                                if #available(iOS 26.0, macOS 26.0, *) {
                                    content
                                        .buttonStyle(.glass)
                                } else {
                                    content
                                        .buttonStyle(.bordered)
                                }
                            }
                        }
                    }
                    .onAppear {
                        playDemoAnimation()
                    }
                    
                    Picker("Settings.story-viewer.layout", selection: $selectedLayout) {
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
                    .onAppear {
                        if _fastPath(hasSelectedLayout == nil) {
                            selectedLayout = isvAlwaysFullScreen
                        }
                    }
                    .onChange(of: selectedLayout) {
                        if let selectedLayout {
                            isvAlwaysFullScreen = selectedLayout
                            hasSelectedLayout?.wrappedValue = true
                        }
                    }
                    .onChange(of: isvAlwaysFullScreen) {
                        playDemoAnimation()
                        Task {
                            await submitStats(
                                key: "ISVPreferAlwaysFullScreen2",
                                action: isvAlwaysFullScreen
                            )
                        }
                        Task {
                            await submitStats(
                                key: "ISVPreferPreviewable2",
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
    
    private func playDemoAnimation() {
        func doAnimation() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                    isDemoTouchPressed = true
                } completion: {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                            isDemoTouchPressed = false
                        } completion: {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                withAnimation {
                                    isDemoRotated = true
                                    isDemoTouchVisible = false
                                } completion: {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        withAnimation {
                                            isDemoRotated = false
                                            isDemoReplayAvailable = true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        isDemoTouchPressed = false
        isDemoTouchVisible = true
        isDemoReplayAvailable = false
        if isDemoRotated {
            withAnimation(.spring(duration: 0.2, bounce: 0.2)) {
                isDemoRotated = false
            } completion: {
                doAnimation()
            }
        } else {
            doAnimation()
        }
    }
}
