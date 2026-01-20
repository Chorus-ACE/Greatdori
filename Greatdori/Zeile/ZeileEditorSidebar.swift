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
import SDWebImageSwiftUI
import SymbolAvailability
import UniformTypeIdentifiers
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
                tabButton(for: .project, systemImage: "document")
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
        case project
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
            case .project:
                SidebarProjectSettingsView(project: project)
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

private struct SidebarProjectSettingsView: View {
    @ObservedObject var project: ZeileProjectDocument
    @State private var configuration = ZeileProjectConfig()
    var body: some View {
        Form {
            Section {
                Picker("Zeile.project.metadata.locale", selection: $configuration.metadata.locale) {
                    ForEach(DoriLocale.allCases, id: \.rawValue) { locale in
                        Text(locale.rawValue.uppercased()).tag(locale)
                    }
                }
                TextField("Zeile.project.metadata.name", text: $configuration.metadata.projectName)
                TextField("Zeile.project.metadata.author", text: $configuration.metadata.author)
                TextField("Zeile.project.metadata.description", text: $configuration.metadata.description)
            } header: {
                Text("Zeile.project.metadata")
            }
        }
        .formStyle(.grouped)
        .onAppear {
            configuration = project.configuration
        }
        .onChange(of: configuration) {
            project.configuration = configuration
        }
    }
}

private struct SidebarCodeListView: View {
    @ObservedObject var project: ZeileProjectDocument
    @Binding var fileSelection: FileWrapper?
    var body: some View {
        List(selection: $fileSelection) {
            ForEach(project.configuration.codePhases, id: \.self) { name in
                FileLink(project: project, name: name)
                    .listRowInsets(.init(top: 5, leading: 2, bottom: 5, trailing: 2))
            }
            .onMove { src, dst in
                project.configuration.codePhases.move(fromOffsets: src, toOffset: dst)
            }
        }
        .listStyle(.inset)
        .contentMargins(.vertical, 20, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .environment(\.defaultMinListRowHeight, 0)
    }
    
    private struct FileLink: View {
        @ObservedObject var project: ZeileProjectDocument
        var name: String
        @FocusState private var isRenaming: Bool
        @State private var renameText = ""
        var body: some View {
            NavigationLink(value: project.codeFileWrapper(name: name)) {
                HStack {
                    Image(systemName: .curlybraces)
                    TextField("", text: $renameText)
                        .focused($isRenaming)
                        .onSubmit {
                            let oldName = name
                            let wrapper = project.codeFolderWrapper
                            wrapper.renameFile(from: oldName, to: renameText)
                            if let index = project.configuration.codePhases
                                .firstIndex(of: oldName) {
                                project.configuration.codePhases[index] = renameText
                            }
                            isRenaming = false
                        }
                }
            }
            .contextMenu {
                Section {
                    Button("Zeile.file.new", systemImage: "document.badge.plus") {
                        var _newFileIndex = 0
                        var newFileName: String {
                            if _newFileIndex > 0 {
                                "Untitled \(_newFileIndex).zeile"
                            } else {
                                "Untitled.zeile"
                            }
                        }
                        let folderWrapper = project.codeFolderWrapper
                        while folderWrapper.fileWrappers?[newFileName] != nil {
                            _newFileIndex += 1
                        }
                        let newFileWrapper = FileWrapper(
                            regularFileWithContents: CodeTemplates
                                .newFileZeile(named: newFileName)
                                .data(using: .utf8)!
                        )
                        newFileWrapper.preferredFilename = newFileName
                        folderWrapper.addFileWrapper(newFileWrapper)
                        project.configuration.codePhases.append(newFileName)
                    }
                }
                Section {
                    Button("Zeile.file.rename", systemImage: "pencil.line") {
                        isRenaming = true
                    }
                }
                if project.configuration.codePhases.count > 1 {
                    Section {
                        Button("Zeile.file.delete", systemImage: "trash", role: .destructive) {
                            if let wrapper = project.codeFileWrapper(name: name) {
                                project.configuration.codePhases.removeAll {
                                    $0 == name
                                }
                                project.codeFolderWrapper.removeFileWrapper(wrapper)
                            }
                        }
                    }
                }
            }
            .onAppear {
                renameText = name
            }
        }
    }
}

private struct SidebarAssetListView: View {
    @ObservedObject var project: ZeileProjectDocument
    @Binding var fileSelection: FileWrapper?
    @State private var fileWrappers: [FileWrapper]
    @State private var contentUpdateTimer: Timer?
    
