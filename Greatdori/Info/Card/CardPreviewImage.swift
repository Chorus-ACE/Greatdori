//===---*- Greatdori! -*---------------------------------------------------===//
//
// Card.swift
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

// MARK: CardPreviewImage
struct CardPreviewImage: View {
    private var inputtedPreviewCard: PreviewCard?
    private var cardID: Int
    private var thumbNormalImageURL: URL
    private var thumbTrainedImageURL: URL?
    private var cardType: DoriAPI.Cards.CardType
    private var attribute: DoriAPI.Attribute
    private var rarity: Int
    private var bandIconImageURL: URL?
    private var showTrainedVersion: Bool = false
    private var sideLength: CGFloat = 72
    private var showNavigationHints: Bool
    private var cardTitle: DoriAPI.LocalizedData<String>
    private var characterID: Int
    @State var cardCharacterName: DoriAPI.LocalizedData<String>?
    //    @State var isCardInfoAvailable = false
    //    @State var cardNavigationDestinationID: Int?
    @State var showCardDetailView = false
    @State var cardNavigationDestinationID: Int = 0
    @State var isHovering: Bool = false
    
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 323)
    init(_ card: PreviewCard, showTrainedVersion: Bool = false, sideLength: CGFloat = 72, showNavigationHints: Bool = false/*, cardNavigationDestinationID: Binding<Int?>*/) {
        self.inputtedPreviewCard = card
        self.cardID = card.id
        self.thumbNormalImageURL = card.thumbNormalImageURL
        self.thumbTrainedImageURL = card.thumbAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.bandIconImageURL = URL(string: "https://bestdori.com/res/icon/band_\(DoriCache.preCache.characters.first { $0.id == card.characterID }?.bandID ?? 0).svg")!
        self.showTrainedVersion = showTrainedVersion
        self.sideLength = sideLength
        self.showNavigationHints = showNavigationHints
        self.cardTitle = card.prefix
        self.characterID = card.characterID
        //        self._cardNavigationDestinationID = cardNavigationDestinationID
    }
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 323)
    init(_ card: Card, showTrainedVersion: Bool = false, sideLength: CGFloat = 72, showNavigationHints: Bool = false/*, cardNavigationDestinationID: Binding<Int?>*/) {
        self.cardID = card.id
        self.thumbNormalImageURL = card.thumbNormalImageURL
        self.thumbTrainedImageURL = card.thumbAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.bandIconImageURL = URL(string: "https://bestdori.com/res/icon/band_\(DoriCache.preCache.characters.first { $0.id == card.characterID }?.bandID ?? 0).svg")!
        self.showTrainedVersion = showTrainedVersion
        self.sideLength = sideLength
        self.showNavigationHints = showNavigationHints
        self.cardTitle = card.prefix
        self.characterID = card.characterID
        //        self._cardNavigationDestinationID = cardNavigationDestinationID
    }
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 332)
    
    var body: some View {
        ZStack(alignment: .center) {
            // Cover
            WebImage(url: (thumbTrainedImageURL != nil && showTrainedVersion) ? thumbTrainedImageURL : thumbNormalImageURL) { image in
                image
            } placeholder: {
                RoundedRectangle(cornerRadius: 10)
                //                    .fill(Color.gray.opacity(0.15))
                    .fill(getPlaceholderColor())
                    .aspectRatio(1, contentMode: .fit)
            }
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            //.scaledToFill()
            //.cornerRadius(2)
            .clipped()
            .frame(width: 67/72*sideLength, height: 67/72*sideLength)
            
            // Frame
            if rarity != 1 {
                Image("CardThumbBorder\(rarity)")
                    .resizable()
                    .frame(width: sideLength, height: sideLength)
            } else {
                Image("CardThumbBorder\(rarity)\(attribute.rawValue.prefix(1).uppercased() + attribute.rawValue.dropFirst())")
                    .resizable()
                    .frame(width: sideLength, height: sideLength)
            }
            
            // Icons
            VStack(spacing: 0) {
                HStack {
                    WebImage(url: bandIconImageURL)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .frame(width: 20/72*sideLength, height: 20/72*sideLength, alignment: .topLeading)
                    Spacer()
                    WebImage(url: attribute.iconImageURL)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .frame(width: 18/72*sideLength, height: 18/72*sideLength, alignment: .topTrailing)
                        .offset(x: -1)
                }
                
                Spacer(minLength: 0)
                HStack {
                    VStack(alignment: .leading, spacing: -2) {
                        ForEach(1...rarity, id: \.self) { _ in
                            Image((thumbTrainedImageURL != nil && showTrainedVersion) ? .trainedStar : .star)
                                .resizable()
                                .frame(width: 12/72*sideLength, height: 12/72*sideLength)
                        }
                    }
                    Spacer()
                }
            }
            .frame(width: sideLength, height: sideLength)
        }
        .wrapIf(showNavigationHints, in: { content in
#if os(iOS)
            content
                .contextMenu(menuItems: {
                    VStack {
                        //                        NavigationLink(destination: {
                        //                            CardDetailView(id: cardID)
                        //                        }, label: {
                        Button(action: {
                            cardNavigationDestinationID = cardID
                            showCardDetailView = true
                        }, label: {
                            if let title = cardTitle.forPreferredLocale(), let character = cardCharacterName?.forPreferredLocale() {
                                Group {
                                    Text(title)
                                    Group {
                                        Text("\(character)") + Text("Typography.bold-dot-seperater").bold() +  Text(cardType.localizedString)
                                    }
                                    .font(.caption)
                                }
                            } else {
                                Group {
                                    Text(verbatim: "Lorem ipsum dolor")
                                    //                                        .foregroundStyle(.secondary)
                                    Text(verbatim: "Lorem ipsum")
                                        .font(.caption)
                                    //                                        .foregroundStyle(.tertiary)
                                }
                                .redacted(reason: .placeholder)
                                
                            }
                        })
                        .disabled(cardTitle.forPreferredLocale() == nil ||  cardCharacterName?.forPreferredLocale() == nil)
                    }
                })
#else
            // Very weird code cuz SwiftUI has very weird refreshing logic.
            // Don't touch without complete-understaning
            let sumimi = HereTheWorld(arguments: (cardTitle, cardCharacterName)) { cardTitle, cardCharacterName in
                VStack {
                    if let title = cardTitle.forPreferredLocale(), let character = cardCharacterName?.forPreferredLocale() {
                        Group {
                            Text(title)
                            Group {
                                Text("\(character)") + Text("Typography.bold-dot-seperater").bold() +  Text(cardType.localizedString)
                            }
                            .font(.caption)
                        }
                    } else {
                        Group {
                            Text(verbatim: "Lorem ipsum dolor")
                                .foregroundStyle(getPlaceholderColor())
                            //                                .fill()
                            Text(verbatim: "Lorem ipsum")
                                .foregroundStyle(.tertiary)
                        }
                        .redacted(reason: .placeholder)
                        
                    }
                }
                .padding()
            }
            content
                .onHover { isHovering in
                    self.isHovering = isHovering
                }
                .popover(isPresented: $isHovering, arrowEdge: .bottom) {
                    sumimi
                }
                .onChange(of: cardTitle) {
                    sumimi.updateArguments((cardTitle, cardCharacterName))
                }
                .onChange(of: cardCharacterName) {
                    sumimi.updateArguments((cardTitle, cardCharacterName))
                }
#endif
        })
        .frame(width: sideLength, height: sideLength)
        .onAppear {
            self.cardCharacterName = DoriCache.preCache.characterDetails[characterID]?.characterName
        }
        .navigationDestination(isPresented: $showCardDetailView, destination: {
            CardDetailView(id: cardNavigationDestinationID)
        })
    }
}
