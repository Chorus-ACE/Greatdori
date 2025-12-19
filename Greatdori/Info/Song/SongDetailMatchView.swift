//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongDetailMatchView.swift
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
import SDWebImageSwiftUI

struct SongDetailMatchView: View {
    var song: Song
    @Binding var songMatches: [Int: _DoriFrontend.Songs._SongMatchResult]?
    @Environment(\.openURL) private var openURL
    @State private var isReportPresented = false
    var body: some View {
        Group {
            if let songMatches,
               let matchResult = songMatches.first(where: { $0.key == song.id })?.value,
               case let .some(results) = matchResult, !results.isEmpty {
                LazyVStack(pinnedViews: .sectionHeaders) {
                    Section {
                        ForEach(results, id: \.self) { result in
                            Button(action: {
                                if let url = result.appleMusicURL {
                                    openURL(url)
                                } else if let url = result.webURL {
                                    openURL(url)
                                }
                            }, label: {
                                CustomGroupBox {
                                    VStack(alignment: .leading) {
                                        HStack {
                                            WebImage(url: result.artworkURL) { image in
                                                image
                                            } placeholder: {
                                                Rectangle()
                                                    .fill(Color.secondary)
                                            }
                                            .resizable()
                                            .cornerRadius(5)
                                            .scaledToFit()
                                            .frame(width: 100, height: 100)
                                            .padding(.trailing, 3)
                                            
                                            VStack(alignment: .leading) {
                                                Text(result.title ?? "")
                                                Group {
                                                    Text(result.artist ?? "") + Text(verbatim: " · ") + Text(result.appleMusicURL != nil ? "Song.shazam.apple-music" : "Song.shazam.shazam")
                                                }
                                                .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            if result.appleMusicURL != nil || result.webURL != nil {
                                                Image(systemName: "arrow.up.forward.app")
                                                    .foregroundStyle(.secondary)
                                                    .font(.title3)
                                            }
                                        }
                                    }
                                }
                            })
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: infoContentMaxWidth)
                    } header: {
                        HStack {
                            Text("Song.shazam")
                                .font(.title2)
                                .bold()
                            Spacer()
                            Button("Report a Concern", systemImage: "exclamationmark.bubble") {
                                isReportPresented = true
                            }
                            .labelStyle(.iconOnly)
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: 615)
                    }
                }
                .sheet(isPresented: $isReportPresented) {
                    NavigationStack {
                        SongMatchReportView(song: song)
                    }
                }
            }
        }
    }
}

private struct SongMatchReportView: View {
    var song: Song
    @Environment(\.dismiss) private var dismiss
    @State private var selectedConcern: ConcernType?
    @State private var isSubmitting = false
    var body: some View {
        Form {
            Picker("What's your concern with this content?", selection: $selectedConcern) {
                ForEach(ConcernType.allCases, id: \.rawValue) { concern in
                    Text(concern.localizedString).tag(concern)
                }
            }
            .pickerStyle(.inline)
        }
        .formStyle(.grouped)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel", systemImage: "xmark") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    Task {
                        guard let selectedConcern else { return }
                        isSubmitting = true
                        await submitCombinedStats(
                            key: "SongShazamReport_\(song.id)",
                            subKey: selectedConcern.rawValue,
                            action: true /* +1 */
                        )
                        isSubmitting = false
                        dismiss()
                    }
                } label: {
                    if !isSubmitting {
                        Label("Submit", systemImage: "checkmark")
                    } else {
                        ProgressView()
                            .controlSize(.small)
                    }
                }
                #if os(iOS)
                .wrapIf(true) { content in
                    if #available(iOS 26.0, *) {
                        content
                            .buttonStyle(.glassProminent)
                    } else {
                        content
                    }
                }
                #endif
                .disabled(selectedConcern == nil || isSubmitting)
            }
        }
    }
    
    // Please don't change the Swift name of cases here,
    // feel free to add new ones.
    enum ConcernType: String, Hashable, CaseIterable {
        case incorrectResult
        case incorrectVersion
        case incorrectMetadata
        case missingAppleMusicLink
        case other
        
        var localizedString: LocalizedStringResource {
            switch self {
            case .incorrectResult: "Incorrect music"
            case .incorrectVersion: "Incorrect cover"
            case .incorrectMetadata: "Incorrect metadata (title, artist, artwork, etc.)"
            case .missingAppleMusicLink: "Apple Music link not available"
            case .other: "My concern is not listed here"
            }
        }
    }
}
