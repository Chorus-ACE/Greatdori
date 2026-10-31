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
    @State private var focusIndex = 0
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
    
    @State var isNormalImageUnavailable: Bool = false
    @State var isHovering: Bool = false
    var body: some View {
        ZStack {
            CardCoverImageBorder(card, band: band, isNormalImageUnavailable: $isNormalImageUnavailable, showNavigationHints: showNavigationHints, displayType: displayType, focusIndex: $focusIndex)
            
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
        .imageContextMenu(focusedImageInfo, sectionTitle: focusedImageTitle) {
            if showNavigationHints {
                CardCoverNavigationHints(showCardDetailView: $showCardDetailView, card: card, characterName: characterName)
            }
        }
        .navigationDestination(isPresented: $showCardDetailView, destination: {
            CardDetailView(id: card.id)
        })
        .onChange(of: card.id) {
            isNormalImageUnavailable = false
            focusIndex = 0
        }
        .onChange(of: displayType) {
            focusIndex = 0
        }
    }

    private var focusedImageInfo: [ImageInfo] {
        var images: [ImageInfo] = []
        if focusedDisplayType != .trainedOnly && !isNormalImageUnavailable {
            images.append(.init(url: card.coverNormalImageURL, description: "Image.card.normal"))
        }
        if focusedDisplayType != .normalOnly, let url = card.coverAfterTrainingImageURL {
            images.append(.init(url: url, description: "Image.card.trained"))
        }
        return images
    }

    private var focusedImageTitle: LocalizedStringResource? {
        switch focusedDisplayType {
        case .normalOnly: "Image.card.normal"
        case .trainedOnly: "Image.card.trained"
        case .both: nil
        }
    }

    private var focusedDisplayType: CardImageDisplayType {
        guard card.coverAfterTrainingImageURL != nil, displayType != .normalOnly else {
            return .normalOnly
        }
        if displayType == .trainedOnly || isNormalImageUnavailable {
            return .trainedOnly
        }
        return focusIndex < 0 ? .normalOnly : focusIndex > 0 ? .trainedOnly : .both
    }
}

// MARK: CardCoverImageBorder
struct CardCoverImageBorder: View {
    private var card: PreviewCard
    private var band: Band?
    private var displayType: CardImageDisplayType
    private var characterName: LocalizedData<String>?
    private var showNavigationHints: Bool
    private var isNormalImageUnavailable: Binding<Bool>
    @Binding private var focusIndex: Int
    
    @State var showCardDetailView: Bool = false
    init(_ card: PreviewCard, band: Band?, isNormalImageUnavailable: Binding<Bool>, showNavigationHints: Bool = true, displayType: CardImageDisplayType = .both, focusIndex: Binding<Int>) {
        self.card = card
        self.band = band
        self.isNormalImageUnavailable = isNormalImageUnavailable
        self._focusIndex = focusIndex
        
        self.showNavigationHints = showNavigationHints
        self.displayType = displayType
        self.characterName = DoriCache.preCache.characterDetails[card.characterID]?.characterName
    }
    
    private let cardCornerRadius: CGFloat = 10
    private let standardCardWidth: CGFloat = 480
    private let standardCardHeight: CGFloat = 320
    private let expectedCardRatio: CGFloat = 480/320
    private let cardFocusSwitchingAnimation: Animation = .easeOut(duration: 0.15)
    
