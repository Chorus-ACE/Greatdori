//===---*- Greatdori! -*---------------------------------------------------===//
//
// CharacterSelector.swift
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
@_spi(Advanced) import SwiftUIIntrospect

struct CharacterSelector: View {
    @Binding var selection: PreviewCharacter?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supportsMultipleWindows) private var supportsMultipleWindows
    @State private var allCharacters: [PreviewCharacter]?
    @State private var infoIsAvailable = true
    var body: some View {
        Group {
            Group {
                if let allCharacters {
                    ScrollView {
                        HStack {
                            Spacer(minLength: 0)
                            LazyVGrid(columns: [.init(.adaptive(minimum: 180))]) {
                                ForEach(allCharacters) { character in
                                    Button(action: {
                                        selection = character
                                        dismiss()
                                    }, label: {
                                        CustomGroupBox {
                                            ExtendedConstraints {
                                                HStack {
                                                    WebImage(url: character.iconImageURL) { image in
                                                        image
                                                            .resizable()
                                                            .frame(width: 25, height: 25)
                                                    } placeholder: {
                                                        EmptyView()
                                                    }
                                                    Text(character.characterName.forPreferredLocale() ?? "")
                                                }
                                            }
                                            .padding(.vertical, 5)
                                        }
                                        .groupBoxStrokeLineWidth(selection == character ? 3 : 0)
                                    })
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding()
                            Spacer(minLength: 0)
                        }
                    }
                } else {
                    if infoIsAvailable {
                        ExtendedConstraints {
                            ProgressView()
                        }
                    } else {
                        ExtendedConstraints {
                            ContentUnavailableView("Character.search.unavailable", systemImage: "person.2.fill", description: Text("Search.unavailable.description"))
                        }
                        .onTapGesture {
                            getCharacters()
                        }
                    }
                }
            }
            .navigationTitle("Character")
            .toolbar {
                if !supportsMultipleWindows {
                    ToolbarItem {
                        Button("Done", systemImage: "checkmark") {
                            dismiss()
                        }
                        .wrapIf(true) { content in
                            if #available(iOS 26.0, macOS 26.0, *) {
                                content
                                    .buttonStyle(.glassProminent)
                            }
                        }
                    }
                }
            }
        }
        .withSystemBackground()
        .onAppear {
            getCharacters()
        }
    }
    
    func getCharacters() {
        DoriCache.withCache(id: "AllCharacters", trait: .realTime) {
            await _DoriAPI.Characters.all()
        } .onUpdate {
            if let characters = $0 {
                allCharacters = characters
            }
        }
    }
}

struct CharacterSelectorButton: View {
    @Binding var selection: PreviewCharacter?
    @State private var selectorWindowIsPresented = false
    var body: some View {
        Button(action: {
            selectorWindowIsPresented = true
        }, label: {
            if let selection {
                HStack {
                    Text(selection.characterName.forPreferredLocale() ?? "#\(selection.id)")
                    Image(systemName: "chevron.up.chevron.down")
                        .bold(isMACOS)
                        .font(.footnote)
                }
            } else {
                Text("Selector.prompt.Character")
            }
        })
        .onChange(of: selection) {
            selectorWindowIsPresented = false
        }
        .onDisappear {
            selectorWindowIsPresented = false
        }
        .window(isPresented: $selectorWindowIsPresented) {
            CharacterSelector(selection: $selection)
            #if os(macOS)
                .introspect(.window, on: .macOS(.v14...)) { window in
                    window.standardWindowButton(.zoomButton)?.isEnabled = false
                    window.standardWindowButton(.miniaturizeButton)?.isEnabled = false
                    window.level = .floating
                }
            #endif
        }
    }
}
