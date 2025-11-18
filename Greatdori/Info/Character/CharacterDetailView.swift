//===---*- Greatdori! -*---------------------------------------------------===//
//
// CharacterDetail.swift
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


//MARK: CharacterDetailView
struct CharacterDetailView: View {
    private let randomCardScalingFactor: CGFloat = 1
    var id: Int
    var allCharacters: [PreviewCharacter]? = nil
    @Environment(\.horizontalSizeClass) var sizeClass
    @State var allCharacterIDs: [Int] = []
    @State var currentID: Int = 0
    @State var informationLoadPromise: DoriCache.Promise<ExtendedCharacter?>?
    @State var information: ExtendedCharacter?
    @State var infoIsAvailable = true
    @State var cardNavigationDestinationID: Int?
    @State var randomCard: PreviewCard?
    @State var showSubtitle: Bool = false
    @State var randomCardHadUpdatedOnce = false
    var body: some View {
        Group {
            if let information {
                ScrollView {
                    VStack {
                        HStack {
                            Spacer(minLength: 0)
                            VStack {
                                if let randomCard, information.band != nil {
                                    CardCoverImage(randomCard, band: information.band!)
                                        .wrapIf(sizeClass == .regular) { content in
                                            content
                                                .frame(maxWidth: 480*randomCardScalingFactor, maxHeight: 320*randomCardScalingFactor)
                                        } else: { content in
                                            content
                                                .padding(.horizontal, -15)
                                        }
                                }
                                if randomCard != nil && information.band != nil {
                                    Button(action: {
                                        randomCard = information.randomCard()!
                                    }, label: {
                                        Label("Character.random-card", systemImage: "arrow.clockwise")
                                    })
                                    .wrapIf(true) { content in
                                        if #available(iOS 26.0, macOS 26.0, *) {
                                            content
                                                .buttonStyle(.glass)
                                        } else {
                                            content
                                                .buttonStyle(.bordered)
                                        }
                                    }
                                    .buttonBorderShape(.capsule)
                                }
                            }
                            .padding(.horizontal)
                            Spacer(minLength: 0)
                        }
                        CharacterDetailOverviewView(information: information)
                        //                        if !information.cards.isEmpty {
                        Rectangle()
                            .opacity(0)
                            .frame(height: 30)
                        DetailsCardsSection(cards: information.cards)
                        //                        }
                        //                        if !information.costumes.isEmpty {
                        Rectangle()
                            .opacity(0)
                            .frame(height: 30)
                        DetailsCostumesSection(costumes: information.costumes)
                        //                        }
                        //                        if !information.events.isEmpty {
                        Rectangle()
                            .opacity(0)
                            .frame(height: 30)
                        DetailsEventsSection(events: information.events)
                        //                        }
                        //                        if !information.gacha.isEmpty {
                        Rectangle()
                            .opacity(0)
                            .frame(height: 30)
                        DetailsGachasSection(gachas: information.gacha)
                        //                        }
                        Spacer()
                    }
                    .padding()
                }
                .scrollDisablesPopover()
            } else {
                if infoIsAvailable {
                    ExtendedConstraints {
                        ProgressView()
                    }
                } else {
                    Button(action: {
                        Task {
                            await getInformation(id: currentID)
                        }
                    }, label: {
                        ExtendedConstraints {
                            ContentUnavailableView("Character.unavailable", systemImage: "photo.badge.exclamationmark", description: Text("Search.unavailable.description"))
                        }
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .withSystemBackground()
        .navigationDestination(item: $cardNavigationDestinationID, destination: { id in
            Text("\(id)")
        })
        .navigationTitle(Text(information?.character.characterName.forPreferredLocale() ?? "\(isMACOS ? String(localized: "Character") : "")"))
#if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, macOS 14.0, *) {
                content
                    .navigationSubtitle(information?.character.characterName.forPreferredLocale() != nil ? "#\(currentID)" : "")
            } else {
                content
            }
        }
#endif
        .task {
            if (allCharacters ?? []).isEmpty {
                allCharacterIDs = (await Character.all() ?? []).sorted(withDoriSorter: _DoriFrontend.Sorter(keyword: .id, direction: .ascending)).map {$0.id}
            } else {
                allCharacterIDs = (allCharacters ?? []).map { $0.id }
            }
        }
        .onChange(of: currentID, {
            Task {
                randomCardHadUpdatedOnce = false
                await getInformation(id: currentID)
            }
        })
        .task {
            currentID = id
            await getInformation(id: currentID)
        }
        .toolbar {
            ToolbarItemGroup(content: {
                DetailsIDSwitcher(currentID: $currentID, allIDs: allCharacterIDs, destination: { CharacterSearchView() })
                    .onChange(of: currentID) {
                        information = nil
                    }
                    .onAppear {
                        showSubtitle = (sizeClass == .compact)
                    }
            })
        }
    }
    
    func getInformation(id: Int) async {
        infoIsAvailable = true
        informationLoadPromise?.cancel()
        
        informationLoadPromise = DoriCache.withCache(id: "CharacterDetail_\(id)") {
            await _DoriFrontend.Characters.extendedInformation(of: id)
        }.onUpdate {
            if let information = $0 {
                self.information = information
                if !randomCardHadUpdatedOnce {
                    randomCard = information.randomCard()
                    randomCardHadUpdatedOnce = true
                }
            } else {
                infoIsAvailable = false
            }
            //            SDWebImagePrefetcher.shared.prefetchURLs(
            //                information.cards.map(\.thumbNormalImageURL)
            //                + information.cards.compactMap(\.thumbAfterTrainingImageURL)
            //                + information.costumes.map(\.thumbImageURL)
            //                + information.events.map(\.bannerImageURL)
            //                + information.gacha.map(\.bannerImageURL)
            //            )
        }
    }
}


//MARK: CharacterDetailOverviewView
struct CharacterDetailOverviewView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let information: ExtendedCharacter
    var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.timeZone = .init(identifier: "Asia/Tokyo")!
        df.setLocalizedDateFormatFromTemplate("MMM d")
        return df
    }
    var body: some View {
        CustomGroupBox(cornerRadius: 20) {
            VStack {
                Group {
                    //MARK: Info
                    Group {
                        //MARK: Name
                        Group {
                            ListItem(title: {
                                Text("Character.name")
                                    .bold()
                            }, value: {
                                MultilingualText(information.character.characterName)
                            })
                            Divider()
                        }
                        
                        if !(information.character.nickname.jp ?? "").isEmpty {
                            //MARK: Nickname
                            Group {
                                ListItem(title: {
                                    Text("Character.nickname")
                                        .bold()
                                }, value: {
                                    MultilingualText(information.character.nickname)
                                })
                                Divider()
                            }
                        }
                        
                        if let profile = information.character.profile {
                            //MARK: Character Voice
                            Group {
                                ListItem(title: {
                                    Text("Character.character-voice")
                                        .bold()
                                }, value: {
                                    MultilingualText(profile.characterVoice)
                                })
                                Divider()
                            }
                        }
                        
                        if let color = information.character.color {
                            //MARK: Color
                            Group {
                                ListItem(title: {
                                    Text("Character.color")
                                        .bold()
                                }, value: {
                                    Text(color.toHex() ?? "")
                                        .fontDesign(.monospaced)
                                    RoundedRectangle(cornerRadius: 7)
                                    //                                    .aspectRatio(1, contentMode: .fit)
                                        .frame(width: 30, height: 30)
                                        .foregroundStyle(color)
                                })
                                Divider()
                            }
                        }
                        
                        if let bandID = information.character.bandID {
                            //MARK: Band
                            Group {
                                ListItem(title: {
                                    Text("Character.band")
                                        .bold()
                                }, value: {
                                    Text(DoriCache.preCache.mainBands.first{$0.id == bandID}?.bandName.forPreferredLocale(allowsFallback: true) ?? "Unknown")
                                    WebImage(url: DoriCache.preCache.mainBands.first{$0.id == bandID}?.iconImageURL)
                                        .resizable()
                                        .interpolation(.high)
                                        .antialiased(true)
                                    //                                    .scaledToFit()
                                        .frame(width: 30, height: 30)
                                    
                                })
                                Divider()
                            }
                        }
                        
                        if let profile = information.character.profile {
                            //MARK: Role
                            Group {
                                ListItem(title: {
                                    Text("Character.role")
                                        .bold()
                                }, value: {
                                    Text(profile.part.localizedString)
                                })
                                Divider()
                            }
                            
                            //MARK: Role
                            Group {
                                ListItem(title: {
                                    Text("Character.birthday")
                                        .bold()
                                }, value: {
                                    Text(dateFormatter.string(from: profile.birthday))
                                })
                                Divider()
                            }
                            
                            //MARK: Constellation
                            Group {
                                ListItem(title: {
                                    Text("Character.constellation")
                                        .bold()
                                }, value: {
                                    Text(profile.constellation.localizedString)
                                })
                                Divider()
                            }
                            
                            //MARK: Height
                            Group {
                                ListItem(title: {
                                    Text("Character.height")
                                        .bold()
                                }, value: {
                                    Text(verbatim: "\(profile.height) cm")
                                })
                                Divider()
                            }
                            
                            //MARK: School
                            Group {
                                ListItem(title: {
                                    Text("Character.school")
                                        .bold()
                                }, value: {
                                    MultilingualText(profile.school)
                                })
                                Divider()
                            }
                            
                            //MARK: Favorite Food
                            Group {
                                ListItem(title: {
                                    Text("Character.year-class")
                                        .bold()
                                }, value: {
                                    MultilingualText({
                                        var localizedContent = LocalizedData<String>()
                                        for locale in DoriLocale.allCases {
                                            localizedContent._set("\(profile.schoolYear.forLocale(locale) ?? "nil") - \(profile.schoolClass.forLocale(locale) ?? "nil")", forLocale: locale)
                                        }
                                        return localizedContent
                                    }())
                                })
                                Divider()
                            }
                            
                            //MARK: Favorite Food
                            Group {
                                ListItem(title: {
                                    Text("Character.favorite-food")
                                        .bold()
                                }, value: {
                                    MultilingualText(profile.favoriteFood)
                                })
                                Divider()
                            }
                            
                            //MARK: Disliked Food
                            Group {
                                ListItem(title: {
                                    Text("Character.disliked-food")
                                        .bold()
                                }, value: {
                                    MultilingualText(profile.hatedFood)
                                })
                                Divider()
                            }
                            
                            //MARK: Hobby
                            Group {
                                ListItem(title: {
                                    Text("Character.hobby")
                                        .bold()
                                }, value: {
                                    MultilingualText(profile.hobby)
                                })
                                Divider()
                            }
                            
                            //MARK: Introduction
                            Group {
                                ListItem(displayMode: .basedOnUISizeClass, title: {
                                    Text("Character.introduction")
                                        .bold()
                                }, value: {
                                    MultilingualText(profile.selfIntroduction, showSecondaryText: false, allowPopover: false)
                                })
                                Divider()
                            }
                        }
                        
                        
                        //MARK: ID
                        Group {
                            ListItem(title: {
                                Text("ID")
                                    .bold()
                            }, value: {
                                Text("\(String(information.id))")
                            })
                        }
                    }
                }
            }
        }
        .frame(maxWidth: infoContentMaxWidth)
    }
}
