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
    @Environment(\.openURL) private var openURL
    var body: some View {
        if !links.isEmpty {
            Section {
                HereTheWorld { // Super weird issue causing infinite hang. Use `HereTheWorld` to fix. MAGIC --ThreeManager785
                    CustomGroupBox {
                        VStack {
                            ForEach(links) { item in
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
                                .id(item.id)
                            }
                            .insert {
                                Divider()
                            }
                        }
                    }
                    .frame(maxWidth: infoContentMaxWidth)
                }
            } header: {
                HStack {
                    Text("External-links")
                        .font(.title2)
                        .bold()
                    Spacer()
                }
                .frame(maxWidth: 615)
                .detailSectionHeader()
            }
        }
    }
}

struct ExternalLink: Hashable, Identifiable {
    let id: UUID = .init()
    let name: LocalizedStringResource
    let url: URL
}
