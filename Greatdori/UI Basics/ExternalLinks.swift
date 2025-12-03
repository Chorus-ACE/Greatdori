//===---*- Greatdori! -*---------------------------------------------------===//
//
// ExternalLinks.swift
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

struct ExternalLinksSection: View {
    var links: [ExternalLink] = []
    @Environment(\.openURL) var openURL
    var body: some View {
        if !links.isEmpty {
            LazyVStack(pinnedViews: .sectionHeaders) {
                Section {
                    CustomGroupBox {
                        VStack {
                            ForEach(links, id: \.self) { item in
                                Button(action: {
                                    openURL(item.url)
                                }, label: {
                                    HStack {
                                        Text(item.name)
                                        Spacer()
                                        Image(systemName: "arrow.up.forward.app")
                                            .foregroundStyle(.secondary)
                                    }
                                    .contentShape(Rectangle())
                                })
                                .buttonStyle(.plain)
                            }
                            .insert {
                                Divider()
                            }
                        }
                    }
                    .frame(maxWidth: infoContentMaxWidth)
                } header: {
                    HStack {
                        Text("External-links")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    .frame(maxWidth: 615)
                }
            }
        }
    }
}

struct ExternalLink: Hashable, Equatable {
    let name: LocalizedStringResource
    let url: URL
}
