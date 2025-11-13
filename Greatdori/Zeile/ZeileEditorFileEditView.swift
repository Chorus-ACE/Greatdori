//===---*- Greatdori! -*---------------------------------------------------===//
//
// ZeileEditorFileEditView.swift
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

struct ZeileEditorFileEditView: View {
    @ObservedObject var project: ZeileProjectDocument
    var file: FileWrapper
    var body: some View {
        let filename = file.preferredFilename!
        if filename.hasSuffix(".zeile") {
            ZeileCodeEditView(project: project, file: file)
        }
    }
}

private struct ZeileCodeEditView: View {
    @ObservedObject var project: ZeileProjectDocument
    @State var file: FileWrapper
    @EnvironmentObject private var sharedState: ZeileProjectSharedState
    @State private var codeText: String
    
    init(project: ZeileProjectDocument, file: FileWrapper) {
        self.project = project
        self.file = file
        self._codeText = .init(
            initialValue: .init(
                data: file.regularFileContents!,
                encoding: .utf8
            )!
        )
    }
    
    var body: some View {
        CodeEditor(text: $codeText)
            .environment(\.onDiagnosticsUpdate) { diags in
                sharedState.diagnostics.updateValue(diags, forKey: file.preferredFilename!)
            }
            .onChange(of: codeText) {
                let name = file.preferredFilename
                project.codeFolderWrapper.removeFileWrapper(file)
                file = .init(regularFileWithContents: codeText.data(using: .utf8)!)
                file.preferredFilename = name
                project.codeFolderWrapper.addFileWrapper(file)
            }
    }
}
