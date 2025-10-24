//===---*- Greatdori! -*---------------------------------------------------===//
//
// ContentView.swift
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
@_private(sourceFile: "FrontendSong.swift") import DoriKit

struct ContentView: View {
    @State var lyrics = Lyrics(
        id: 0,
        version: 1,
        lyrics: [],
        mainStyle: nil,
        metadata: .init(legends: [])
    )
    @State var mainTabSelection = 0
    @State var detailNavigationPath = NavigationPath()
    @State var navigationActions = NavigationActions()
    @State var shouldRecordChange = true
    var body: some View {
        NavigationSplitView {
            List(selection: $mainTabSelection) {
                Section {
                    Label("File", systemImage: "document").tag(0)
                    Label("Style", systemImage: "paintbrush").tag(1)
                    Label("Metadata", systemImage: "gearshape").tag(2)
                    Label("Lyrics", systemImage: "music.note.list").tag(3)
                } header: {
                    Text("Lyrics")
                }
                Section {
                    Label {
                        Text("Reflection")
                    } icon: {
                        Image(_internalSystemName: "music.note.circle.righthalf.dotted")
                    }
                    .tag(4)
                } header: {
                    Text("Music")
                }
            }
            .navigationSplitViewColumnWidth(180)
        } detail: {
            NavigationStack(path: $detailNavigationPath) {
                Group {
                    switch mainTabSelection {
                    case 0: FileView(lyrics: $lyrics)
                    case 1: StyleView(lyrics: $lyrics)
                    case 2: MetadataView(lyrics: $lyrics)
                    case 3: LyricsView(lyrics: $lyrics)
                    case 4: ReflectionView()
                    default: EmptyView()
                    }
                }
                .navigationBarBackButtonHidden()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                navigator
            }
        }
        .onChange(of: detailNavigationPath) {
            if !shouldRecordChange {
                shouldRecordChange = true
                return
            }
            if detailNavigationPath == .init() { return }
            navigationActions.newChange(.path(detailNavigationPath))
        }
        .onChange(of: mainTabSelection) {
            if !shouldRecordChange {
                shouldRecordChange = true
                return
            }
            navigationActions.newChange(.tab(mainTabSelection))
        }
    }
    
    @ViewBuilder
    var navigator: some View {
        ControlGroup {
            Button(action: {
                shouldRecordChange = false
                navigationActions.goBackward(toPath: &detailNavigationPath, toTab: &mainTabSelection)
            }, label: {
                Image(systemName: "chevron.backward")
            })
            .disabled(!navigationActions.canGoBackward)
            Button(action: {
                shouldRecordChange = false
                navigationActions.goForward(toPath: &detailNavigationPath, toTab: &mainTabSelection)
            }, label: {
                Image(systemName: "chevron.forward")
            })
            .disabled(!navigationActions.canGoForward)
        }
        .controlGroupStyle(.navigation)
    }
    
    struct NavigationActions {
        // Actions: T, T, P...
        // Cursor:  <- ^ ->
        var actions: [Action] = [.tab(0)]
        var cursor = 0
        
        mutating func newChange(_ action: Action) {
            actions.removeSubrange(cursor + 1..<actions.count)
            actions.append(action)
            cursor = actions.count - 1
        }
        mutating func goBackward(toPath path: inout NavigationPath, toTab tab: inout Int) {
            guard canGoBackward else { return }
            cursor -= 1
            if case .tab = actions[cursor + 1] {
                while case .path = actions[cursor] {
                    actions.remove(at: cursor)
                    cursor -= 1
                }
            }
            let item = actions[cursor]
            switch item {
            case .path(let newPath):
                path = newPath
            case .tab(let newSelection):
                if newSelection != tab {
                    tab = newSelection
                } else {
                    path = .init()
                }
            }
        }
        mutating func goForward(toPath path: inout NavigationPath, toTab tab: inout Int) {
            guard canGoForward else { return }
            cursor += 1
            let item = actions[cursor]
            switch item {
            case .path(let newPath):
                path = newPath
            case .tab(let newSelection):
                tab = newSelection
            }
        }
        
        var canGoBackward: Bool {
            cursor > 0
        }
        var canGoForward: Bool {
            cursor < actions.count - 1
        }
        
        enum Action {
            case path(NavigationPath)
            case tab(Int)
        }
    }
}