    init(project: ZeileProjectDocument, fileSelection: Binding<FileWrapper?>) {
        self._project = .init(initialValue: project)
        self._fileSelection = fileSelection
        self._fileWrappers = .init(
            initialValue: project.assetFolderWrapper.fileWrappers!.values.map { $0 }
        )
    }
    
    var body: some View {
        Group {
            if !fileWrappers.isEmpty {
                ScrollView {
                    LazyVGrid(columns: [.init(.adaptive(minimum: 120, maximum: 120), alignment: .leading)], alignment: .leading) {
                        let sortedWrappers = fileWrappers.sorted { $0.preferredFilename! < $1.preferredFilename! }
                        ForEach(sortedWrappers, id: \.self) { wrapper in
                            FileLink(project: project, fileSelection: $fileSelection, wrapper: wrapper)
                        }
                    }
                    .padding()
                }
            } else {
                ExtendedConstraints {
                    ContentUnavailableView(
                        "Zeile.asset.none",
                        systemImage: "folder.fill",
                        description: Text("Zeile.asset.drag-to-add")
                    )
                }
            }
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            for provider in providers {
                _ = provider.loadDataRepresentation(for: .fileURL) { data, _ in
                    if let data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        _ = url.startAccessingSecurityScopedResource()
                        defer { url.stopAccessingSecurityScopedResource() }
                        if let content = try? Data(contentsOf: url) {
                            project.assetFolderWrapper.addRegularFile(
                                withContents: content,
                                preferredFilename: url.lastPathComponent
                            )
                        }
                    }
                }
            }
            return true
        }
        .onAppear {
            contentUpdateTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                DispatchQueue.main.async {
                    fileWrappers = project.assetFolderWrapper.fileWrappers!.values.map { $0 }
                }
            }
        }
        .onDisappear {
            contentUpdateTimer?.invalidate()
        }
    }
    
    private struct FileLink: View {
        @ObservedObject var project: ZeileProjectDocument
        @Binding var fileSelection: FileWrapper?
        var wrapper: FileWrapper
        @State private var isRenaming = false
        @State private var renameText = ""
        @State private var thumbnailImage: PlatformImage?
        var body: some View {
            Button {
                fileSelection = wrapper
            } label: {
                VStack {
                    Group {
                        if let thumbnailImage {
                            #if os(macOS)
                            Image(nsImage: thumbnailImage)
                                .resizable()
                                .scaledToFit()
                            #else
                            Image(uiImage: thumbnailImage)
                                .resizable()
                                .scaledToFit()
                            #endif
                        }
                    }
                    if !isRenaming {
                        Text(renameText)
                    } else {
                        TextField("", text: $renameText)
                            .onSubmit {
                                let oldName = wrapper.preferredFilename!
                                project.assetFolderWrapper.renameFile(from: oldName, to: renameText)
                                isRenaming = false
                            }
                    }
                }
            }
            .buttonStyle(.plain)
            .contextMenu {
                Section {
                    Button("Zeile.asset.rename", systemImage: "pencil.line") {
                        isRenaming = true
                    }
                }
                Section {
                    Button("Zeile.asset.delete", systemImage: "trash", role: .destructive) {
                        project.assetFolderWrapper.removeFileWrapper(wrapper)
                    }
                }
            }
            .onAppear {
                renameText = wrapper.preferredFilename!
                
                if thumbnailImage == nil {
                    if let image = PlatformImage(data: wrapper.regularFileContents!) {
                        thumbnailImage = image
                    }
                }
            }
        }
    }
}

private struct SidebarDiagnosticListView: View {
    @ObservedObject var project: ZeileProjectDocument
    @EnvironmentObject private var sharedState: ZeileProjectSharedState
    var body: some View {
        if !sharedState.diagnostics.isEmpty {
            List {
                ForEach(sharedState.diagnostics.keys.sorted(), id: \.self) { file in
                    if sharedState.diagnostics[file]?.isEmpty == false {
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
            }
            .listStyle(.inset)
            .contentMargins(.vertical, 20, for: .scrollContent)
            .scrollContentBackground(.hidden)
        } else {
            ExtendedConstraints {
                ContentUnavailableView("Zeile.diagnostic.none", systemImage: "stethoscope")
            }
        }
    }
}
