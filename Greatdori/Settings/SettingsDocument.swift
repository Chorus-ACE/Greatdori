//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsDocument.swift
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

import MarkdownUI
import SwiftUI


struct SettingsDocumentButton<L: View>: View {
    var document: String
    var preferNavigationLink: Bool = false
    var label: () -> L
    @State var sheetIsDisplayed = false
    @State var navigationLinkIsEntered = false
    var body: some View {
        Button(action: {
            if preferNavigationLink {
                navigationLinkIsEntered = true
            } else {
                sheetIsDisplayed = true
            }
        }, label: {
//            Text(label)
            label()
        })
        .navigationDestination(isPresented: $navigationLinkIsEntered, destination: {
            SettingsDocumentView(document: document)
        })
        .sheet(isPresented: $sheetIsDisplayed, content: {
            NavigationStack {
                SettingsDocumentView(document: document)
                    .toolbar {
                        #if os(macOS)
                        ToolbarItem(placement: .cancellationAction) {
                            DismissButton {
                                Text("Settings.document.close")
                            }
                        }
                        #else
                        ToolbarItem(placement: .topBarTrailing) {
                            Label("Settings.document.close", systemImage: "xmark")
                        }
                        #endif
                    }
            }
        })
    }
    
    struct SettingsDocumentView: View {
        var document: String
        var body: some View {
            Group {
                if let markdownContent = readMarkdownFile(document) {
                    ScrollView {
                        Markdown(markdownContent)
                            .padding()
                            .textSelection(.enabled)
                    }
                } else {
                    ExtendedConstraints {
                        ContentUnavailableView("Settings.document.unavailable", systemImage: "questionmark.circle")
                    }
                }
            }
        }
    }
}

func readMarkdownFile(_ fileName: String) -> String? {
    var collectionCodeDocLanguage = "EN"
    if #available(iOS 16, macOS 13, *) {
        if Locale.current.language.languageCode?.identifier == "zh" &&
            Locale.current.language.script?.identifier == "Hans" {
            collectionCodeDocLanguage = "ZH-HANS"
        }
    }
    if let path = Bundle.main.path(forResource: "\(fileName)_\(collectionCodeDocLanguage)", ofType: "md") {
        if let content = try? String(contentsOfFile: path, encoding: .utf8) {
            return content
        }
    }
    return nil
}
