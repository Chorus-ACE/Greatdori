//===---*- Greatdori! -*---------------------------------------------------===//
//
// ZeileProductActions.swift
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
import Foundation

@discardableResult
func zeileProductBuild(project: ZeileProjectDocument, with state: ZeileProjectSharedState) async -> Bool {
    let work = state.addWork(.init(description: "Building", progress: 0.5))
    
    return await withCheckedContinuation { continuation in
        DispatchQueue(label: "com.memz233.Greatdori.Zeile-Editor.Build").async {
            let buildFolder = _buildFolder(for: project)
            
            let builder = DoriStoryBuilder(for: project.configuration.metadata.locale)
            
            var codeList: [String] = []
            for phase in project.configuration.codePhases {
                if let wrapper = project.codeFileWrapper(name: phase),
                   let data = wrapper.regularFileContents,
                   let codeStr = String(data: data, encoding: .utf8) {
                    codeList.append(codeStr)
                }
            }
            
            var diags: [Diagnostic] = []
            if let ir = builder.buildIR(from: codeList, diags: &diags) {
                try? ir.binaryEncoded().write(to: buildFolder.appending(path: "Story.zir"))
                state.removeWork(work)
                state.lastWork = .init(description: "Build Succeeded", progress: -1)
                continuation.resume(returning: true)
            } else {
                state.removeWork(work)
                state.lastWork = .init(description: "Build Failed", progress: -1)
                continuation.resume(returning: false)
            }
        }
    }
}

@discardableResult
func zeileProductRun(project: ZeileProjectDocument, with state: ZeileProjectSharedState) async -> UUID? {
    // Stop running instance
    if state.runningWindowID != nil {
        await state.removeRunningWindow()
    }
    
    if await zeileProductBuild(project: project, with: state) {
        let irURL = _buildFolder(for: project).appending(path: "Story.zir")
        let uuid = UUID()
        await EnvironmentValues().openWindow(
            id: "ZeileStoryViewer",
            value: ZeileStoryViewerWindowData(id: uuid, irURL: irURL)
        )
        state.addRunningWindow(id: uuid)
        state.addWork(.init(id: uuid, description: "Running \(project.configuration.metadata.projectName)", progress: -1))
        return uuid
    } else {
        return nil
    }
}

func _buildFolder(for project: ZeileProjectDocument) -> URL {
    let projName = (project.wrapper.preferredFilename ?? project.wrapper.filename)!
        .components(separatedBy: ".")
        .dropLast()
        .joined(separator: ".")
    let folderURL = URL(filePath: NSHomeDirectory() + "/Library/Developer/Zeile/DerivedData/\(projName)/Build")
    if !FileManager.default.fileExists(atPath: folderURL.path) {
        try? FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true)
    }
    return folderURL
}
