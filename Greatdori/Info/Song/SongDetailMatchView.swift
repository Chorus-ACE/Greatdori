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
import SymbolAvailability

struct SongDetailMatchView: View {
    var song: Song
    @Binding var songMatches: [Int: DoriFrontend.Songs._NeoSongMatchResult]?
    @Environment(\.openURL) private var openURL
    @State private var isReportPresented = false
    var body: some View {
        if let songMatches,
           let matchResult = songMatches.first(where: { $0.key == song.id })?.value,
           case let .success(results) = matchResult, !results.isEmpty {
            Section {
                ForEach(results, id: \.self) { result in
                    Button(action: {
                        if let url = result.appleMusicURL {
                            openURL(url)
                        } else if let url = result.shazamURL {
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
                                        Text(result.title(preferEN: DoriLocale.primaryLocale == .en))
                                        Group {
                                            Text(result.artist(preferEN: DoriLocale.primaryLocale == .en)) + Text(verbatim: " · ") + Text(result.appleMusicURL != nil ? "Song.shazam.apple-music" : "Song.shazam.shazam")
                                        }
                                        .lineLimit(3)
                                        .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if result.appleMusicURL != nil || result.shazamURL != nil {
                                        Image(systemName: .arrowUpForwardApp)
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
                    Button(action: {
                        isReportPresented = true
                    }, label: {
                        Text("Song.shazam.report")
                            .foregroundStyle(.secondary)
                    })
                    .buttonStyle(.plain)
                    .sheet(isPresented: $isReportPresented) {
                        NavigationStack {
                            SongMatchReportView(song: song)
                        }
                    }
                }
                .frame(maxWidth: 615)
                .detailSectionHeader()
            }
        }
    }
}

private struct SongMatchReportView: View {
    var song: Song
    @Environment(\.dismiss) private var dismiss
    @State private var selectedConcern: ConcernType?
    @State private var isSubmitting = false
    @State private var isSubmitted = false
    var body: some View {
        Group {
            if !isSubmitted {
                Form {
                    Picker("Song.shazam.report.type", selection: $selectedConcern) {
                        ForEach(ConcernType.allCases, id: \.rawValue) { concern in
                            VStack(alignment: .leading) {
                                Text(concern.label)
                                Text(concern.description)
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            }
                            .tag(concern)
                        }
                    }
                    .pickerStyle(.inline)
                }
                .formStyle(.grouped)
            } else {
                ExtendedConstraints {
                    ContentUnavailableView("Song.shazam.report.sent", systemImage: "paperplane", description: Text("Song.shazam.report.sent.description"))
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    dismiss()
                }, label: {
                    Label("Song.shazam.report.cancel", systemImage: "xmark")
                        .wrapIf(isMACOS, in: {
                            $0.labelStyle(.titleOnly)
                        }, else: {
                            $0.labelStyle(.iconOnly)
                        })
                })
            }
            if !isSubmitted {
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
                            isSubmitted = true
                        }
                    } label: {
                        if !isSubmitting {
                            Label("Song.shazam.report.submit", systemImage: "checkmark")
                                .wrapIf(isMACOS, in: {
                                    $0.labelStyle(.titleOnly)
                                }, else: {
                                    $0.labelStyle(.iconOnly)
                                })
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
    }
    
    // Please don't change the Swift name of cases here,
    // feel free to add new ones.
    enum ConcernType: String, Hashable, CaseIterable {
        case mismatch
        case incorrectVersion
        case incorrectMetadata
        case appleMusicLinkMissing
        case other
        
        var label: LocalizedStringResource {
            switch self {
            case .mismatch: "Song.shazam.report.type.mismatch"
            case .incorrectVersion: "Song.shazam.report.type.version"
            case .incorrectMetadata: "Song.shazam.report.type.metadata"
            case .appleMusicLinkMissing: "Song.shazam.report.type.apple-music-link-missing"
            case .other: "Song.shazam.report.type.metadata.other"
            }
        }
        
        var description: LocalizedStringResource {
            switch self {
            case .mismatch: "Song.shazam.report.type.mismatch.description"
            case .incorrectVersion: "Song.shazam.report.type.version.description"
            case .incorrectMetadata: "Song.shazam.report.type.metadata.description"
            case .appleMusicLinkMissing: "Song.shazam.report.type.apple-music-link-missing.description"
            case .other: "Song.shazam.report.type.metadata.other.description"
            }
        }
    }
}
