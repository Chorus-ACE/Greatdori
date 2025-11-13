//===---*- Greatdori! -*---------------------------------------------------===//
//
// ZeileEditorCommands.swift
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

import Combine
import SwiftUI

struct ZeileEditorCommands: Commands {
    @FocusedValue(\.currentZeileProject) private var project: ZeileProjectDocument?
    var body: some Commands {
        if let project {
            #if os(macOS)
            CommandMenu("Find") {
                Section {
                    Button("Find…", systemImage: "text.page.badge.magnifyingglass") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.showFindInterface)
                        }
                    }
                    .keyboardShortcut("f", modifiers: .command)
                    Button("Find and Replace…") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.showReplaceInterface)
                        }
                    }
                    .keyboardShortcut("f", modifiers: [.command, .option])
                    Button("Find Next") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.nextMatch)
                        }
                    }
                    .keyboardShortcut("g", modifiers: .command)
                    Button("Find Previous") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.previousMatch)
                        }
                    }
                    .keyboardShortcut("g", modifiers: [.command, .shift])
                }
                Section {
                    Button("Replace", systemImage: "text.page.badge.magnifyingglass") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.replace)
                        }
                    }
                    Button("Replace All") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.replaceAll)
                        }
                    }
                    Button("Replace and Find Next") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.replaceAndFind)
                        }
                    }
                    Button("Replace and Find Previous") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.replace)
                            finder.performAction(.previousMatch)
                        }
                    }
                }
                Section {
                    Button("Hide Find Bar", systemImage: "inset.filled.topthird.rectangle") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.hideFindInterface)
                        }
                    }
                }
            }
            #endif // os(macOS)
            CommandMenu("Product") {
                Section {
                    Button("Run", systemImage: "play.fill") {
                        
                    }
                    .keyboardShortcut("r", modifiers: .command)
                    Button("Archive", systemImage: "shippingbox.fill") {
                        
                    }
                    .keyboardShortcut("p", modifiers: .command)
                }
                Section {
                    Button("Build", systemImage: "hammer.fill") {
                        
                    }
                    .keyboardShortcut("b", modifiers: .command)
                }
            }
        }
    }
}

extension FocusedValues {
    @Entry var currentZeileProject: ZeileProjectDocument?
}
