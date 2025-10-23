//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardCoverImage.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.memz.top/LICENSE.txt for license information
// See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import DoriKit
import SDWebImageSwiftUI
import SwiftUI


// MARK: CardCoverImage
struct CardCoverImage: View {
    private var normalBackgroundImageURL: URL
    private var trainedBackgroundImageURL: URL?
    private var cardType: CardType
    private var attribute: DoriAPI.Attribute
    private var rarity: Int
    private var bandIconImageURL: URL?
    private var showNavigationHints: Bool
    private var cardID: Int
    private var cardTitle: DoriAPI.LocalizedData<String>
    private var characterID: Int
    private var displayType: CardImageDisplayType
    @State var cardCharacterName: DoriAPI.LocalizedData<String>?
    @State var showCardDetailView: Bool = false
    //    @State var cardDestinationID: Int = 0
    
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 104)
    init(_ card: PreviewCard, band: Band?, showNavigationHints: Bool = true, displayType: CardImageDisplayType = .both) {
        self.normalBackgroundImageURL = card.coverNormalImageURL
        self.trainedBackgroundImageURL = card.coverAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.bandIconImageURL = band?.iconImageURL
        self.showNavigationHints = showNavigationHints
        self.cardID = card.id
        self.cardTitle = card.prefix
        self.characterID = card.characterID
        self.displayType = displayType
    }
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 104)
    init(_ card: Card, band: Band?, showNavigationHints: Bool = true, displayType: CardImageDisplayType = .both) {
        self.normalBackgroundImageURL = card.coverNormalImageURL
        self.trainedBackgroundImageURL = card.coverAfterTrainingImageURL
        self.cardType = card.type
        self.attribute = card.attribute
        self.rarity = card.rarity
        self.bandIconImageURL = band?.iconImageURL
        self.showNavigationHints = showNavigationHints
        self.cardID = card.id
        self.cardTitle = card.prefix
        self.characterID = card.characterID
        self.displayType = displayType
    }
    //#sourceLocation(file: "/Users/t785/Xcode/Greatdori/Greatdori Watch App/CardViews.swift.gyb", line: 113)
    
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
            // MARK: Border
            Group {
                if rarity != 1 {
                    Image("CardBorder\(rarity)")
                        .resizable()
                } else {
                    Image("CardBorder\(rarity)\(attribute.rawValue.prefix(1).uppercased() + attribute.rawValue.dropFirst())")
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
                        if let trainedBackgroundImageURL, displayType != .normalOnly {
                            if displayType == .both && !isNormalImageUnavailable {
                                // Both
                                HStack(spacing: 0) {
                                    WebImage(url: normalBackgroundImageURL) { image in
                                        image
                                    } placeholder: {
                                        RoundedRectangle(cornerRadius: 0)
                                            .fill(getPlaceholderColor())
                                    }
                                    .resizable()
                                    .onFailure { _ in
                                        isNormalImageUnavailable = true
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
                                    
                                    WebImage(url: trainedBackgroundImageURL) { image in
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
                                WebImage(url: trainedBackgroundImageURL) { image in
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
                            WebImage(url: normalBackgroundImageURL) { image in
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
            
            // The Image may not be in expected ratio. Gosh.
            // Why the heck will the image has a different ratio with the border???
            // --@ThreeManager785
            
            // MARK: Visualized Card Information
            // This includes information like `attributes` and `rarity`.
            GeometryReader { proxy in
                VStack {
                    HStack {
                        if let bandIconImageURL {
                            WebImage(url: bandIconImageURL)
                                .resizable()
                                .interpolation(.high)
                                .antialiased(true)
                            //51:480 = ?:currentWidth
                            //? = currentWidth*51/480
                            
                                .frame(width: 51/standardCardWidth*proxy.size.width, height: 51/standardCardHeight*proxy.size.height, alignment: .topLeading)
                                .offset(x: proxy.size.width*0.005, y: proxy.size.height*0.01)
                            //                    Spacer()
                        }
                        Spacer()
                        WebImage(url: attribute.iconImageURL)
                            .resizable()
                            .interpolation(.high)
                            .antialiased(true)
                            .frame(width: 51/standardCardWidth*proxy.size.width, height: 51/standardCardHeight*proxy.size.height, alignment: .topLeading)
                            .offset(x: proxy.size.width*(-0.015), y: proxy.size.height*0.015)
                    }
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(1...rarity, id: \.self) { _ in
                                Image(rarity >= 3 ? .trainedStar : .star)
                                    .resizable()
                                    .frame(width: 40/standardCardWidth*proxy.size.width, height: 40/standardCardHeight*proxy.size.height, alignment: .topLeading)
                                    .padding(.top, CGFloat(-rarity))
                            }
                        }
                        Spacer()
                    }
                }
            }
            .aspectRatio(expectedCardRatio, contentMode: .fit)
        }
        .cornerRadius(cardCornerRadius)
        .imageContextMenu([
            .init(url: normalBackgroundImageURL, description: "Image.card.normal"),
            trainedBackgroundImageURL != nil ? .init(url: trainedBackgroundImageURL!, description: "Image.card.trained") : nil
        ].compactMap { $0 }) {
            if showNavigationHints {
                VStack {
                    Button(action: {
                        // cardNavigationDestinationID = cardID
                        showCardDetailView = true
                    }, label: {
#if os(iOS)
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
                                Text(verbatim: "Lorem ipsum")
                                    .font(.caption)
                            }
                            .redacted(reason: .placeholder)
                        }
#else
                        if let title = cardTitle.forPreferredLocale() {
                            Label(title, systemImage: "info.circle")
                        } else {
                            Text(verbatim: "Lorem ipsum dolor")
                                .redacted(reason: .placeholder)
                        }
#endif
                    })
                    .disabled(cardTitle.forPreferredLocale() == nil ||  cardCharacterName?.forPreferredLocale() == nil)
                }
            }
        }
        .onAppear {
            self.cardCharacterName = DoriCache.preCache.characterDetails[characterID]?.characterName
        }
        .navigationDestination(isPresented: $showCardDetailView, destination: {
            CardDetailView(id: cardID)
        })
    }
}
