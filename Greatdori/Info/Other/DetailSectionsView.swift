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

// MARK: DetailSectionDoubleOptionPicker
struct DetailSectionDoubleOptionPicker<T: Hashable, S: Hashable>: View {
    @Binding var pSelection: T
    @Binding var sSelection: S
    var pOptions: [T]
    var sOptions: [S]
    var pLabels: [T: String]? = nil
    var sLabels: [S: String]? = nil
    
    @State var showSecondaryLabel = false
    var body: some View {
        Menu(content: {
            Picker(selection: $pSelection, content: {
                ForEach(pOptions, id: \.self) { item in
                    Text(pLabels?[item] ?? ((T.self == DoriLocale.self) ? "\(item)".uppercased() : "\(item)"))
                        .tag(item)
                }
            }, label: {
                Text("")
            })
            .pickerStyle(.inline)
            .labelsHidden()
            .multilineTextAlignment(.leading)
            
            Picker(selection: $sSelection, content: {
                ForEach(sOptions, id: \.self) { item in
                    Text(sLabels?[item] ?? ((S.self == DoriLocale.self) ? "\(item)".uppercased() : "\(item)"))
                        .tag(item)
                }
            }, label: {
                Text("")
            })
            .pickerStyle(.inline)
            .labelsHidden()
            .multilineTextAlignment(.leading)
        }, label: {
            ZStack(alignment: .leading) {
//                if showSecondaryLabel {
                    Text(getAttributedString(sLabels?[sSelection] ?? ((S.self == DoriLocale.self) ? "\(sSelection)".uppercased() : "\(sSelection)"), fontSize: .title2, fontWeight: .semibold, foregroundColor: .accent))
                        .transition(.opacity)
                        .opacity(showSecondaryLabel ? 1 : 0)
                        .id("s")
//                } else {
                    Text(getAttributedString(pLabels?[pSelection] ?? ((T.self == DoriLocale.self) ? "\(pSelection)".uppercased() : "\(pSelection)"), fontSize: .title2, fontWeight: .semibold, foregroundColor: .accent))
                        .transition(.opacity)
                        .opacity(showSecondaryLabel ? 0 : 1)
                        .id("p")
//                }
            }
            .animation(.easeIn(duration: 0.2), value: showSecondaryLabel)
            .onChange(of: showSecondaryLabel, {
                if showSecondaryLabel {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showSecondaryLabel = false
                    }
                }
            })
        })
        .menuIndicator(.hidden)
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
        .onChange(of: pSelection) {
            showSecondaryLabel = true
        }
        .onChange(of: sSelection) {
            showSecondaryLabel = true
        }
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


