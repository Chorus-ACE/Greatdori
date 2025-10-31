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

//MARK: WelcomeView
struct WelcomeView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @State var primaryLocale = "jp"
    @State var secondaryLocale = "en"
    @Binding var showWelcomeScreen: Bool
    var body: some View {
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
            Rectangle()
                .frame(height: 1)
                .opacity(0)
            Text("Welcome.message")
            Rectangle()
                .frame(height: 1)
                .opacity(0)
            HStack {
#if os(iOS)
                Text("Welcome.primaryLocale")
                Spacer()
#endif
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
            }
            HStack {
#if os(iOS)
                Text("Welcome.secondaryLocale")
                Spacer()
#endif
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
            }
            Rectangle()
                .frame(height: 1)
                .opacity(0)
            Text("Welcome.footnote")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
#if os(iOS)
            Button(action: {
                //ANIMATION?
                showWelcomeScreen = false
            }, label: {
                ZStack {
                    if #available(iOS 26.0, *) {
                        Capsule()
                            .frame(height: 50)
                            .glassEffect(.identity)
                    } else {
                        RoundedRectangle(cornerRadius: 50)
                            .frame(height: 20)
                    }
                    Text("Done")
                        .bold()
                        .foregroundStyle(colorScheme == .dark ? .black : .white)
                    //                        .colorInvert()
                }
            })
#endif
        }
        .padding()
        .onAppear {
            primaryLocale = DoriLocale.primaryLocale.rawValue
            secondaryLocale = DoriLocale.secondaryLocale.rawValue
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction, content: {
                Button(action: {
                    //ANIMATION?
                    //                    dismiss()
                    showWelcomeScreen = false
                }, label: {
                    Text("Done")
                })
                //                .background()
            })
        }
    }
}
