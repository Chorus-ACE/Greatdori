//===---*- Greatdori! -*---------------------------------------------------===//
//
// UnavailableView.swift
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

struct UnavailableView: View {
    private var text: LocalizedStringResource
    private var systemImage: String
    private var retryHandler: () -> Void
    
    init(_ text: LocalizedStringResource, systemImage: String, retryHandler: @escaping () -> Void) {
        self.text = text
        self.systemImage = systemImage
        self.retryHandler = retryHandler
    }
    init(_ text: LocalizedStringResource, systemImage: String, retryHandler: @escaping () async -> Void) {
        self.text = text
        self.systemImage = systemImage
        self.retryHandler = {
            Task {
                await retryHandler()
            }
        }
    }
    
    var body: some View {
        HStack {
            Spacer()
            VStack {
                if !systemImage.hasPrefix("_") {
                    ContentUnavailableView(text, systemImage: systemImage)
                } else {
                    ContentUnavailableView {
                        Label {
                            Text(text)
                        } icon: {
                            Image(_internalSystemName: String(systemImage.dropFirst()))
                        }
                    }
                }
                Button("重试", systemImage: "arrow.clockwise", action: retryHandler)
                    .buttonStyle(.bordered)
            }
            Spacer()
        }
        .listRowBackground(Color.clear)
    }
}
