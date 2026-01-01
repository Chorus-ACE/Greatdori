//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardCoverImage.swift
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


// MARK: CardCoverImage
struct CardCoverImage: View {
    private var card: PreviewCard
    private var band: Band?
    private var displayType: CardImageDisplayType
    private var characterName: LocalizedData<String>?
    private var showNavigationHints: Bool
    
    @State var showCardDetailView: Bool = false
    init(_ card: PreviewCard, band: Band?, showNavigationHints: Bool = true, displayType: CardImageDisplayType = .both) {
        self.card = card
        self.band = band
        
        self.showNavigationHints = showNavigationHints
        self.displayType = displayType
        self.characterName = DoriCache.preCache.characterDetails[card.characterID]?.characterName
    }
    init(_ card: Card, band: Band?, showNavigationHints: Bool = true, displayType: CardImageDisplayType = .both) {
        self.card = PreviewCard(card)
        self.band = band
        
        self.showNavigationHints = showNavigationHints
        self.displayType = displayType
        self.characterName = DoriCache.preCache.characterDetails[card.characterID]?.characterName
    }
    
    private let cardCornerRadius: CGFloat = 10
    private let standardCardWidth: CGFloat = 480
    private let standardCardHeight: CGFloat = 320
    private let expectedCardRatio: CGFloat = 480/320
    private let cardFocusSwitchingAnimation: Animation = .easeOut(duration: 0.15)
    
    @State var normalCardIsOnHover = false
    @State var trainedCardIsOnHover = false
    @State var isNormalImageUnavailable = false
    
    @State var isHovering: Bool = false
    var body: some View {
        ZStack {
            CardCoverImageBorder(card, band: band, showNavigationHints: showNavigationHints, displayType: displayType)
            
            // The Image may not be in expected ratio. Gosh.
            // Why the heck will the image has a different ratio with the border???
            // --@ThreeManager785
            
            // MARK: Visualized Card Information
            // This includes information like `card.attributes` and `card.rarity`.
            GeometryReader { proxy in
                VStack {
                    HStack {
                        if let band {
                            WebImage(url: band.iconImageURL)
                                .resizable()
                                .interpolation(.high)
                                .antialiased(true)
                                .frame(width: 51/standardCardWidth*proxy.size.width, height: 51/standardCardHeight*proxy.size.height, alignment: .topLeading)
                                .offset(x: proxy.size.width*0.005, y: proxy.size.height*0.01)
                        }
                        Spacer()
                        WebImage(url: card.attribute.iconImageURL)
                            .resizable()
                            .interpolation(.high)
                            .antialiased(true)
                            .frame(width: 51/standardCardWidth*proxy.size.width, height: 51/standardCardHeight*proxy.size.height, alignment: .topLeading)
                            .offset(x: proxy.size.width*(-0.015), y: proxy.size.height*0.015)
                    }
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(1...card.rarity, id: \.self) { _ in
                                Image(card.rarity >= 3 ? .trainedStar : .star)
                                    .resizable()
                                    .frame(width: 40/standardCardWidth*proxy.size.width, height: 40/standardCardHeight*proxy.size.height, alignment: .topLeading)
                                    .padding(.top, CGFloat(-card.rarity))
                            }
                        }
                        Spacer()
                    }
                }
            }
            .aspectRatio(expectedCardRatio, contentMode: .fit)
        }
        .cornerRadius(cardCornerRadius)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Accessibility.card.\(card.cardName.forPreferredLocale() ?? "")")
        .accessibilityCustomContent("Card.character", Text(characterName?.forPreferredLocale() ?? ""), importance: .high)
        .accessibilityCustomContent("Card.rarity", "\(card.rarity)")
        .accessibilityCustomContent("Card.attribute", card.attribute.selectorText)
        .accessibilityCustomContent("Card.band", band?.bandName.forPreferredLocale() ?? "")
        .accessibilityCustomContent("Card.type", card.type.selectorText)
        .imageContextMenu([
            isNormalImageUnavailable ? nil : .init(url: card.coverNormalImageURL, description: "Image.card.normal"),
            card.coverAfterTrainingImageURL != nil ? .init(url: card.coverAfterTrainingImageURL!, description: "Image.card.trained") : nil
        ].compactMap { $0 }) {
            if showNavigationHints {
                CardCoverNavigationHints(showCardDetailView: $showCardDetailView, card: card, characterName: characterName)
            }
        }
        .navigationDestination(isPresented: $showCardDetailView, destination: {
            CardDetailView(id: card.id)
        })
        .onChange(of: card.id) {
            isNormalImageUnavailable = false
        }
    }
}

// MARK: CardCoverImageBorder
struct CardCoverImageBorder: View {
    private var card: PreviewCard
    private var band: Band?
    private var displayType: CardImageDisplayType
    private var characterName: LocalizedData<String>?
    private var showNavigationHints: Bool
    
    @State var showCardDetailView: Bool = false
    init(_ card: PreviewCard, band: Band?, showNavigationHints: Bool = true, displayType: CardImageDisplayType = .both) {
        self.card = card
        self.band = band
        
        self.showNavigationHints = showNavigationHints
        self.displayType = displayType
        self.characterName = DoriCache.preCache.characterDetails[card.characterID]?.characterName
    }
    
    private let cardCornerRadius: CGFloat = 10
    private let standardCardWidth: CGFloat = 480
    private let standardCardHeight: CGFloat = 320
    private let expectedCardRatio: CGFloat = 480/320
    private let cardFocusSwitchingAnimation: Animation = .easeOut(duration: 0.15)
    
