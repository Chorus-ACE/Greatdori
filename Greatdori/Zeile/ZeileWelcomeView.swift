//===---*- Greatdori! -*---------------------------------------------------===//
//
// ZeileWelcomeView.swift
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

struct ZeileWelcomeView: View {
    var body: some View {
        ScrollView {
            HStack {
                Spacer(minLength: 0)
                VStack {
                    ZeileWelcomeHeading()
                    DetailSectionsSpacer(height: 15)
                    ZeileWelcomeActions()
                }
                .padding()
                Spacer(minLength: 0)
            }
        }
        .navigationTitle(String("Zeile Editor"))
    }
}

private struct ZeileWelcomeHeading: View {
    var body: some View {
        CustomGroupBox {
            HStack {
                Image("CreatorIcon64")
                    .resizable()
                    .frame(width: 50, height: 50)
                VStack(alignment: .leading) {
                    Text(verbatim: "Zeile Editor")
                        .font(.title)
                        .fontWeight(.semibold)
                    Text(verbatim: "Version 1.0.0")
                        .font(.body)
                        .foregroundStyle(.gray)
                }
                Spacer()
            }
        }
        .frame(maxWidth: infoContentMaxWidth)
    }
}

private struct ZeileWelcomeActions: View {
    @Environment(\.newDocument) private var newDocument
    @Environment(\.openDocument) private var openDocument
    @State private var isOpenProjectPresented = false
    var body: some View {
        CustomGroupBox {
            VStack {
                Button(action: {
                    newDocument {
                        ZeileProjectDocument(emptyWithName: "Untitled.zeileproj")
                    }
                }, label: {
                    HStack {
                        Image(systemName: "plus.square")
                            .foregroundStyle(.gray)
                            .frame(width: 20)
                        Text("创建新项目…")
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                })
                Divider()
                    .padding(.vertical, 5)
                Button(action: {
                    isOpenProjectPresented = true
                }, label: {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundStyle(.gray)
                            .frame(width: 20)
                        Text("打开现有项目…")
                            .fontWeight(.medium)
                        Spacer()
                    }
                    .contentShape(Rectangle())
                })
                .fileImporter(
                    isPresented: $isOpenProjectPresented,
                    allowedContentTypes: [.zeileProject]
                ) { result in
                    if case .success(let url) = result {
                        Task {
                            try? await openDocument(at: url)
                        }
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: infoContentMaxWidth)
    }
}
