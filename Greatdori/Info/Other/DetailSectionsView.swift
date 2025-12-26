//===---*- Greatdori! -*---------------------------------------------------===//
//
// ListSectionsView.swift
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
#if os(macOS)
import QuickLook
#endif


// MARK: DetailSectionsSpacer
struct DetailSectionsSpacer: View {
    var height: CGFloat = 30
    var body: some View {
        Rectangle()
            .opacity(0)
            .frame(height: height)
    }
}


// MARK: DetailSectionOptionPicker
struct DetailSectionOptionPicker<T: Hashable>: View {
    @Binding var selection: T
    var options: [T]
    var labels: [T: String]? = nil
    var body: some View {
        Menu(content: {
            Picker(selection: $selection, content: {
                ForEach(options, id: \.self) { item in
                    Text(labels?[item] ?? ((T.self == DoriLocale.self) ? "\(item)".uppercased() : "\(item)"))
                        .tag(item)
                }
            }, label: {
                Text("")
            })
            .pickerStyle(.inline)
            .labelsHidden()
            .multilineTextAlignment(.leading)
        }, label: {
            Text(getAttributedString(labels?[selection] ?? ((T.self == DoriLocale.self) ? "\(selection)".uppercased() : "\(selection)"), fontSize: .title2, fontWeight: .semibold, foregroundColor: .accent))
        })
        .menuIndicator(.hidden)
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
    }
}

// MARK: DetailUnavailableView
struct DetailUnavailableView: View {
    var title: LocalizedStringResource
    var symbol: String
    var body: some View {
        CustomGroupBox {
            HStack {
                Spacer()
                VStack {
                    Image(fallingSystemName: symbol)
                        .font(.largeTitle)
                        .padding(.top, 2)
                        .padding(.bottom, 1)
                    Text(title)
                        .font(.title2)
                        .padding(.bottom, 2)
                }
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
                Spacer()
            }
        }
    }
}
