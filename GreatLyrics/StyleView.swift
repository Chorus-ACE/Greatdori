//===---*- Greatdori! -*---------------------------------------------------===//
//
// StyleView.swift
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

struct StyleView: View {
    @Binding var lyrics: Lyrics
    @State var presetStyles = [Lyrics.Style]()
    var body: some View {
        Form {
            Section {
                if !presetStyles.isEmpty {
                    ForEach(Array(presetStyles.enumerated()), id: \.element.id) { (index, style) in
                        NavigationLink(value: index) {
                            HStack {
                                TextStyleRender(text: "迷い星のうた", style: style)
                                Spacer()
                                if lyrics.mainStyle?.id == style.id {
                                    Text("Main")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.green)
                                        .padding(2)
                                        .padding(.horizontal, 3)
                                        .background {
                                            RoundedRectangle(cornerRadius: 4)
                                                .strokeBorder(Color.green)
                                        }
                                        .contextMenu {
                                            Button("Remove Main Style") {
                                                lyrics.mainStyle = nil
                                            }
                                        }
                                } else {
                                    Button("Set as Main") {
                                        lyrics.mainStyle = style
                                    }
                                }
                            }
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        Text("No Presets")
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                }
                HStack {
                    Button {
                        presetStyles.append(.init(color: Color.primary))
                        savePresets()
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.primary)
                    }
                }
                .buttonStyle(.borderless)
                .listRowInsets(.init())
            } header: {
                Text("Presets")
            }
        }
        .formStyle(.grouped)
        .navigationSubtitle("Style")
        .navigationDestination(for: Int.self) { index in
            StyleEditorView(style: presetStyles[index]) { newStyle in
                presetStyles[index] = newStyle
                savePresets()
            }
        }
        .task {
            let decoder = PropertyListDecoder()
            let source = URL(filePath: NSHomeDirectory() + "/Documents/StylePresets.plist")
            if let _data = try? Data(contentsOf: source),
               let presets = try? decoder.decode([Lyrics.Style].self, from: _data) {
                presetStyles = presets
            }
        }
    }
    
    func savePresets() {
        let encoder = PropertyListEncoder()
        let destination = URL(filePath: NSHomeDirectory() + "/Documents/StylePresets.plist")
        try? encoder.encode(presetStyles).write(to: destination)
    }
}
