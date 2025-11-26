//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsAboutView.swift
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
            Group {
                if AppFlag.DEBUG {
                    Text("Settings.about.version.\(appVersion)") + Text(verbatim: " - ") + Text(verbatim: "DEBUG")
                } else {
                    Text("Settings.about.version.\(appVersion)")
                }
            }
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
        Text(verbatim: "Licensed under Apache License 2.0")
        Link(destination: URL(string: "https://github.com/Greatdori")!, label: {
            HStack {
                Text("Settings.about.github")
                Spacer()
                Image(systemName: "arrow.up.forward.app")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        })
        .foregroundStyle(.primary)
        SettingsDocumentButton(document: "T&C", preferNavigationLink: true) {
            HStack {
                Text("Settings.about.user-agreement-license")
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundStyle(.tertiary)
                    .font(.footnote)
                    .bold()
            }
        }
        .buttonStyle(.plain)
        SettingsDocumentButton(document: "Privacy", preferNavigationLink: true) {
            HStack {
                Text("Greatdori! and Privacy")
                Spacer()
                Image(systemName: "chevron.forward")
                    .foregroundStyle(.tertiary)
                    .font(.footnote)
                    .bold()
            }
        }
        .buttonStyle(.plain)
        NavigationLink(destination: {
            SettingsAboutAcknowledgementsView()
        }, label: {
            Text("Settings.about.acknowledgements")
        })
    }
}

struct SettingsAboutAcknowledgementsView: View {
    var body: some View {
        Form {
            Section {
                ForEach(acknowledgements, id: \.self) { item in
                    SettingsAboutAcknowledgementItem(type: .package, item: item)
                }
            } header: {
                Text("Packages")
            }
            Section {
                ForEach(codeSnippetsAck, id: \.self) { item in
                    SettingsAboutAcknowledgementItem(type: .codeSnippet, item: item)
                }
            } header: {
                Text("Code Snippets")
            } footer: {
                Text("Settings.about.acknowledgements.footer")
            }
        }
        .navigationTitle("Settings.about.acknowledgements")
        .formStyle(.grouped)
    }
    
    struct SettingsAboutAcknowledgementItem: View {
        var type: ItemType
        var item: AcknowledgementItem
        @State var isExpanded = false
        var body: some View {
            VStack {
                HStack {
                    Image(systemName: type == .package ? "shippingbox" : "ellipsis.curlybraces")
                        .foregroundStyle(type == .package ? .brown : .blue)
                        .font(.title3)
                    VStack(alignment: .leading) {
                        Text(item.title)
                        Text(item.subtitle)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.forward")
                        .foregroundStyle(.secondary)
                        .rotationEffect(Angle(degrees: isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    withAnimation(.spring(duration: 0.3, bounce: 0.1)) {
                        isExpanded.toggle()
                    }
                }
                if isExpanded {
                    Rectangle()
                        .frame(height: 1)
                        .opacity(0)
                    Text(item.licenseVerbatim)
                        .fontDesign(.monospaced)
                        .multilineTextAlignment(.leading)
                        .textSelection(.enabled)
                }
            }
        }
        
        enum ItemType {
            case package
            case codeSnippet
        }
    }
}

struct AcknowledgementItem: Equatable, Hashable {
    var title: String
    var subtitle: String
    var licenseVerbatim: String
}
