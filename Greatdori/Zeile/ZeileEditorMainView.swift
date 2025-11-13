//===---*- Greatdori! -*---------------------------------------------------===//
//
// ZeileEditorMainView.swift
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

struct ZeileEditorMainView: View {
    @ObservedObject var document: ZeileProjectDocument
    @StateObject private var sharedState = ZeileProjectSharedState()
    @State private var selectedFile: FileWrapper?
    @State private var editorWidth: CGFloat = 0
    var body: some View {
        NavigationSplitView {
            ZeileEditorSidebar(
                document: document,
                fileSelection: $selectedFile
            )
        } detail: {
            Group {
                if let file = selectedFile, file.preferredFilename != nil {
                    ZeileEditorFileEditView(project: document, file: file)
                }
            }
            .toolbar {
                ToolbarItem(placement: .status) {
                    ZeileEditorStatusBar(document: document, widthAvailable: editorWidth)
                }
            }
            .onFrameChange { geometry in
                editorWidth = geometry.size.width
            }
        }
        .focusedSceneValue(\.currentZeileProject, document)
        .environmentObject(sharedState)
    }
}

private struct ZeileEditorStatusBar: View {
    @ObservedObject var document: ZeileProjectDocument
    var widthAvailable: CGFloat
    @EnvironmentObject private var sharedState: ZeileProjectSharedState
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Diagnostic.Severity.allCases, id: \.self) { severity in
                Button(action: {
                    ZeileEditorSidebar.switchTabSubject.send(.diagnostics)
                }, label: {
                    Image(systemName: severity.symbol)
                        .font(.system(size: 10))
                        .foregroundStyle(.white, severity.color)
                    Text("\(sharedState.diagnostics.values.flatMap{ $0 }.count { $0.severity == severity })")
                        .font(.system(size: 12))
                })
            }
            Group {
                if !sharedState.currentWorks.isEmpty {
                    workIndicator(sharedState.currentWorks.first!)
                } else {
                    workIndicator(sharedState.lastWork)
                }
            }
            .frame(width: widthAvailable / 4, alignment: .trailing)
        }
        .padding(.trailing, 10)
    }
    
    @ViewBuilder
    private func workIndicator(_ work: ZeileProjectSharedState.Work) -> some View {
        HStack {
            Text(work.description)
            if work.progress >= 0 {
                ProgressView(value: work.progress)
                    .progressViewStyle(.circular)
            }
        }
    }
}

final class ZeileProjectSharedState: ObservableObject {
    @Published var diagnostics: [/*file name*/String: [Diagnostic]] = [:]
    
    @Published var lastWork: Work = .init(description: "Idle", progress: -1)
    @Published var currentWorks: [Work] = [] {
        willSet {
            if newValue.isEmpty, let previousLast = currentWorks.last {
                lastWork = previousLast
            }
        }
    }
    
    struct Work {
        var description: String
        var progress: Double
    }
}
