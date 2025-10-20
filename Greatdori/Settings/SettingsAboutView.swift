//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsAboutView.swift
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

import SwiftUI

struct SettingsAboutView: View {
    var body: some View {
#if os(iOS)
        Section(content: {
            NavigationLink(destination: {
                SettingsAboutDetailView()
            }, label: {
                Text("Settings.about.about-greatdori")
            })
            NavigationLink(destination: {
                SettingsAdvancedView()
            }, label: {
                Text("Settings.advanced")
            })
        }, header: {
            Text(verbatim: "Greatdori!")
        })
#else
        SettingsAboutDetailView()
#endif
    }
}

struct SettingsAboutDetailView: View {
    var body: some View {
        Group {
#if os(iOS)
            List {
                HStack {
                    Spacer()
                    SettingsAboutDetailIconView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
                Section {
                    SettingsAboutDetailListView()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
#else
            ScrollView {
                VStack {
                    SettingsAboutDetailIconView()
                        .listRowBackground(Color.clear)
                    Form {
//                        Section {
                            SettingsAboutDetailListView()
//                        }
                    }
                    .formStyle(.grouped)
                    .scrollDisabled(true)
                }
                .padding()
            }
#endif
        }
        .navigationTitle("Settings.about")
        .withSystemBackground()
    }
}

struct SettingsAboutDetailIconView: View {
    @State var showDebugVerificationAlert = false
    @State var password = ""
    @State var showDebugUnlockAlert = false
    @AppStorage("lastDebugPassword") var lastDebugPassword = ""
    @Environment(\.colorScheme) var colorScheme
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    let appIconSideLength: CGFloat = isMACOS ? 80 : 100
    var body: some View {
        VStack {
            Image("MacAppIcon\(colorScheme == .dark ? "Dark" : "")")
                .resizable()
                .frame(width: appIconSideLength, height: appIconSideLength)
            Text(verbatim: "Greatdori!")
                .bold()
                .font(.largeTitle)
            Text("Settings.about.version.\(appVersion)")
                .foregroundStyle(.secondary)
                .font(.title3)
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
        }
    }
}

struct SettingsAboutDetailListView: View {
    var body: some View {
//        Group {
            NavigationLink(destination: {
                
            }, label: {
                Text("Settings.about.acknowledgements")
            })
//        }
    }
}
