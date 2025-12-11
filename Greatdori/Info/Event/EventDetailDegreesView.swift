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
import SwiftUI

struct EventDetailDegreesView: View {
    var information: ExtendedEvent
    @State private var locale = DoriLocale.primaryLocale
    @State var isExpanded = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section {
                if information.degrees.first?.baseImageName.forLocale(locale) != nil {
                    CustomGroupBox {
                        if isExpanded {
                            WrappingHStack(contentWidth: 140) {
                                ForEach(information.degrees) { degree in
                                    DegreeView(degree)
                                        .frame(width: 140)
                                }
                            }
                        } else {
                            HStack {
                                Spacer()
                                DegreeView(information.degrees.first!)
                                    .frame(width: 140)
                                Spacer()
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
