//===---*- Greatdori! -*---------------------------------------------------===//
//
// ComicInfo.swift
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


// MARK: ComicInfo
struct ComicInfo: View {
    @State var information: Comic
    var layout: SummaryLayout
    
    init(_ comic: Comic, layout: SummaryLayout = .horizontal) {
        self.information = comic
        self.layout = layout
    }
    
    var body: some View {
        SummaryViewBase(layout, source: information) {
            WebImage(url: information.thumbImageURL) { image in
                image
                    .resizable()
                    .antialiased(true)
                    .aspectRatio(184/134, contentMode: .fit)
                    .frame(width: 184, height: 134)
                    .cornerRadius(5)
            } placeholder: {
                RoundedRectangle(cornerRadius: 5)
                    .fill(getPlaceholderColor())
                    .frame(width: 184, height: 134)
            }
            .interpolation(.high)
        } detail: {
            if let type = information.type {
                Text(type.localizedString)
                    .font(isMACOS ? .body : .caption)
            }
        }
    }
}