    @Namespace var hoverGroup
    @State var normalCardIsOnHover = false
    @State var trainedCardIsOnHover = false
    
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
                        if displayType == .both && !isNormalImageUnavailable.wrappedValue {
                            Group {
                                #if os(visionOS)
                                if focusIndex == 0 {
                                    spatialImages(afterTrainingURL: cardCoverAfterTrainingImageURL, size: proxy.size)
                                } else {
                                    focusedImages(afterTrainingURL: cardCoverAfterTrainingImageURL, width: proxy.size.width)
                                }
                                #else
                                focusedImages(afterTrainingURL: cardCoverAfterTrainingImageURL, width: proxy.size.width)
                                #endif
                            }
                            .gesture(DragGesture(minimumDistance: 30).onEnded { value in
                                guard abs(value.translation.width) > abs(value.translation.height) else { return }
                                withAnimation(cardFocusSwitchingAnimation) {
                                    focusIndex = min(2, max(-2, focusIndex + (value.translation.width > 0 ? -1 : 1)))
                                }
                            })
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
            }
        }
    }

    private let cardWidthFactor: [Int: CGFloat] = [-2: 0, -1: 0.25, 0: 0.5, 1: 0.75, 2: 1]

    private func focusedImages(afterTrainingURL: URL, width: CGFloat) -> some View {
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
                    isNormalImageUnavailable.wrappedValue = true
                }
            }
            .interpolation(.high)
            .antialiased(true)
            .scaledToFill()
            .frame(width: width * (cardWidthFactor[-focusIndex] ?? 0.5))
            .clipped()
            .onTapGesture { focusNormalImage() }
            .onHover { isHovering in
                withAnimation(cardFocusSwitchingAnimation) {
                    focusIndex = isHovering ? -1 : 0
                    normalCardIsOnHover = isHovering
                }
            }
            .contentShape(Rectangle())

            WebImage(url: afterTrainingURL) { image in
                image
            } placeholder: {
                RoundedRectangle(cornerRadius: 0)
                    .fill(getPlaceholderColor())
            }
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .scaledToFill()
            .frame(width: width * (cardWidthFactor[focusIndex] ?? 0.5))
            .clipped()
            .onTapGesture { focusTrainedImage() }
            .onHover { isHovering in
                withAnimation(cardFocusSwitchingAnimation) {
                    focusIndex = isHovering ? 1 : 0
                    trainedCardIsOnHover = isHovering
                }
            }
            .contentShape(Rectangle())
        }
    }

    private func focusNormalImage() {
        withAnimation(cardFocusSwitchingAnimation) {
            if [0, -1].contains(focusIndex) {
                focusIndex -= 1
            } else {
                focusIndex = focusIndex == -2 && normalCardIsOnHover ? -1 : 0
            }
        }
    }

    private func focusTrainedImage() {
        withAnimation(cardFocusSwitchingAnimation) {
            if [0, 1].contains(focusIndex) {
                focusIndex += 1
            } else {
                focusIndex = focusIndex == 2 && trainedCardIsOnHover ? 1 : 0
            }
        }
    }

    #if os(visionOS)
    private func spatialImages(afterTrainingURL: URL, size: CGSize) -> some View {
        ZStack {
            WebImage(url: card.coverNormalImageURL) { image in
                image
            } placeholder: {
                RoundedRectangle(cornerRadius: 0)
                    .fill(getPlaceholderColor())
            }
            .resizable()
            .onFailure { _ in
                DispatchQueue.main.async {
                    isNormalImageUnavailable.wrappedValue = true
                }
            }
            .interpolation(.high)
            .antialiased(true)
            .scaledToFill()
            .hoverEffect(.empty, in: .init(id: "leadingActivatesTrailing", in: hoverGroup))
            .hoverEffect(in: .init(id: "trailingActivatesLeading", in: hoverGroup, behavior: .followsGroup)) { content, isActive, proxy in
                content
                    .animation(cardFocusSwitchingAnimation) { content in
                        content
                            .offset(x: -(isActive ? proxy.size.width / 8 : 0))
                            .clipShape(.rect.size(
                                width: isActive ? proxy.size.width * 0.5 : proxy.size.width,
                                height: proxy.size.height,
                                anchor: .leading
                            ))
                    }
            }
            .hoverEffect { content, isActive, proxy in
                content
                    .animation(cardFocusSwitchingAnimation) { content in
                        content
                            .offset(x: -(isActive ? proxy.size.width / 8 : proxy.size.width / 4))
                            .clipShape(.rect.size(
                                width: isActive ? proxy.size.width * 0.75 : proxy.size.width * 0.5,
                                height: proxy.size.height,
                                anchor: .leading
                            ))
                    }
            }
            .clipped()
            .contentShape(.rect.size(width: size.width / 2, height: size.height, anchor: .leading))
            .onTapGesture { focusNormalImage() }

            WebImage(url: afterTrainingURL) { image in
                image
            } placeholder: {
                RoundedRectangle(cornerRadius: 0)
                    .fill(getPlaceholderColor())
            }
            .resizable()
            .interpolation(.high)
            .antialiased(true)
            .scaledToFill()
            .hoverEffect(.empty, in: .init(id: "trailingActivatesLeading", in: hoverGroup))
            .hoverEffect(in: .init(id: "leadingActivatesTrailing", in: hoverGroup, behavior: .followsGroup)) { content, isActive, proxy in
                content
                    .animation(cardFocusSwitchingAnimation) { content in
                        content
                            .offset(x: isActive ? proxy.size.width / 8 : 0)
                            .clipShape(.rect.size(
                                width: isActive ? proxy.size.width * 0.5 : proxy.size.width,
                                height: proxy.size.height,
                                anchor: .trailing
                            ))
                    }
            }
            .hoverEffect { content, isActive, proxy in
                content
                    .animation(cardFocusSwitchingAnimation) { content in
                        content
                            .offset(x: isActive ? proxy.size.width / 8 : proxy.size.width / 4)
                            .clipShape(.rect.size(
                                width: isActive ? proxy.size.width * 0.75 : proxy.size.width * 0.5,
                                height: proxy.size.height,
                                anchor: .trailing
                            ))
                    }
            }
            .clipped()
            .contentShape(.rect.size(width: size.width / 2, height: size.height, anchor: .trailing))
            .onTapGesture { focusTrainedImage() }
        }
    }
    #endif

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
