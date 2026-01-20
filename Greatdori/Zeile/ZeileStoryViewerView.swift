//===---*- Greatdori! -*---------------------------------------------------===//
//
// ZeileStoryViewerView.swift
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
import SymbolAvailability
@_spi(Advanced) import SwiftUIIntrospect

struct ZeileStoryViewerView: View {
    static let shouldDismissSubject = PassthroughSubject<UUID, Never>() // Outside -> Here
    static let willDismissSubject = PassthroughSubject<UUID, Never>() // Here -> Outside
    
    var data: ZeileStoryViewerWindowData?
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var irData: StoryIR?
    @State private var assetFolder: URL?
    var body: some View {
        Group {
            if let irData {
                InteractiveStoryView(irData, assetFolder: assetFolder)
            } else {
                ProgressView()
                    .controlSize(.large)
                    .onAppear {
                        if let data, let data = try? Data(contentsOf: data.irURL) {
                            assetFolder = unsafe self.data.unsafelyUnwrapped.assetFolder
                            irData = StoryIR(binary: data)
                        }
                    }
            }
        }
        .onDisappear {
            if let data {
                Self.willDismissSubject.send(data.id)
            }
        }
        .onReceive(Self.shouldDismissSubject) { id in
            if let data {
                if id == data.id {
                    dismissWindow()
                }
            }
        }
        .onOpenURL { url in
            if FileManager.default.fileExists(atPath: url.path),
               let data = try? Data(contentsOf: url) {
                if url.path.hasSuffix(".zir") {
                    irData = StoryIR(binary: data)
                } else if url.path.hasSuffix(".sar") {
                    Task {
                        let folderName = url.lastPathComponent.dropLast(".sar".count)
                        let tmpFolderURL = URL(filePath: NSTemporaryDirectory() + "/StoryPlayerIntermediate/\(folderName)")
                        if FileManager.default.fileExists(atPath: tmpFolderURL.path) {
                            try? FileManager.default.removeItem(at: tmpFolderURL)
                        }
                        if await StoryArchive.extract(from: data, to: tmpFolderURL),
                           let ir = try? Data(contentsOf: tmpFolderURL.appending(path: "Story.zir")) {
                            assetFolder = tmpFolderURL.appending(path: "Assets")
                            irData = StoryIR(binary: ir)
                        } else {
                            dismissWindow()
                        }
                    }
                } else {
                    dismissWindow()
                }
            } else {
                dismissWindow()
            }
        }
        #if os(macOS)
        .introspect(.window, on: .macOS(.v14...)) { window in
            window.isRestorable = false
        }
        .toolbar {
            if let irData, AppFlag.ISV_DEBUG {
                ToolbarItem {
                    Menu(content: {
                        Button(action: {
                            let downloadBase = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                            let dst = downloadBase.appending(path: "DumpIR.txt")
                            let text = DoriStoryBuilder.Conversion.plainText(fromIR: irData)
                            try? text.write(to: dst, atomically: true, encoding: .utf8)
                            NSWorkspace.shared.selectFile(
                                dst.path,
                                inFileViewerRootedAtPath: ""
                            )
                            print(dump(irData))
                        }, label: {
                            Label(String("Dump IR"), systemImage: "text.word.spacing")
                        })
                        
                        Button(action: {
                            let downloadBase = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                            let dst = downloadBase.appending(path: "Sirius.txt")
                            let text = DoriStoryBuilder.Conversion.sirius(fromIR: irData)
                            try? text.write(to: dst, atomically: true, encoding: .utf8)
                            NSWorkspace.shared.selectFile(
                                dst.path,
                                inFileViewerRootedAtPath: ""
                            )
                        }, label: {
                            Label(String("Sirius"), systemImage: "sparkles")
                        })
                    }, label: {
                        Image(systemName: .ant)
                    })
                }
            }
        }
        #endif
    }
}

struct ZeileStoryViewerWindowData: Identifiable, Hashable, Codable {
    var id: UUID = .init()
    var irURL: URL
    var assetFolder: URL?
}
