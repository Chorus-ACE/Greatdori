//===---*- Greatdori! -*---------------------------------------------------===//
//
// ComicDetailView.swift
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

struct ComicDetailView: View {
    var id: Int
    var allComics: [Comic]? = nil
    var body: some View {
        DetailViewBase(forType: Comic.self, previewList: allComics, initialID: id) { information in
            ComicDetailOverviewView(information: information)
            ComicDetailComicView(information: information)
            
            DetailArtsSection {
                ArtsTab("Comic.arts.thumb") {
                    for locale in DoriLocale.allCases {
                        if let url = information.thumbImageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url)
                        }
                    }
                }
                ArtsTab("Comic.arts.comic") {
                    for locale in DoriLocale.allCases {
                        if let url = information.imageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url)
                        }
                    }
                }
            }
        } switcherDestination: {
            ComicSearchView()
        }
    }
}

struct ComicDetailOverviewView: View {
    let information: Comic
    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
    var body: some View {
        VStack {
            CustomGroupBox {
                LazyVStack {
                    Group {
                        ListItem {
                            Text("Comic.title")
                        } value: {
                            MultilingualText(information.title)
                        }
                        Divider()
                    }
                    
                    Group {
                        ListItem {
                            Text("Comic.subtitle")
                        } value: {
                            MultilingualText(information.subTitle)
                        }
                        Divider()
                    }
                    
                    if let type = information.type {
                        Group {
                            ListItem {
                                Text("Comic.type")
                            } value: {
                                Text(type.localizedString)
                            }
                            Divider()
                        }
                    }
                    
                    // MARK: Release Date
                    Group {
                        ListItem {
                            Text("Comic.character")
                        } value: {
                            ForEach(information.characterIDs, id: \.self) { id in
                                #if os(macOS)
                                NavigationLink(destination: {
                                    CharacterDetailView(id: id)
                                }, label: {
                                    WebImage(url: .init(string: "https://bestdori.com/res/icon/chara_icon_\(id).png"))
                                        .antialiased(true)
                                        .resizable()
                                        .frame(width: imageButtonSize, height: imageButtonSize)
                                })
                                .buttonStyle(.plain)
                                #else
                                Menu(content: {
                                    NavigationLink(destination: {
                                        CharacterDetailView(id: id)
                                    }, label: {
                                        HStack {
                                            WebImage(url: .init(string: "https://bestdori.com/res/icon/chara_icon_\(id).png"))
                                                .antialiased(true)
                                                .resizable()
                                                .frame(width: imageButtonSize, height: imageButtonSize)
                                            if let name = PreCache.current.characters.first(where: { $0.id == id })?.characterName.forPreferredLocale() {
                                                Text(name)
                                            } else {
                                                Text(verbatim: "Lorum Ipsum")
                                                    .foregroundStyle(Color(UIColor.placeholderText))
                                                    .redacted(reason: .placeholder)
                                            }
                                        }
                                    })
                                }, label: {
                                    WebImage(url: .init(string: "https://bestdori.com/res/icon/chara_icon_\(id).png"))
                                        .antialiased(true)
                                        .resizable()
                                        .frame(width: imageButtonSize, height: imageButtonSize)
                                })
                                #endif
                            }
                        }
                        Divider()
                    }
                    
                    ListItem {
                        Text("ID")
                    } value: {
                        Text("\(String(information.id))")
                    }
                }
            }
        }
        .frame(maxWidth: infoContentMaxWidth)
    }
}

struct ComicDetailComicView: View {
    var information: Comic
    @State var locale: DoriLocale = .primaryLocale
    @State var comicLoadingHadFailed = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
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
                .frame(maxWidth: infoContentMaxWidth)
                .onChange(of: locale) {
                    comicLoadingHadFailed = false
                }
            }, header: {
                HStack {
                    Text("Comic.comic")
                        .font(.title2)
                        .bold()
                    DetailSectionOptionPicker(selection: $locale, options: DoriLocale.allCases)
                    Spacer()
                }
                .frame(maxWidth: 615)
            })
        }
    }
}
