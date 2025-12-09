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


// MARK: CharacterDetailView
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
                        DetailSectionsSpacer()
                        DetailsCardsSection(cards: information.cards)
                        DetailSectionsSpacer()
                        DetailsCostumesSection(costumes: information.costumes)
                        DetailSectionsSpacer()
                        DetailsEventsSection(events: information.events)
                        DetailSectionsSpacer()
                        DetailsGachasSection(gachas: information.gacha)
                        DetailSectionsSpacer()
                        ExternalLinksSection(links: [ExternalLink(name: "External-link.bestdori", url: URL(string: "https://bestdori.com/info/characters/\(id)")!)])
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
