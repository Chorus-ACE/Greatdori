//===---*- Greatdori! -*---------------------------------------------------===//
//
// ContentAnalysis.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2026 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.com/LICENSE.txt for license information
// See https://greatdori.com/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import SwiftUI
import MarkdownUI
import SDWebImageSwiftUI
import SymbolAvailability
import SensitiveContentAnalysis

/// This image provider implements sensitive content analysis
/// for community images as long as users enable this feature.
struct PostContentImageProvider: ImageProvider {
    func makeImage(url: URL?) -> some View {
        AsyncSensitiveDetectableImage(url: url)
    }
}
extension ImageProvider where Self == PostContentImageProvider {
    /// This image provider implements sensitive content analysis
    /// for community images as long as users enable this feature.
    static var postContent: Self { .init() }
}

struct AsyncSensitiveDetectableImage: View {
    private static let sensitivityAnalyzer = SCSensitivityAnalyzer()
    
    var url: URL?
    init(url: URL?) {
        self.url = url
    }
    
    @State private var shouldFlagSensitive = false
    @State private var isSensitiveCoverHidden = false
    @State private var isDescriptiveInterventionPresented = false
    var body: some View {
        WebImage(url: url)
            .resizable()
            .onSuccess { image, _, _ in
                let analyzer = Self.sensitivityAnalyzer
                guard analyzer.analysisPolicy != .disabled else { return }
                guard let cgImage = image.cgImage else { return }
                Task {
                    guard let response = try? await analyzer.analyzeImage(cgImage) else {
                        return
                    }
                    shouldFlagSensitive = response.isSensitive
                }
            }
            .scaledToFit()
            .blur(radius: shouldFlagSensitive && !isSensitiveCoverHidden ? 20 : 0, opaque: true)
            .overlay {
                if shouldFlagSensitive {
                    ZStack {
                        if !isSensitiveCoverHidden {
                            Rectangle()
                                .fill(Color.black.opacity(0.1))
                                .onTapGesture {
                                    if Self.sensitivityAnalyzer.analysisPolicy == .descriptiveInterventions {
                                        isDescriptiveInterventionPresented = true
                                    }
                                }
                        }
                        VStack {
                            HStack {
                                Spacer()
                                Menu("Community.post.sensitive-image.actions", systemImage: "exclamationmark.triangle.fill") {
                                    let resourceURL = Self.sensitivityAnalyzer.analysisPolicy == .simpleInterventions
                                    ? "https://www.apple.com/wtgh/re/"
                                    : "https://www.apple.com/child-safety/rc-u13/"
                                    Link(destination: URL(string: resourceURL)!) {
                                        Label("Community.post.sensitive-image.actions.view-resources", systemImage: "doc.plaintext")
                                    }
                                }
                                .menuStyle(.button)
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.circle)
                                .labelStyle(.iconOnly)
                                .foregroundStyle(.white)
                            }
                            Spacer()
                            if !isSensitiveCoverHidden {
                                Text("Community.post.sensitive-image.description")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .allowsHitTesting(false)
                                Spacer()
                                HStack {
                                    Spacer()
                                    if Self.sensitivityAnalyzer.analysisPolicy == .simpleInterventions {
                                        Button("Community.post.sensitive-image.show", systemImage: "eye.fill") {
                                            isSensitiveCoverHidden = true
                                        }
                                        .buttonStyle(.bordered)
                                        .foregroundStyle(.white)
                                    } else {
                                        Image(systemName: .eyeSlashFill)
                                            .foregroundStyle(.gray)
                                            .allowsHitTesting(false)
                                    }
                                }
                            }
                        }
                        .padding(5)
                    }
                }
            }
            .sheet(isPresented: $isDescriptiveInterventionPresented) {
                SensitiveContentDescriptiveInterventionView {
                    isSensitiveCoverHidden = true
                }
            }
    }
}

