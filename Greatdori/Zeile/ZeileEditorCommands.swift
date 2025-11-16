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
    @FocusedValue(\.zeileProjectSharedState) private var sharedState: ZeileProjectSharedState?
    var body: some Commands {
        if let project, let sharedState {
            #if os(macOS)
            CommandMenu("Zeile.command.find") {
                Section {
                    Button("Zeile.command.find.find", systemImage: "text.page.badge.magnifyingglass") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.showFindInterface)
                        }
                    }
                    .keyboardShortcut("F", modifiers: .command)
                    Button("Zeile.command.find.find-and.replace") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.showReplaceInterface)
                        }
                    }
                    .keyboardShortcut("f", modifiers: [.command, .option])
                    Button("Zeile.command.find.find.next") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.nextMatch)
                        }
                    }
                    .keyboardShortcut("G", modifiers: .command)
                    Button("Zeile.command.find.find.previous") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.previousMatch)
                        }
                    }
                    .keyboardShortcut("G", modifiers: [.command, .shift])
                }
                Section {
                    Button("Zeile.command.find.replace", systemImage: "text.page.badge.magnifyingglass") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.replace)
                        }
                    }
                    Button("Zeile.command.find.replace-all") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.replaceAll)
                        }
                    }
                    Button("Zeile.command.find.replace.next") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.replaceAndFind)
                        }
                    }
                    Button("Zeile.command.find.replace.previous") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.replace)
                            finder.performAction(.previousMatch)
                        }
                    }
                }
                Section {
                    Button("Zeile.command.find.hide", systemImage: "inset.filled.topthird.rectangle") {
                        CodeEditor.textFinderSubject.send { finder in
                            finder.performAction(.hideFindInterface)
                        }
                    }
                }
            }
            #endif // os(macOS)
            CommandMenu("Zeile.command.product") {
                Section {
                    Button("Zeile.command.product.run", systemImage: "play.fill") {
                        Task {
                            await zeileProductRun(project: project, with: sharedState)
                        }
                    }
                    .keyboardShortcut("R", modifiers: .command)
                    Button("Zeile.command.product.archive", systemImage: "shippingbox.fill") {
                        
                    }
                    .keyboardShortcut("P", modifiers: .command)
                }
                Section {
                    Button("Zeile.command.product.build", systemImage: "hammer.fill") {
                        Task {
                            await zeileProductBuild(project: project, with: sharedState)
                        }
                    }
                    .keyboardShortcut("B", modifiers: .command)
                    Button("Zeile.command.product.stop", systemImage: "stop.fill") {
                        sharedState.removeRunningWindow()
                    }
                    .disabled(sharedState.runningWindowID == nil)
                    .keyboardShortcut(".", modifiers: .command)
                }
                #if os(macOS)
                Section {
                    Button("Show Build Folder in Finder", systemImage: "folder") {
                        NSWorkspace.shared.selectFile(
                            nil,
                            inFileViewerRootedAtPath: _buildFolder(for: project).path
                        )
                    }
                }
                #endif
            }
        }
    }
}

extension FocusedValues {
    @Entry var currentZeileProject: ZeileProjectDocument?
    @Entry var zeileProjectSharedState: ZeileProjectSharedState?
}
