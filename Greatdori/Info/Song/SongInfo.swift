//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongInfo.swift
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
import SDWebImageSwiftUI
import SwiftUI


// MARK: SongInfo
struct SongInfo: View {
    @State var information: PreviewSong
    @State var bandName: String = "Lorem Ipsum Dolor"
    var subtitle: LocalizedStringKey? = nil
    var layout: SummaryLayout
    
    init(_ song: PreviewSong, subtitle: LocalizedStringKey? = nil, layout: SummaryLayout = .horizontal) {
        self.information = song
        self.subtitle = subtitle
        self.layout = layout
    }
    
    init(_ song: Song, subtitle: LocalizedStringKey? = nil, layout: SummaryLayout = .horizontal) {
        self.information = PreviewSong(song)
        self.subtitle = subtitle
        self.layout = layout
    }
    
    let horizontalLayoutCoverSideLength: CGFloat = 110
    let verticalLayoutCoverSideLength: CGFloat = 120
    
    var body: some View {
        SummaryViewBase(layout, source: information) {
            WebImage(url: information.jacketImageURL) { image in
                image
                    .resizable()
                    .antialiased(true)
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: (layout == .horizontal ? horizontalLayoutCoverSideLength : verticalLayoutCoverSideLength), height: (layout == .horizontal ? horizontalLayoutCoverSideLength : verticalLayoutCoverSideLength))
                    .cornerRadius(5)
            } placeholder: {
                RoundedRectangle(cornerRadius: 5)
                    .fill(getPlaceholderColor())
                    .frame(width: (layout == .horizontal ? horizontalLayoutCoverSideLength : verticalLayoutCoverSideLength), height: (layout == .horizontal ? horizontalLayoutCoverSideLength : verticalLayoutCoverSideLength))
            }
            .interpolation(.high)
        } detail: {
            Text(bandName)
                .font(isMACOS ? .body : .caption)
                .wrapIf(bandName == "Lorem Ipsum", in: { content in
                    Text(bandName)
                        .redacted(reason: .placeholder)
                })
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
            }
            SongDifficultiesIndicator(information.difficulty)
                .foregroundStyle(.primary)
                .preferHiddenInCompactLayout()
        }
        .onAppear {
            bandName = DoriCache.preCache.bands.first { $0.id == information.bandID }?.bandName.forPreferredLocale() ?? "Lorem Ipsum"
            if bandName == "Lorem Ipsum" {
                Task {
                    let allBands = await Band.all()
                    bandName = allBands?.first{ $0.id == information.bandID }?.bandName.forPreferredLocale() ?? "Lorem Ipsum"
                }
            }
        }
    }
}
