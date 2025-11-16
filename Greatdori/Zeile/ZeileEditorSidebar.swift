//===---*- Greatdori! -*---------------------------------------------------===//
//
// ZeileEditorSidebar.swift
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
import DoriKit
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct ZeileEditorSidebar: View {
    static let switchTabSubject = PassthroughSubject<SidebarTab, Never>()
    
    @ObservedObject var document: ZeileProjectDocument
    @Binding var fileSelection: FileWrapper?
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedTab: SidebarTab = .code
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                tabButton(for: .code, systemImage: "ellipsis.curlybraces")
                tabButton(for: .assets, systemImage: "folder")
                tabButton(for: .diagnostics, systemImage: "exclamationmark.triangle")
            }
            .font(.system(size: 14))
            .buttonStyle(.plain)
            .buttonBorderShape(.circle)
            .background {
                Capsule()
                    .fill(Color.gray.opacity(0.2))
            }
            .padding(.horizontal)
            
            selectedTab.contentView(
                for: document,
                fileSelection: $fileSelection
            )
        }
        .onReceive(Self.switchTabSubject) { newTab in
            selectedTab = newTab
        }
    }
    
    @ViewBuilder
    private func tabButton(for tab: SidebarTab, systemImage: String) -> some View {
        Button(action: {
            selectedTab = tab
        }, label: {
            HStack {
                Spacer(minLength: 0)
                Image(systemName: systemImage)
                    .padding(6)
                Spacer(minLength: 0)
            }
            .foregroundStyle(selectedTab == tab && colorScheme == .light ? .white : .primary)
            .background {
                Capsule()
                    .fill(.accent)
                    .opacity(selectedTab == tab ? 1 : 0)
            }
            .contentShape(Rectangle())
        })
    }
    
    enum SidebarTab {
        case code
        case assets
        case diagnostics
        
        @MainActor
        @ViewBuilder
        fileprivate func contentView(
            for project: ZeileProjectDocument,
            fileSelection: Binding<FileWrapper?>
        ) -> some View {
            switch self {
            case .code:
                SidebarCodeListView(project: project, fileSelection: fileSelection)
            case .assets:
                SidebarAssetListView(project: project, fileSelection: fileSelection)
            case .diagnostics:
                SidebarDiagnosticListView(project: project)
            }
        }
    }
}

private struct SidebarCodeListView: View {
    @ObservedObject var project: ZeileProjectDocument
    @Binding var fileSelection: FileWrapper?
    var body: some View {
        List(selection: $fileSelection) {
            ForEach(project.configuration.codePhases, id: \.self) { name in
                NavigationLink(value: project.codeFileWrapper(name: name)) {
                    HStack {
                        Image(systemName: "applescript")
                        Text(name)
                    }
                }
                .listRowInsets(.init(top: 5, leading: 2, bottom: 5, trailing: 2))
            }
        }
        .listStyle(.inset)
        .contentMargins(.vertical, 20, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
    }
}

private struct SidebarAssetListView: View {
    @ObservedObject var project: ZeileProjectDocument
    @Binding var fileSelection: FileWrapper?
    var body: some View {
        Spacer() // FIXME
    }
}

private struct SidebarDiagnosticListView: View {
    @ObservedObject var project: ZeileProjectDocument
    @EnvironmentObject private var sharedState: ZeileProjectSharedState
    var body: some View {
        List {
            ForEach(sharedState.diagnostics.keys.sorted(), id: \.self) { file in
                Text(file)
                ForEach(sharedState.diagnostics[file]!, id: \.self) { diag in
                    HStack(alignment: .top) {
                        Spacer()
                            .frame(width: 20)
                        Image(systemName: diag.severity.symbol)
                            .foregroundStyle(.white, diag.severity.color)
                        Text(diag.message)
                    }
                }
            }
        }
        .listStyle(.inset)
        .contentMargins(.vertical, 20, for: .scrollContent)
        .scrollContentBackground(.hidden)
    }
}
