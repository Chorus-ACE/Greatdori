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

//struct SettingsAboutView: View {
//    var body: some View {
////#if os(iOS)
////        Section(content: {
////            NavigationLink(destination: {
////                SettingsAboutDetailView()
////            }, label: {
////                Text("Settings.about.about-greatdori")
////            })
////            NavigationLink(destination: {
////                SettingsAdvancedView()
////            }, label: {
////                Text("Settings.advanced")
////            })
////        }, header: {
////            Text(verbatim: "Greatdori!")
////        })
////#else
//        SettingsAboutDetailView()
////#endif
//    }
//}

struct SettingsAboutView: View {
    var body: some View {
        Group {
#if os(iOS)
//            List {
                HStack {
                    Spacer()
                    SettingsAboutDetailIconView()
                    Spacer()
                }
                .listRowBackground(Color.clear)
                Section {
                    SettingsAboutDetailListView()
                }
//            }
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
    @State var showDebugDeactivateAlert = false
    @State var password = ""
    @State var showDebugUnlockAlert = false
    @AppStorage("lastDebugPassword") var lastDebugPassword = ""
    @Environment(\.colorScheme) var colorScheme
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
    let appIconSideLength: CGFloat = isMACOS ? 80 : 100
    var body: some View {
        VStack {
            Image(decorative: "MacAppIcon\(colorScheme == .dark ? "Dark" : "")")
                .resizable()
                .frame(width: appIconSideLength, height: appIconSideLength)
            Text(verbatim: "Greatdori!")
                .bold()
                .font(.largeTitle)
            Group {
                if AppFlag.DEBUG {
                    Text("Settings.about.version.\(appVersion)") + Text(verbatim: " - ") + Text(verbatim: "DEBUG")
                } else if isComplyingWithAppStore {
                    Text("Settings.about.version.\(appVersion)") + Text(verbatim: " - ") + Text(verbatim: "App Store")
                } else {
                    Text("Settings.about.version.\(appVersion)")
                }
            }
            .foregroundStyle(.secondary)
            .font(.title3)
            .onTapGesture(count: 3) {
                if !AppFlag.DEBUG {
                    showDebugVerificationAlert = true
                } else {
                    showDebugDeactivateAlert = true
                }
            }
            .alert("Settings.debug.activate-alert.title", isPresented: $showDebugVerificationAlert) {
                #if os(iOS)
                TextField("Settings.debug.activate-alert.prompt", text: $password)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .fontDesign(.monospaced)
                #else
                TextField("Settings.debug.activate-alert.prompt", text: $password)
                    .autocorrectionDisabled()
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
            } message: {
                Text("Settings.debug.activate-alert.message")
            }
            .alert("Settings.debug.activate-alert.succeed", isPresented: $showDebugUnlockAlert) {}
            .alert("Settings.debug.deactivate-alert.title", isPresented: $showDebugDeactivateAlert) {
                Button("Settings.debug.deactivate-alert.confirm") {
                    AppFlag.set(false, forKey: "DEBUG")
                }
                .keyboardShortcut(.defaultAction)
                Button("Settings.debug.deactivate-alert.cancel") {}
            } message: {
                Text("Settings.debug.deactivate-alert.prompt")
            }
        }
    }
}

struct SettingsAboutDetailListView: View {
    @Environment(\.locale) private var locale
    var body: some View {
        Text(verbatim: "Licensed under Apache License 2.0")
        Link(destination: URL(string: "https://github.com/Greatdori")!) {
            HStack {
                Text("Settings.about.github")
                Spacer()
                Image(systemName: "arrow.up.forward.app")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .foregroundStyle(.primary)
        Link(destination: URL(string: "https://github.com/Greatdori/Greatdori/issues")!) {
            HStack {
                Text("Settings.about.report-a-problem")
                Spacer()
                Image(systemName: "arrow.up.forward.app")
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
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
                Text("Settings.about.privacy-policy")
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
        if locale.identifier == "zh-CN" {
            Link(destination: URL(string: "https://beian.miit.gov.cn")!) {
                HStack {
                    Text(verbatim: "蜀ICP备2025125473号-17A")
                    Spacer()
                    Image(systemName: "arrow.up.forward.app")
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .foregroundStyle(.primary)
        }
    }
}

struct SettingsAboutAcknowledgementsView: View {
    var body: some View {
        Form {
            Section {
                ForEach(getAcknowledgements(), id: \.self) { item in
                    SettingsAboutAcknowledgementItem(type: .package, item: item)
                }
            } header: {
                Text("Settings.about.acknowledgements.packages")
            }
            Section {
                ForEach(codeSnippetsAck, id: \.self) { item in
                    SettingsAboutAcknowledgementItem(type: .codeSnippet, item: item)
                }
            } header: {
                Text("Settings.about.acknowledgements.code-snippets")
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
            .accessibilityElement(children: .combine)
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
    var notes: String? = nil
}
