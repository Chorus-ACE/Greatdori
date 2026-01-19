//===---*- Greatdori! -*---------------------------------------------------===//
//
// CharacterSearchView.swift
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
#if os(iOS)
import UIKit
#endif

fileprivate let bandLogoScaleFactor: CGFloat = 1.2
fileprivate let charVisualImageCornerRadius: CGFloat = 10


//MARK: CharacterSearchView
struct CharacterSearchView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Namespace var detailNavigation
    @State var charactersDict: DoriFrontend.Characters.CategorizedCharacters?
    @State var allCharacters: [PreviewCharacter]? = nil
    @State var bandArray: [Band?] = []
    @State var infoIsAvailable = true
    @State var infoIsReady = false
    @State var otherCharacters: [PreviewCharacter] = []
    @State var characterIDMap: [PreviewCharacter: Int64] = [:]
    var body: some View {
        Group {
            if infoIsReady {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
                            ForEach(bandArray, id: \.self) { band in
                                if let band {
                                    WebImage(url: band.logoImageURL)
                                        .resizable()
                                        .frame(width: 160*bandLogoScaleFactor, height: 76*bandLogoScaleFactor)
                                        .accessibilityElement()
                                        .accessibilityLabel(band.bandName.forPreferredLocale() ?? String(localized: "Band.unknown"))
                                        .accessibilityAddTraits([.isImage, .isHeader])
                                    HStack {
                                        ForEach(charactersDict![band]!.swappedAt(0, 3).swappedAt(2, 3), id: \.self) { char in
                                            NavigationLink(destination: {
                                                CharacterDetailView(id: char.id, allCharacters: allCharacters)
                                                #if !os(macOS)
                                                    .wrapIf(true, in: { content in
                                                        if #available(iOS 18.0, *) {
                                                            content
                                                                .navigationTransition(.zoom(sourceID: char.id, in: detailNavigation))
                                                                .onDisappear {
                                                                    characterIDMap.updateValue(
                                                                        Int64(CFAbsoluteTimeGetCurrent() * 1000),
                                                                        forKey: char
                                                                    )
                                                                }
                                                        } else {
                                                            content
                                                        }
                                                    })
                                                #endif
                                            }, label: {
                                                CharacterImageView(character: char)
                                            })
                                            .buttonStyle(.plain)
                                            .id(characterIDMap[char] ?? Int64(char.hashValue))
                                            .wrapIf(true, in: { content in
                                                if #available(iOS 18.0, macOS 15.0, *) {
                                                    content
                                                        .matchedTransitionSource(id: char.id, in: detailNavigation)
                                                    
                                                } else {
                                                    content
                                                }
                                            })
                                            .accessibilityLabel(char.characterName.forPreferredLocale() ?? "")
                                        }
                                    }
                                    if sizeClass == .regular {
                                        Rectangle()
                                            .frame(width: 0, height: 20)
                                    }
                                }
                            }
                            if !otherCharacters.isEmpty {
                                DetailSectionsSpacer()
                                HStack {
                                    Text("Characters.search.others")
                                        .font(.title2)
                                        .bold()
                                    Spacer()
                                }
                                .frame(maxWidth: 675)
                                LazyVGrid(columns: [.init(.flexible(minimum: 40)), .init(.flexible(minimum: 40))]) {
                                    ForEach(otherCharacters, id: \.self) { item in
                                        NavigationLink(destination: {
                                            CharacterDetailView(id: item.id, allCharacters: allCharacters)
                                        }, label: {
                                            CustomGroupBox {
                                                HStack {
                                                    Spacer()
                                                    Text(item.characterName.forPreferredLocale() ?? String(localized: "Character.unknown"))
                                                        .font(isMACOS ? .title3 : .body)
                                                        .multilineTextAlignment(.center)
                                                    Spacer()
                                                }
                                                .frame(minHeight: 40)
                                            }
                                        })
                                        .buttonStyle(.plain)
                                    }
                                }
                                .frame(maxWidth: 650)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal)
                }
            } else {
                if infoIsAvailable {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        Spacer()
                    }
                } else {
                    ContentUnavailableView("Character.search.unavailable", systemImage: "person.2.fill", description: Text("Search.unavailable.description"))
                        .onTapGesture {
                            Task {
                                await getCharacters()
                            }
                        }
                }
            }
        }
        .navigationTitle("Character")
        .wrapIf(isMACOS && bandArray.count > 0, in: { content in
            if #available(iOS 26.0, macOS 26.0, *) {
                content
                    .navigationSubtitle("Character.band.count.\(bandArray.count-1)")
            } else {
                content
            }
        })
        .task {
            await getCharacters()
        }
        .withSystemBackground()
    }
    
    func getCharacters() async {
        infoIsAvailable = true
        DoriCache.withCache(id: "CharacterList") {
            await Character.categorized()
        } .onUpdate {
            if let characters = $0 {
                self.charactersDict = characters
                bandArray = []
                if let charactersDict {
                    for (key, _) in charactersDict {
                        bandArray.append(key)
                    }
                    bandArray.sort { ($0?.id ?? 9999) < ($1?.id ?? 9999) }
                }
                otherCharacters = characters[nil] ?? []
                infoIsReady = true
            } else {
                infoIsAvailable = false
            }
        }
        
        DoriCache.withCache(id: "AllCharacters", trait: .realTime) {
            await Character.all()
        } .onUpdate {
            if let characters = $0 {
                allCharacters = characters
            }
        }
    }
    
    struct CharacterImageView: View {
        var character: PreviewCharacter
        @Environment(\.horizontalSizeClass) var sizeClass
        @State var isHovering = false
        var body: some View {
            Group {
                if sizeClass == .regular {
                    ZStack {
                        RoundedRectangle(cornerRadius: charVisualImageCornerRadius)
                            .foregroundStyle(character.color ?? .gray)
                        WebImage(url: character.keyVisualImageURL)
                            .resizable()
                            .scaledToFill()
                            .scaleEffect(isHovering ? 1.05 : 1)
                    }
                    .frame(width: 122, height: 480)
                } else {
                    RoundedRectangle(cornerRadius: charVisualImageCornerRadius)
                        .foregroundStyle(character.color ?? .gray)
                        .aspectRatio(122 / 480, contentMode: .fill)
                        .overlay {
                            WebImage(url: character.keyVisualImageURL)
                                .resizable()
                                .scaledToFill()
                                .clipped()
                                .scaleEffect(isHovering ? 1.05 : 1)
                        }
                }
            }
            .mask {
                RoundedRectangle(cornerRadius: charVisualImageCornerRadius)
                    .aspectRatio(122/480, contentMode: .fill)
            }
            .animation(.spring(duration: 0.3, bounce: 0.1, blendDuration: 0), value: isHovering)
            .onHover { hovering in
                isHovering = hovering
            }
            .contentShape(RoundedRectangle(cornerRadius: charVisualImageCornerRadius))
        }
    }
}
