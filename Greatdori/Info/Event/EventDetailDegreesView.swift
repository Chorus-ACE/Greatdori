//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventDetailDegreesView.swift
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

struct EventDetailDegreesView: View {
    var information: ExtendedEvent
    @State private var locale = DoriLocale.primaryLocale
    @State private var isExpanded = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section {
                if information.degrees.first?.first?.baseImageName.forLocale(locale) != nil {
                    CustomGroupBox {
                        VStack {
                            if isExpanded {
                                    ForEach(0..<information.degrees.count, id: \.self) { i in
                                        let degrees = information.degrees[i]
                                        HStack {
                                            Spacer()
                                            WrappingHStack(alignment: .leading) {
                                                ForEach(degrees) { degree in
                                                    DegreeView(degree)
                                                        .frame(width: 140)
                                                }
                                            }
                                            Spacer()
                                        }
                                    }
                                    .insert {
                                        Spacer()
                                            .frame(height: 30)
                                    }
                            } else {
                                HStack {
                                    Spacer()
                                    DegreeView(information.degrees.first!.first!)
                                        .frame(width: 140)
                                    Spacer()
                                }
                            }
                        }
                    }
                } else {
                    DetailUnavailableView(title: "Details.unavailable.degree", symbol: "medal.star")
                }
            } header: {
                HStack {
                    Text("Event.degree")
                        .font(.title2)
                        .bold()
                    DetailSectionOptionPicker(selection: $locale, options: DoriLocale.allCases)
                    Spacer()
                    Button(action: {
                        isExpanded.toggle()
                    }, label: {
                        Text(isExpanded ? "Details.show-less" : "Details.show-all")
                            .foregroundStyle(.secondary)
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: infoContentMaxWidth)
    }
}

struct DegreeView: View {
    var degree: Degree
    
    init(_ degree: Degree) {
        self.degree = degree
    }
    
    @State private var baseSize = CGSize.zero
    
    var body: some View {
        ZStack(alignment: .trailing) {
            WebImage(url: degree.baseImageURL)
                .resizable()
                .scaledToFit()
                .onFrameChange { geometry in
                    baseSize = geometry.size
                }
            if let url = degree.rankImageURL {
                WebImage(url: url)
                    .resizable()
                    .scaledToFit()
                    .frame(height: baseSize.height)
            }
            if let url = degree.iconImageURL {
                HStack {
                    WebImage(url: url)
                        .resizable()
                        .scaledToFit()
                        .frame(height: baseSize.height)
                    Spacer()
                }
            }
        }
    }
}