private struct SensitiveContentDescriptiveInterventionView: View {
    var continueAction: () -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack {
                Text(verbatim: "🤔")
                    .font(.system(size: 85))
                    .padding(.bottom)
                Text("Sensitive-content.descriptive.page1.title")
                    .font(.title2)
                    .bold()
                    .padding(.bottom)
                Label {
                    Text("Sensitive-content.descriptive.page1.description.1")
                        .foregroundStyle(.secondary)
                } icon: {
                    Text(verbatim: "🙈")
                        .font(.title)
                }
                Label {
                    Text("Sensitive-content.descriptive.page1.description.2")
                        .foregroundStyle(.secondary)
                } icon: {
                    Text(verbatim: "😨")
                        .font(.title)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Text("Sensitive-content.descriptive.page1.cancel")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                .wrapIf(true) { content in
                    #if !os(visionOS)
                    if #available(iOS 26.0, macOS 26.0, *) {
                        content
                            .buttonStyle(.glassProminent)
                    } else {
                        content
                            .buttonStyle(.borderedProminent)
                    }
                    #else
                    content
                        .buttonStyle(.borderedProminent)
                    #endif
                }
                Link(destination: URL(string: "https://www.apple.com/child-safety/rc-u13/")!) {
                    HStack {
                        Spacer()
                        Text("Sensitive-content.descriptive.page1.view-resources")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
                NavigationLink {
                    VStack {
                        Text(verbatim: "🧐")
                            .font(.system(size: 85))
                            .padding(.bottom)
                        Text("Sensitive-content.descriptive.page2.title")
                            .font(.title2)
                            .bold()
                            .padding(.bottom)
                        Label {
                            Text("Sensitive-content.descriptive.page2.description.1")
                                .foregroundStyle(.secondary)
                        } icon: {
                            Text(verbatim: "👯")
                                .font(.title)
                        }
                        Label {
                            Text("Sensitive-content.descriptive.page2.description.2")
                                .foregroundStyle(.secondary)
                        } icon: {
                            Text(verbatim: "🙊")
                                .font(.title)
                        }
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Sensitive-content.descriptive.page2.cancel")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.vertical, 10)
                        }
                        .wrapIf(true) { content in
                            #if !os(visionOS)
                            if #available(iOS 26.0, macOS 26.0, *) {
                                content
                                    .buttonStyle(.glassProminent)
                            } else {
                                content
                                    .buttonStyle(.borderedProminent)
                            }
                            #else
                            content
                                .buttonStyle(.borderedProminent)
                            #endif
                        }
                        Button {
                            continueAction()
                            dismiss()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Sensitive-content.descriptive.page2.continue")
                                    .fontWeight(.semibold)
                                Spacer()
                            }
                            .padding(.vertical, 10)
                        }
                    }
                    .padding()
                    .padding(.horizontal)
                    .wrapIf(true) { content in
                        #if !os(visionOS)
                        if #available(iOS 26.0, macOS 26.0, *) {
                            content
                                .buttonStyle(.glass)
                        } else {
                            content
                                .buttonStyle(.borderless)
                        }
                        #else
                        content
                            .buttonStyle(.borderless)
                        #endif
                    }
                    .toolbar {
                        ToolbarItem {
                            Button("Sensitive-content.descriptive.dismiss", systemImage: "xmark") {
                                dismiss()
                            }
                        }
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text("Sensitive-content.descriptive.page1.continue")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding(.vertical, 10)
                }
            }
            .padding()
            .padding(.horizontal)
            .wrapIf(true) { content in
                #if !os(visionOS)
                if #available(iOS 26.0, macOS 26.0, *) {
                    content
                        .buttonStyle(.glass)
                } else {
                    content
                        .buttonStyle(.borderless)
                }
                #else
                content
                    .buttonStyle(.borderless)
                #endif
            }
            .toolbar {
                ToolbarItem {
                    Button("Sensitive-content.descriptive.dismiss", systemImage: "xmark") {
                        dismiss()
                    }
                }
            }
        }
    }
}
