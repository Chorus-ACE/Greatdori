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
@_spi(Advanced) import SwiftUIIntrospect

struct ZeileStoryViewerView: View {
    static let shouldDismissSubject = PassthroughSubject<UUID, Never>() // Outside -> Here
    static let willDismissSubject = PassthroughSubject<UUID, Never>() // Here -> Outside
    
    var data: ZeileStoryViewerWindowData?
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var irData: StoryIR?
    var body: some View {
        Group {
            if let irData {
                InteractiveStoryView(irData)
            } else {
                ProgressView()
                    .controlSize(.large)
                    .onAppear {
                        if let data, let data = try? Data(contentsOf: data.irURL) {
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
                irData = StoryIR(binary: data)
            } else {
                dismissWindow()
            }
        }
        #if os(macOS)
        .introspect(.window, on: .macOS(.v14...)) { window in
            window.isRestorable = false
        }
        #endif
    }
}

struct ZeileStoryViewerWindowData: Identifiable, Hashable, Codable {
    var id: UUID = .init()
    var irURL: URL
}
