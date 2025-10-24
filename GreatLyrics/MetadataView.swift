//===---*- Greatdori! -*---------------------------------------------------===//
//
// MetadataView.swift
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

import SwiftUI
@_private(sourceFile: "FrontendSong.swift") import DoriKit

struct MetadataView: View {
    @Binding var lyrics: Lyrics
    @State var selectedLegendIndex: Int?
    var body: some View {
        Form {
            Section {
                Toggle("Contains Annotation", isOn: .init {
                    lyrics.metadata.annotation != nil
                } set: {
                    lyrics.metadata.annotation = $0 ? "" : nil
                })
                if let text = lyrics.metadata.annotation {
                    TextField("Text", text: .init {
                        text
                    } set: {
                        lyrics.metadata.annotation = $0
                    })
                }
            } header: {
                Text("Annotation")
            }
            Section {
                List(selection: $selectedLegendIndex) {
                    if !lyrics.metadata.legends.isEmpty {
                        ForEach(Array(lyrics.metadata.legends.enumerated()), id: \.element.id) { (index, legend) in
                            HStack {
                                Circle()
                                    .fill(legend.color)
                                    .frame(width: 15, height: 15)
                                Text(legend.text.forPreferredLocale() ?? "[No Text]")
                            }
                            .tag(index)
                        }
                    } else {
                        HStack {
                            Spacer()
                            Text("No Legends")
                                .foregroundStyle(.gray)
                            Spacer()
                        }
                        .padding(.vertical, 5)
                    }
                    HStack {
                        Button {
                            lyrics.metadata.legends.append(.init(color: .cyan, text: .init(jp: nil, en: nil, tw: nil, cn: nil, kr: nil)))
                        } label: {
                            Image(systemName: "plus")
                                .foregroundStyle(Color.primary)
                        }
                        Button {
                            if let index = selectedLegendIndex {
                                lyrics.metadata.legends.remove(at: index)
                            }
                        } label: {
                            Image(systemName: "minus")
                        }
                        .disabled(selectedLegendIndex == nil)
                    }
                    .buttonStyle(.borderless)
                    .listRowInsets(.init())
                }
                if let index = selectedLegendIndex {
                    let legend = lyrics.metadata.legends[index]
                    TextField("Text for JP", text: .init {
                        legend.text.jp ?? ""
                    } set: {
                        lyrics.metadata.legends[index].text.jp = $0.isEmpty ? nil : $0
                    })
                    TextField("Text for EN", text: .init {
                        legend.text.en ?? ""
                    } set: {
                        lyrics.metadata.legends[index].text.en = $0.isEmpty ? nil : $0
                    })
                    TextField("Text for TW", text: .init {
                        legend.text.tw ?? ""
                    } set: {
                        lyrics.metadata.legends[index].text.tw = $0.isEmpty ? nil : $0
                    })
                    TextField("Text for CN", text: .init {
                        legend.text.cn ?? ""
                    } set: {
                        lyrics.metadata.legends[index].text.cn = $0.isEmpty ? nil : $0
                    })
                    TextField("Text for KR", text: .init {
                        legend.text.kr ?? ""
                    } set: {
                        lyrics.metadata.legends[index].text.kr = $0.isEmpty ? nil : $0
                    })
                    ColorPicker("Color", selection: .init {
                        legend.color
                    } set: {
                        lyrics.metadata.legends[index].color = $0
                    })
                }
            } header: {
                Text("Legends")
            }
        }
        .formStyle(.grouped)
        .navigationSubtitle("Metadata")
    }
}