    @State var normalCardIsOnHover = false
    @State var trainedCardIsOnHover = false
    @State var isNormalImageUnavailable = false
    
    @State var isHovering: Bool = false
    var body: some View {
        // MARK: Border
        Group {
            if card.rarity != 1 {
                Image("CardBorder\(card.rarity)")
                    .resizable()
            } else {
                Image("CardBorder\(card.rarity)\(card.attribute.rawValue.prefix(1).uppercased() + card.attribute.rawValue.dropFirst())")
                    .resizable()
            }
        }
        .aspectRatio(expectedCardRatio, contentMode: .fit)
        .clipped()
        .allowsHitTesting(false)
        .background {
            // MARK: Card Content
            GeometryReader { proxy in
                Group {
                    if let cardCoverAfterTrainingImageURL = card.coverAfterTrainingImageURL, displayType != .normalOnly {
                        if displayType == .both && !isNormalImageUnavailable {
                            // Both
                            HStack(spacing: 0) {
                                WebImage(url: card.coverNormalImageURL) { image in
                                    image
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 0)
                                        .fill(getPlaceholderColor())
                                }
                                .resizable()
                                .onFailure { _ in
                                    DispatchQueue.main.async {
                                        isNormalImageUnavailable = true
                                    }
                                }
                                .interpolation(.high)
                                .antialiased(true)
                                .scaledToFill()
                                .frame(width: proxy.size.width * CGFloat(normalCardIsOnHover ? 0.75 : (trainedCardIsOnHover ? 0.25 : 0.5)))
                                .clipped()
#if !os(macOS)
                                .onTapGesture {
                                    withAnimation(cardFocusSwitchingAnimation) {
                                        if !normalCardIsOnHover {
                                            normalCardIsOnHover = true
                                            trainedCardIsOnHover = false
                                        } else {
                                            normalCardIsOnHover = false
                                        }
                                    }
                                }
#endif
                                .onHover { isHovering in
                                    withAnimation(cardFocusSwitchingAnimation) {
                                        if isHovering {
                                            normalCardIsOnHover = true
                                            trainedCardIsOnHover = false
                                        } else {
                                            normalCardIsOnHover = false
                                        }
                                    }
                                }
                                .contentShape(Rectangle())
                                
                                WebImage(url: cardCoverAfterTrainingImageURL) { image in
                                    image
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 0)
                                        .fill(getPlaceholderColor())
                                }
                                .resizable()
                                .interpolation(.high)
                                .antialiased(true)
                                .scaledToFill()
                                .frame(width: proxy.size.width * CGFloat(trainedCardIsOnHover ? 0.75 : (normalCardIsOnHover ? 0.25 : 0.5)))
                                .clipped()
#if !os(macOS)
                                .onTapGesture {
                                    withAnimation(cardFocusSwitchingAnimation) {
                                        if !trainedCardIsOnHover {
                                            normalCardIsOnHover = false
                                            trainedCardIsOnHover = true
                                        } else {
                                            trainedCardIsOnHover = false
                                        }
                                    }
                                }
#endif
                                .onHover { isHovering in
                                    withAnimation(cardFocusSwitchingAnimation) {
                                        if isHovering {
                                            normalCardIsOnHover = false
                                            trainedCardIsOnHover = true
                                        } else {
                                            trainedCardIsOnHover = false
                                        }
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .allowsHitTesting(true)
                        } else {
                            WebImage(url: cardCoverAfterTrainingImageURL) { image in
                                image
                            } placeholder: {
                                RoundedRectangle(cornerRadius: cardCornerRadius)
                                    .fill(getPlaceholderColor())
                            }
                            .resizable()
                            .interpolation(.high)
                            .antialiased(true)
                        }
                    } else {
                        WebImage(url: card.coverNormalImageURL) { image in
                            image
                        } placeholder: {
                            RoundedRectangle(cornerRadius: cardCornerRadius)
                                .fill(getPlaceholderColor())
                        }
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                    }
                }
                .cornerRadius(cardCornerRadius)
                .scaledToFill()
                .frame(width: proxy.size.width, height: proxy.size.height)
                .clipped()
                //                    .scaleEffect(0.97)
            }
        }
    }
}

// MARK: CardCoverNavigationHints
struct CardCoverNavigationHints: View {
    @Binding var showCardDetailView: Bool
    var card: PreviewCard
    var characterName: LocalizedData<String>?
    var body: some View {
        VStack {
            Button(action: {
                // cardNavigationDestinationID = card.id
                showCardDetailView = true
            }, label: {
#if os(iOS)
                if let title = card.cardName.forPreferredLocale(), let character = characterName?.forPreferredLocale() {
                    Group {
                        Text(title)
                        Group {
                            Text("\(character)") + Text("Typography.bold-dot-seperater").bold() +  Text(card.type.localizedString)
                        }
                        .font(.caption)
                    }
                } else {
                    Group {
                        Text(verbatim: "Lorem ipsum dolor")
                        Text(verbatim: "Lorem ipsum")
                            .font(.caption)
                    }
                    .redacted(reason: .placeholder)
                }
#else
                if let title = card.cardName.forPreferredLocale() {
                    Label(title, systemImage: "info.circle")
                } else {
                    Text(verbatim: "Lorem ipsum dolor")
                        .redacted(reason: .placeholder)
                }
#endif
            })
            .disabled(card.cardName.forPreferredLocale() == nil || characterName?.forPreferredLocale() == nil)
        }
    }
}
