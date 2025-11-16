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

struct SettingsDocumentButton: View {
    var label: LocalizedStringResource
    var content: String
    @State var sheetIsDisplayed = false
    var body: some View {
        Button(action: {
            sheetIsDisplayed = true
        }, label: {
            Text(label)
        })
        .sheet(isPresented: $sheetIsDisplayed, content: {
            Group {
                if let markdownContent = readMarkdownFile(content) {
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
            .toolbar {
#if os(macOS)
                ToolbarItem(placement: .cancellationAction) {
                    DismissButton(label: {
                        Text("Settings.document.close")
                    })
                }
#else
                ToolbarItem(placement: .topBarTrailing, content: {
                    Label("Settings.document.close", systemImage: "xmark")
                })
#endif
            }
        })
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
