//===---*- Greatdori! -*---------------------------------------------------===//
//
// CharacterListView.swift
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
import DoriKit
import SDWebImageSwiftUI

struct CharacterListView: View {
    @State var characters: CategorizedCharacters?
    @State var availability = true
    var body: some View {
        List {
            if let characters {
                let bands = characters.keys.sorted {
                    if let lhs = $0 {
                        if let rhs = $1 {
                            lhs.id < rhs.id
                        } else {
                            true
                        }
                    } else {
                        false
                    }
                }
                ForEach(bands, id: \.?.id) { band in
                    if let band {
                        Section {
                            ForEach(characters[band]!) { character in
                                NavigationLink(destination: { CharacterDetailView(id: character.id) }) {
                                    HStack {
                                        WebImage(url: character.iconImageURL)
                                            .resizable()
                                            .clipShape(Circle())
                                            .frame(width: 30, height: 30)
                                        Text(character.characterName.forPreferredLocale() ?? "")
                                    }
                                }
                            }
                        } header: {
                            Text(band.bandName.forPreferredLocale() ?? "")
                        }
                    } else {
                        Section {
                            ForEach(characters[nil]!) { character in
                                NavigationLink(destination: { CharacterDetailView(id: character.id) }) {
                                    HStack {
                                        Text(character.characterName.forPreferredLocale() ?? "")
                                    }
                                }
                            }
                        } header: {
                            Text("其他")
                        }
                    }
                }
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入角色时出错", systemImage: "person.fill", retryHandler: getCharacters)
                }
            }
        }
        .navigationTitle("角色")
        .task {
            await getCharacters()
        }
    }
    
    func getCharacters() async {
        availability = true
        withDoriCache(id: "CharacterList") {
            await CategorizedCharacters.all()
        }.onUpdate {
            if let characters = $0 {
                self.characters = characters
            } else {
                availability = false
            }
        }
    }
}
