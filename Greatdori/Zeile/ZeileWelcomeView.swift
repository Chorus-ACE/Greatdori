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
import SymbolAvailability

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
        .navigationTitle("Zeile.editor")
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
                    Text("Zeile.editor")
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
    #if os(macOS)
    @Environment(\.newDocument) private var newDocument
    @Environment(\.openDocument) private var openDocument
    #endif
    @Environment(\.openURL) private var openURL
    @Environment(\.supportsMultipleWindows) private var supportsMultipleWindows
    @State private var isOpenProjectPresented = false
    @State private var isProjectPresented = false
    @State private var presentingProject: ZeileProjectDocument?
    @State private var presentingProjectURL: URL?
    var body: some View {
        CustomGroupBox {
            VStack {
                Button(action: {
                    #if os(macOS)
                    newDocument {
                        ZeileProjectDocument(emptyWithName: "Story.zeileproj")
                    }
                    #endif
                }, label: {
                    HStack {
                        Image(systemName: .plusSquare)
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        Text("Zeile.home.new")
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
                        Image(systemName: .folder)
                            .foregroundStyle(.secondary)
                            .frame(width: 20)
                        Text("Zeile.home.open")
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
                        #if os(macOS)
                        Task {
                            try? await openDocument(at: url)
                        }
                        #else
                        if supportsMultipleWindows {
                            openURL(url)
                        } else {
                            _ = url.startAccessingSecurityScopedResource()
                            presentingProjectURL = url
                            if let wrapper = try? FileWrapper(url: url),
                               let project = try? ZeileProjectDocument(wrapper: wrapper) {
                                presentingProject = project
                                isProjectPresented = true
                            }
                        }
                        #endif
                    }
                }
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: infoContentMaxWidth)
        #if os(iOS)
        .fullScreenCover(isPresented: $isProjectPresented) {
            ZeileEditorMainView(document: presentingProject!)
                .onDisappear {
                    presentingProjectURL?.stopAccessingSecurityScopedResource()
                }
        }
        #endif
    }
}
