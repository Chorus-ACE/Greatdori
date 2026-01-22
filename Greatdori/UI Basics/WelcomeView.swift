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
import SymbolAvailability

// MARK: ようこそ、Greatdori!の世界へ
struct WelcomeView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    @AppStorage("isFirstLaunchResettable") var isFirstLaunchResettable = true
    
    @Binding var showWelcomeScreen: Bool
    @Binding var isSafeExit: Bool
    
    @State var primaryLocale = DoriLocale.primaryLocale
    @State var secondaryLocale = DoriLocale.secondaryLocale
    @State var isLicenseAgreementPresented = false
    @State var sheetIsHorizontallyCompact = true
    @State var agreementPromptHadBeenDisplayed = false
    @State var agreementAlertIsDisplaying = false
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
                    LocalePicker($primaryLocale) {
                        Text("Welcome.primary-locale")
                    }
                    .onChange(of: primaryLocale, { oldValue, newValue in
                        if newValue == DoriLocale.secondaryLocale {
                            DoriLocale.secondaryLocale = oldValue
                            secondaryLocale = DoriLocale.secondaryLocale
                        }
                        DoriLocale.primaryLocale = newValue
                    })
                    
                    LocalePicker($secondaryLocale) {
                        Text("Welcome.secondary-locale")
                    }
                    .onChange(of: secondaryLocale, { oldValue, newValue in
                        if newValue == DoriLocale.primaryLocale {
                            DoriLocale.primaryLocale = oldValue
                            primaryLocale = DoriLocale.primaryLocale
                        }
                        DoriLocale.secondaryLocale = newValue
                    })
                }, footer: {
                    WelcomeViewAgreementPrompt(isLicenseAgreementPresented: $isLicenseAgreementPresented)
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
                    proceed(ignoreDisplayingCondition: true)
                }, label: {
                    Text("Welcome.agree-done")
                })
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
        #else
        NavigationStack {
            ZStack {
                ScrollView {
                    LazyVStack {
                        // MARK: Pentagonal View
                        ZStack {
                            Image("MacAppIcon\(colorScheme == .dark ? "Dark" : "")")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .shadow(radius: 6, x: 1, y: 1)
                            ForEach(configuration, id: \.self) { configuration in
                                Image(fallingSystemName: configuration.systemName)
                                    .font(.system(size: configuration.size))
                                    .foregroundStyle(
                                        configuration.color,
                                        configuration.color.opacity(0.7),
                                        configuration.color.opacity(0.5)
                                    )
                                    .offset(configuration.offset)
                            }
                        }
                        .padding(.horizontal, 120)
                        .padding(.top, sheetIsHorizontallyCompact ? 100 : 120)
                        .padding(.bottom, 140)
                        
                        // MARK: Main Text
                        Group {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Welcome.title")
                                        .font(.system(size: 20, weight: .bold))
                                    Text("Welcome.message")
                                        .font(.system(size: 20))
                                        .foregroundStyle(.gray)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                        
                        
                        Section(content: {
                            // MARK: Form
                            Group {
                                VStack(spacing: 7) {
                                    ListItem(title: {
                                        Text("Welcome.primary-locale")
                                    }, value: {
                                        LocalePicker($primaryLocale)
                                            .onChange(of: primaryLocale, { oldValue, newValue in
                                                if newValue == DoriLocale.secondaryLocale {
                                                    DoriLocale.secondaryLocale = oldValue
                                                    secondaryLocale = DoriLocale.secondaryLocale
                                                }
                                                DoriLocale.primaryLocale = newValue
                                            })
                                    })
                                    
                                    Divider()
                                    
                                    ListItem(title: {
                                        Text("Welcome.secondary-locale")
                                    }, value: {
                                        LocalePicker($secondaryLocale)
                                            .onChange(of: secondaryLocale, { oldValue, newValue in
                                                if newValue == DoriLocale.primaryLocale {
                                                    DoriLocale.primaryLocale = oldValue
                                                    primaryLocale = DoriLocale.primaryLocale
                                                }
                                                DoriLocale.secondaryLocale = newValue
                                            })
                                    })
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(colorScheme == .light && (sizeClass == .regular && platform == .iOS) ? Color(.systemGroupedBackground) : Color(.secondarySystemGroupedBackground))
                            }
                        }, footer: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Welcome.footnote")
                                    
                                    if sheetIsHorizontallyCompact {
                                        WelcomeViewAgreementPrompt(isLicenseAgreementPresented: $isLicenseAgreementPresented, isCheckmarkButton: true)
                                            .wrapIf(true) {
                                                if #available(iOS 18.0, *) {
                                                    $0.onScrollVisibilityChange(threshold: 0.7) { isVisible in
                                                        if isVisible {
                                                            agreementPromptHadBeenDisplayed = true
                                                        }
                                                    }
                                                } else {
                                                    $0
                                                }
                                            }
                                    }
                                }
                                Spacer()
                            }
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal)
                        })
                        
                    }
                    .padding()
                }
                
                if !sheetIsHorizontallyCompact {
                    // MARK: Confirmation Button
                    VStack {
                        Spacer()
                        WelcomeViewAgreementPrompt(isLicenseAgreementPresented: $isLicenseAgreementPresented)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .onAppear {
                                agreementPromptHadBeenDisplayed = true
                            }
                        Button(action: {
                            proceed()
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
                    .padding()
                }
            }
            .toolbar {
                if sheetIsHorizontallyCompact {
                    Button(optionalRole: .confirm, action: {
                        proceed()
                    }, label: {
                        Label("Welcome.agree-done", systemImage: "checkmark")
                            .foregroundStyle(.white)
                            .fontWeight(.semibold)
                    })
                }
            }
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
                                Image(systemName: .xmark)
                            })
                        }
                    }
            }
        }
        .alert("Welcome.agreement-sheet.title", isPresented: $agreementAlertIsDisplaying, actions: {
            Button(action: {
                proceed(ignoreDisplayingCondition: true)
            }, label: {
                Text("Welcome.agreement-sheet.agree")
            })
            .keyboardShortcut(.defaultAction)
            Button(role: .cancel, action: {}, label: {
                Text("Welcome.agreement-sheet.cancel")
            })
            Button(action: {
                isLicenseAgreementPresented = true
            }, label: {
                Text("Welcome.agreement-sheet.check-license")
            })
        }, message: {
            Text("Welcome.agreement-sheet.message")
        })
        .onFrameChange { geometry in
            sheetIsHorizontallyCompact = geometry.size.height < 750
        }
        #endif
    }
    
    func proceed(ignoreDisplayingCondition: Bool = false) {
        if agreementPromptHadBeenDisplayed || ignoreDisplayingCondition {
            isSafeExit = true
            dismiss()
        } else {
            agreementAlertIsDisplaying = true
        }
    }
    
    private struct WelcomeViewAgreementPrompt: View {
        @Binding var isLicenseAgreementPresented: Bool
        var isCheckmarkButton: Bool = false
        
        var body: some View {
            Text(getActiveAttributeString(isCheckmarkButton: isCheckmarkButton))
//                .font(.footnote)
//                .foregroundStyle(.secondary)
                .environment(\.openURL, OpenURLAction { url in
                    if url.absoluteString == "placeholder://license-agreement" {
                        isLicenseAgreementPresented = true
                        return .handled
                    } else {
                        return .systemAction
                    }
                })
//                .multilineTextAlignment(.center)
//                .onAppear {
//                    agreementPromptHadBeenDisplayed = true
//                }
        }
        
        func getActiveAttributeString(isCheckmarkButton: Bool) -> AttributedString {
            var text = try! AttributedString(markdown: String(localized: self.isCheckmarkButton ? "Welcome.agreement-prompt.checkmark" : "Welcome.agreement-prompt"))
            for run in text.runs {
                if run.attributes.link != nil {
                    text[run.range].foregroundColor = .accent
                }
            }
            return text
        }
    }
}

private struct AppIconWrappingFeatureImageConfiguration: Hashable {
    let systemName: String
    let color: Color
    let size: CGFloat
    let offset: CGSize
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(systemName)
        hasher.combine(color)
        hasher.combine(size)
        hasher.combine(offset.width)
        hasher.combine(offset.height)
    }
}

fileprivate let configuration: [AppIconWrappingFeatureImageConfiguration] = [
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
    .init(systemName: "dice",
          color: .yellow,
          size: 28,
          offset: .init(width: 0, height: 75)),
    .init(systemName: "music.note",
          color: .red,
          size: 20,
          offset: .init(width: 0, height: 140)),
    .init(systemName: "flag.2.crossed.fill",
          color: .green,
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
          color: .green,
          size: 20,
          offset: .init(width: -110, height: -40)),
    .init(systemName: "apple.classical.pages.fill",
          color: .red,
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

struct WelcomeCapsuleText: View {
    var text: any StringProtocol
    var body: some View {
        ZStack {
            Capsule()
            Text(text)
                .padding()
        }
    }
}
