//===---*- Greatdori! -*---------------------------------------------------===//
//
// ComicDetailComicView.swift
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

struct ComicDetailComicView: View {
    var information: Comic
    @State var locale: DoriLocale = .primaryLocale
    @State var comicLoadingHadFailed = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section {
                WebImage(url: information.imageURL(in: locale, allowsFallback: false), content: { image in
                    image
                        .resizable()
                        .scaledToFit()
                }, placeholder: {
                    if !comicLoadingHadFailed {
                        CustomGroupBox {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                    } else {
                        DetailUnavailableView(title: "Details.unavailable.\(Comic.singularName)", symbol: Comic.symbol)
                    }
                }).onFailure { _ in
                    comicLoadingHadFailed = true
                }
                .imageContextMenu([.init(url: information.imageURL(in: locale, allowsFallback: false) ?? .init(filePath: "/"))])
                .frame(maxWidth: infoContentMaxWidth)
                .onChange(of: locale) {
                    comicLoadingHadFailed = false
                }
            } header: {
                HStack {
                    Text("Comic.comic")
                        .font(.title2)
                        .bold()
                    DetailSectionOptionPicker(selection: $locale, options: DoriLocale.allCases)
                    Spacer()
                }
                .frame(maxWidth: 615)
            }
        }
    }
}
