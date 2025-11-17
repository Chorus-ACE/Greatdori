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

import DoriKit
import SwiftUI
import SDWebImageSwiftUI

struct ZeileEditorFileEditView: View {
    @ObservedObject var project: ZeileProjectDocument
    var file: FileWrapper
    var body: some View {
        let filename = file.preferredFilename!
        if filename.hasSuffix(".zeile") {
            ZeileCodeEditView(project: project, file: file)
        } else if let image = PlatformImage(data: file.regularFileContents!) {
            EditorImageViewerView(image: image)
        }
    }
}

private struct ZeileCodeEditView: View {
    @ObservedObject var project: ZeileProjectDocument
    var file: FileWrapper
    @EnvironmentObject private var sharedState: ZeileProjectSharedState
    @State private var codeText: String
    @State private var isShowingEditor = true
    
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
        if isShowingEditor {
            CodeEditor(
                text: $codeText,
                locale: project.configuration.metadata.locale,
                assetFolder: project.assetFolderWrapper
            )
            .environment(\.onDiagnosticsUpdate) { diags in
                sharedState.diagnostics.updateValue(diags, forKey: file.preferredFilename!)
            }
            .onChange(of: codeText) {
                let name = file.preferredFilename!
                project.codeFolderWrapper.updateFile(named: name, data: codeText.data(using: .utf8)!)
            }
            .onChange(of: file) {
                isShowingEditor = false
                codeText = .init(
                    data: file.regularFileContents!,
                    encoding: .utf8
                )!
                DispatchQueue.main.async {
                    isShowingEditor = true
                }
            }
        } else {
            ExtendedConstraints {
                ProgressView()
                    .controlSize(.large)
            }
        }
    }
}

private struct EditorImageViewerView: View {
    var image: PlatformImage
    var body: some View {
        Group {
            #if os(macOS)
            Image(nsImage: image)
                .resizable()
                .scaledToFit()
            #else
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
            #endif
        }
    }
}
