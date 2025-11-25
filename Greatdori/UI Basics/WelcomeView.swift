//===---*- Greatdori! -*---------------------------------------------------===//
//
// WelcomeView.swift
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

// MARK: ようこそ、Greatdori!の世界へ
struct WelcomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State var primaryLocale = DoriLocale.primaryLocale.rawValue
    @State var secondaryLocale = DoriLocale.secondaryLocale.rawValue
    @Binding var showWelcomeScreen: Bool
    @State var isLicenseAgreementPresented = false
    var body: some View {
        #if os(macOS)
        VStack(alignment: .leading) {
            Image("MacAppIcon\(colorScheme == .dark ? "Dark" : "")")
                .resizable()
                .antialiased(true)
                .frame(width: 64, height: 64)
            Rectangle()
                .frame(height: 1)
                .opacity(0)
            Text("Welcome.title")
                .font(.title)
                .bold()
                .padding(.bottom, 3)
            Text("Welcome.message")
            Rectangle()
                .frame(height: 5)
                .opacity(0)
            Form {
                Section(content: {
                    Picker(selection: $primaryLocale, content: {
                        Text("Home.servers.selection.jp")
                            .tag("jp")
                            .disabled(secondaryLocale == "jp")
                        Text("Home.servers.selection.en")
                            .tag("en")
                            .disabled(secondaryLocale == "en")
                        Text("Home.servers.selection.cn")
                            .tag("cn")
                            .disabled(secondaryLocale == "cn")
                        Text("Home.servers.selection.tw")
                            .tag("tw")
                            .disabled(secondaryLocale == "tw")
                        Text("Home.servers.selection.kr")
                            .tag("kr")
                            .disabled(secondaryLocale == "kr")
                    }, label: {
                        Text("Welcome.primaryLocale")
                    })
                    .onChange(of: primaryLocale, {
                        DoriLocale.primaryLocale = localeFromStringDict[primaryLocale] ?? .jp
                    })
                    Picker(selection: $secondaryLocale, content: {
                        Text("Home.servers.selection.jp")
                            .tag("jp")
                            .disabled(primaryLocale == "jp")
                        Text("Home.servers.selection.en")
                            .tag("en")
                            .disabled(primaryLocale == "en")
                        Text("Home.servers.selection.cn")
                            .tag("cn")
                            .disabled(primaryLocale == "cn")
                        Text("Home.servers.selection.tw")
                            .tag("tw")
                            .disabled(primaryLocale == "tw")
                        Text("Home.servers.selection.kr")
                            .tag("kr")
                            .disabled(primaryLocale == "kr")
                    }, label: {
                        Text("Welcome.secondaryLocale")
                    })
                    .onChange(of: secondaryLocale, {
                        DoriLocale.secondaryLocale = localeFromStringDict[secondaryLocale] ?? .en
                    })
                }, footer: {
                    Text(try! AttributedString(markdown: String(localized: "Welcome.agreement-prompt")))
                        .environment(\.openURL, OpenURLAction { url in
                            if url.absoluteString == "placeholder://license-agreement" {
                                isLicenseAgreementPresented = true
                                return .handled
                            } else {
                                return .systemAction
                            }
                        })
                })
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .padding(-20)
            Spacer()
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .confirmationAction, content: {
                Button(action: {
                    //ANIMATION?
                    //                    dismiss()
                    showWelcomeScreen = false
                }, label: {
                    Text("Welcome.agree-done")
                })
                //                .background()
            })
            ToolbarItem(placement: .destructiveAction) {
                Text("Welcome.footnote")
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $isLicenseAgreementPresented) {
            NavigationStack {
                SettingsDocumentButton<EmptyView>.SettingsDocumentView(document: "T&C")
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(action: {
                                isLicenseAgreementPresented = false
                            }, label: {
                                Text("Done")
                            })
                        }
                    }
            }
        }
        #else // os(macOS)
        NavigationStack {
            VStack {
                let configuration: [AppIconWrappingFeatureImageConfiguration] = [
                    .init(systemName: "person.2.fill",
                          color: .mint,
                          size: 28,
                          offset: .init(width: -40, height: -70)),
                    .init(systemName: "person.crop.square.on.square.angled.fill",
                          color: .orange,
                          size: 28,
                          offset: .init(width: 40, height: -70)),
                    .init(systemName: "swatchpalette.fill",
                          color: .blue,
                          size: 28,
                          offset: .init(width: -75, height: 20)),
                    .init(systemName: "star.hexagon.fill",
                          color: .green,
                          size: 28,
                          offset: .init(width: 80, height: 25)),
                    .init(systemName: "line.horizontal.star.fill.line.horizontal",
                          color: .yellow,
                          size: 28,
                          offset: .init(width: 0, height: 75)),
                    .init(systemName: "music.note",
                          color: .red,
                          size: 20,
                          offset: .init(width: 0, height: 140)),
                    .init(systemName: "music.note.list",
                          color: .pink,
                          size: 20,
                          offset: .init(width: -70, height: 100)),
                    .init(systemName: "calendar",
                          color: .cyan,
                          size: 20,
                          offset: .init(width: 70, height: 100)),
                    .init(systemName: "ticket.fill",
                          color: .indigo,
                          size: 20,
                          offset: .init(width: -130, height: 40)),
                    .init(systemName: "book.fill",
                          color: .brown,
                          size: 20,
                          offset: .init(width: 130, height: 50)),
                    .init(systemName: "chart.line.uptrend.xyaxis",
                          color: .blue,
                          size: 20,
                          offset: .init(width: -110, height: -40)),
                    .init(systemName: "apple.classical.pages.fill",
                          color: .green,
                          size: 22,
                          offset: .init(width: 110, height: -40)),
                    .init(systemName: "books.vertical.fill",
                          color: .brown,
                          size: 20,
                          offset: .init(width: -90, height: -110)),
                    .init(systemName: "person.and.viewfinder",
                          color: .mint,
                          size: 20,
                          offset: .init(width: 0, height: -120)),
                    .init(systemName: "folder.fill",
                          color: .cyan,
                          size: 20,
                          offset: .init(width: 90, height: -110))
                ]
                ZStack {
                    Image("MacAppIcon\(colorScheme == .dark ? "Dark" : "")")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .shadow(radius: 6, x: 1, y: 1)
                    ForEach(configuration, id: \.self) { configuration in
                        Image(_internalSystemName: configuration.systemName)
                            .font(.system(size: configuration.size))
                            .foregroundStyle(
                                configuration.color,
                                configuration.color.opacity(0.7),
                                configuration.color.opacity(0.5)
                            )
                            .offset(configuration.offset)
                    }
                }
                .padding(140)
                Group {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Welcome to Greatdori!")
                                .font(.system(size: 20, weight: .bold))
                            Text("This app brings BanG Dream GBP information together in one place.")
                                .font(.system(size: 20))
                                .foregroundStyle(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                            VStack {
                                HStack {
                                    Text("Welcome.primaryLocale")
                                    Spacer()
                                    Picker(selection: $primaryLocale) {
                                        Text("Home.servers.selection.jp")
                                            .tag("jp")
                                            .disabled(secondaryLocale == "jp")
                                        Text("Home.servers.selection.en")
                                            .tag("en")
                                            .disabled(secondaryLocale == "en")
                                        Text("Home.servers.selection.cn")
                                            .tag("cn")
                                            .disabled(secondaryLocale == "cn")
                                        Text("Home.servers.selection.tw")
                                            .tag("tw")
                                            .disabled(secondaryLocale == "tw")
                                        Text("Home.servers.selection.kr")
                                            .tag("kr")
                                            .disabled(secondaryLocale == "kr")
                                    } label: {
                                        EmptyView()
                                    }
                                    .labelsHidden()
                                    .onChange(of: primaryLocale) {
                                        DoriLocale.primaryLocale = localeFromStringDict[primaryLocale] ?? .jp
                                    }
                                }
                                Divider()
                                    .padding(.vertical, -3)
                                HStack {
                                    Text("Welcome.secondaryLocale")
                                    Spacer()
                                    Picker(selection: $secondaryLocale) {
                                        Text("Home.servers.selection.jp")
                                            .tag("jp")
                                            .disabled(primaryLocale == "jp")
                                        Text("Home.servers.selection.en")
                                            .tag("en")
                                            .disabled(primaryLocale == "en")
                                        Text("Home.servers.selection.cn")
                                            .tag("cn")
                                            .disabled(primaryLocale == "cn")
                                        Text("Home.servers.selection.tw")
                                            .tag("tw")
                                            .disabled(primaryLocale == "tw")
                                        Text("Home.servers.selection.kr")
                                            .tag("kr")
                                            .disabled(primaryLocale == "kr")
                                    } label: {
                                        EmptyView()
                                    }
                                    .labelsHidden()
                                    .onChange(of: secondaryLocale) {
                                        DoriLocale.secondaryLocale = localeFromStringDict[secondaryLocale] ?? .en
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color(.systemGroupedBackground))
                            }
                            Text(try! AttributedString(markdown: String(localized: "Welcome.agreement-prompt")))
                                .font(.footnote)
                                .foregroundStyle(.gray)
                                .fixedSize(horizontal: false, vertical: true)
                                .environment(\.openURL, OpenURLAction { url in
                                    if url.absoluteString == "placeholder://license-agreement" {
                                        isLicenseAgreementPresented = true
                                        return .handled
                                    } else {
                                        return .systemAction
                                    }
                                })
                        }
                        Spacer()
                    }
                    Spacer()
                    Button(action: {
                        showWelcomeScreen = false
                    }, label: {
                        HStack {
                            Spacer()
                            Text("Welcome.agree-done")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                    })
                    .wrapIf(true) { content in
                        if #available(iOS 26.0, *) {
                            content
                                .buttonStyle(.glassProminent)
                        } else {
                            content.buttonStyle(.borderedProminent)
                        }
                    }
                    .buttonBorderShape(.capsule)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .interactiveDismissDisabled()
        .sheet(isPresented: $isLicenseAgreementPresented) {
            NavigationStack {
                SettingsDocumentButton<EmptyView>.SettingsDocumentView(document: "T&C")
                    .toolbar {
                        ToolbarItem {
                            Button(action: {
                                isLicenseAgreementPresented = false
                            }, label: {
                                Image(systemName: "xmark")
                            })
                        }
                    }
            }
        }
        #endif // os(macOS)
    }
}

private struct AppIconWrappingFeatureImageConfiguration: Hashable {
    let systemName: String
    let color: Color
    let size: CGFloat
    let offset: CGSize
}
