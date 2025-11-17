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
            .navigationSplitViewColumnWidth(min: 200, ideal: 300)
        } detail: {
            Group {
                if let file = selectedFile, file.preferredFilename != nil {
                    ZeileEditorFileEditView(project: document, file: file)
                } else {
                    ExtendedConstraints {
                        EmptyView()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .status) {
                    ZeileEditorStatusBar(document: document, widthAvailable: editorWidth)
                }
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Stop", systemImage: "stop.fill") {
                        sharedState.removeRunningWindow()
                    }
                    .disabled(sharedState.runningWindowID == nil)
                    Button("Run", systemImage: "play.fill") {
                        Task {
                            await zeileProductRun(project: document, with: sharedState)
                        }
                    }
                }
            }
            .onFrameChange { geometry in
                editorWidth = geometry.size.width
            }
        }
        .focusedSceneValue(\.currentZeileProject, document)
        .focusedSceneValue(\.zeileProjectSharedState, sharedState)
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
            .frame(width: widthAvailable / 5, alignment: .trailing)
        }
        .padding(.trailing, 10)
    }
    
    @ViewBuilder
    private func workIndicator(_ work: ZeileProjectSharedState.Work) -> some View {
        HStack {
            Text(work.description)
            if work.progress >= 0 {
                Gauge(value: work.progress) {
                    EmptyView()
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .labelsHidden()
                .tint(.accentColor)
                .scaleEffect(0.3)
                .frame(width: 20, height: 20)
            }
        }
    }
}

final class ZeileProjectSharedState: @unchecked Sendable, ObservableObject {
    // MARK: - Diags
    @Published var diagnostics: [/*file name*/String: [Diagnostic]] = [:]
    
    // MARK: - Work
    @Published var lastWork: Work = .init(description: "Idle", progress: -1)
    @Published var currentWorks: [Work] = []
    
    @discardableResult
    func addWork(_ work: Work) -> Work {
        DispatchQueue.main.async {
            self.currentWorks.append(work)
        }
        return work
    }
    func removeWork(_ work: Work) {
        DispatchQueue.main.async {
            self.currentWorks.removeAll { $0.id == work.id }
        }
    }
    func setLastWork(_ work: Work) {
        DispatchQueue.main.async {
            self.lastWork = work
        }
    }
    
    struct Work: Identifiable {
        var id: UUID = UUID()
        var description: String
        var progress: Double
    }
    
    // MARK: - Running Status
    @Published var runningWindowID: UUID?
    var attachedRunningWindowDismissHandler: AnyCancellable?
    
    func addRunningWindow(id: UUID) {
        DispatchQueue.main.async {
            self.runningWindowID = id
            self.attachedRunningWindowDismissHandler = ZeileStoryViewerView.willDismissSubject.sink { msgID in
                if msgID == id {
                    self.runningWindowID = nil
                    self.attachedRunningWindowDismissHandler = nil
                    self.currentWorks.removeAll { $0.id == id }
                    self.setLastWork(.init(description: "Finished running", progress: -1))
                }
            }
        }
    }
    @MainActor
    func removeRunningWindow() {
        if let windowID = self.runningWindowID {
            ZeileStoryViewerView.shouldDismissSubject.send(windowID)
            self.currentWorks.removeAll { $0.id == windowID }
            self.setLastWork(.init(description: "Finished running", progress: -1))
            self.runningWindowID = nil
            self.attachedRunningWindowDismissHandler = nil
        }
    }
}
