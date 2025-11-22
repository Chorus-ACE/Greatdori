//===---*- Greatdori! -*---------------------------------------------------===//
//
// GachaDetailView.swift
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
import Foundation
import SDWebImageSwiftUI
import SwiftUI


// MARK: GachaDetailView
struct GachaDetailView: View {
    var id: Int
    var allGachas: [PreviewGacha]? = nil
    var body: some View {
        DetailViewBase(previewList: allGachas, initialID: id) { information in
            GachaDetailOverviewView(information: information)
            DetailsEventsSection(events: information.events)
            GachaDetailCardsView(information: information)
            GachaDetailPossibilityView(information: information)
            DetailArtsSection {
                ArtsTab("Gacha.arts.banner", ratio: 3) {
                    for locale in DoriLocale.allCases {
                        if let url = information.gacha.bannerImageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url)
                        }
                    }
                }
                ArtsTab("Gacha.arts.logo", ratio: 540/240) {
                    for locale in DoriLocale.allCases {
                        if let url = information.gacha.logoImageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url)
                        }
                    }
                }
                ArtsTab("Gacha.arts.pickup", ratio: 964/613) {
                    for locale in DoriLocale.allCases {
                        if let urls = information.gacha.pickupImageURLs(in: locale, allowsFallback: false) {
                            for i in 0..<urls.count {
                                ArtsItem(title: LocalizedStringResource(stringLiteral: "\(locale.rawValue.uppercased()) \(i+1)"), url: urls[i])
                            }
                        }
                    }
                }
            }
        } switcherDestination: {
            GachaSearchView()
        }
    }
}


// MARK: GachaDetailOverviewView
struct GachaDetailOverviewView: View {
    let information: ExtendedGacha
    //    @State var gachaCharacterPercentageDict: [Int: [DoriAPI.Gacha.GachaCharacter]] = [:]
    //    @State var gachaCharacterNameDict: [Int: DoriAPI.LocalizedData<String>] = [:]
    @State var cardsArray: [PreviewCard] = []
    @State var cardsArraySeperated: [[PreviewCard?]] = []
    @State var cardsPercentage: Int = -100
    @State var rewardsArray: [PreviewCard] = []
    @State var cardsTitleWidth: CGFloat = 0 // Fixed
    @State var cardsPercentageWidth: CGFloat = 0 // Fixed
    @State var cardsContentRegularWidth: CGFloat = 0 // Fixed
    @State var cardsFixedWidth: CGFloat = 0 //Fixed
    @State var cardsUseCompactLayout = true
    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
    var body: some View {
        VStack {
            Group {
                // MARK: Title Image
                Group {
                    Rectangle()
                        .opacity(0)
                        .frame(height: 2)
                    WebImage(url: information.gacha.bannerImageURL) { image in
                        image
                            .antialiased(true)
                            .resizable()
                        //                            .aspectRatio(3.0, contentMode: .fit)
                            .scaledToFit()
                            .frame(maxWidth: bannerWidth,/* maxHeight: bannerWidth/3*/)
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 10)
                        //                            .fill(Color.gray.opacity(0.15))
                            .fill(getPlaceholderColor())
                            .aspectRatio(3.0, contentMode: .fit)
                            .frame(maxWidth: bannerWidth, maxHeight: bannerWidth/3)
                    }
                    .interpolation(.high)
                    .cornerRadius(10)
                    Rectangle()
                        .opacity(0)
                        .frame(height: 2)
                }
                
                
                // MARK: Info
                CustomGroupBox(cornerRadius: 20) {
                    // Make this lazy fixes [250920-a] last appears in 8783d44.
                    // Seems like a bug of SwiftUI, idk why make this lazy
                    // fixes that bug. Whatever, it works.
                    LazyVStack {
                        // MARK: Title
                        Group {
                            ListItem(title: {
                                Text("Gacha.title")
                                    .bold()
                            }, value: {
                                MultilingualText(information.gacha.gachaName)
                            })
                            Divider()
                        }
                        
                        // MARK: Type
                        Group {
                            ListItem(title: {
                                Text("Gacha.type")
                                    .bold()
                            }, value: {
                                Text(information.gacha.type.localizedString)
                            })
                            Divider()
                        }
                        
                        // MARK: Countdown
                        Group {
                            ListItem(title: {
                                Text("Gacha.countdown")
                                    .bold()
                            }, value: {
                                MultilingualTextForCountdown(information.gacha)
                            })
                            Divider()
                        }
                        
                        // MARK: Release Date
                        Group {
                            ListItem(title: {
                                Text("Gacha.release-date")
                                    .bold()
                            }, value: {
                                MultilingualText(information.gacha.publishedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                            })
                            Divider()
                        }
                        
                        // MARK: Close Date
                        Group {
                            ListItem(title: {
                                Text("Gacha.close-date")
                                    .bold()
                            }, value: {
                                MultilingualText(information.gacha.closedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                            })
                            Divider()
                        }
                        
                        // MARK: Spotlight Card
                        if !information.pickupCards.isEmpty {
                            ListItem(displayMode: .compactOnly, title: {
                                Text("Gacha.spotlight-card")
                                    .bold()
                            }, value: {
                                WrappingHStack(columnSpacing: 3, contentWidth: cardThumbnailSideLength) {
                                    ForEach(information.pickupCards) { card in
                                        NavigationLink(destination: {
                                            CardDetailView(id: card.id)
                                        }, label: {
                                            CardPreviewImage(card, sideLength: cardThumbnailSideLength, showNavigationHints: true)
                                        })
                                        .buttonStyle(.plain)
                                    }
                                }
                            })
                            Divider()
                        }
                        
                        // MARK: Description
                        Group {
                            ListItem(displayMode: .basedOnUISizeClass, title: {
                                Text("Gacha.descripition")
                                    .bold()
                            }, value: {
                                MultilingualText(information.gacha.description)
                            })
                            Divider()
                        }
                        
                        
                        // MARK: ID
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
        .onAppear {
            /*
             gachaCharacterPercentageDict = [:]
             rewardsArray = []
             cardsArray = []
             let gachaCharacters = information.gacha.characters
             for char in gachaCharacters {
             gachaCharacterPercentageDict.updateValue(((gachaCharacterPercentageDict[char.percent] ?? []) + [char]), forKey: char.percent)
             Task {
             if let allCharacters = await DoriAPI.Character.all() {
             if let character = allCharacters.first(where: { $0.id == char.characterID }) {
             gachaCharacterNameDict.updateValue(character.characterName, forKey: char.characterID)
             }
             }
             
             }
             }
             for card in information.cards {
             if information.gacha.rewardCards.contains(card.id) {
             rewardsArray.append(card)
             } else {
             cardsArray.append(card)
             if cardsPercentage == -100 {
             cardsPercentage = information.gacha.members.first(where: { $0.situationID == card.id })?.percent ?? -200
             }
             }
             }
             cardsArraySeperated = cardsArray.chunked(into: 3)
             for i in 0..<cardsArraySeperated.count {
             while cardsArraySeperated[i].count < 3 {
             cardsArraySeperated[i].insert(nil, at: 0)
             }
             }
             */
        }
        
    }
}


struct GachaDetailCardsView: View {
    var information: ExtendedGacha
    @State var locale: DoriLocale = .primaryLocale
    @State var raritySectionIsExpanded: [Int: Bool] = [:]
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                VStack {
                    if !information.cardDetails.isEmpty, let rates = information.gacha.rates.forLocale(locale) {
                        let rarities = rates.keys.sorted(by: >)
                        ForEach(rarities, id: \.self) { rarity in
                            if rates[rarity]!.weightTotal > 0 {
                                CustomGroupBox {
                                    VStack {
                                        HStack {
                                            Text(verbatim: "\(rates[rarity]!.rate)%")
                                                .bold()
                                            HStack(spacing: 1) {
                                                ForEach(1...rarity, id: \.self) { _ in
                                                    Image(rarity > 2 ? .trainedStar : .star)
                                                        .resizable()
                                                        .frame(width: 16, height: 16)
                                                }
                                            }
                                            Spacer()
                                            if let cardsCount = information.gacha.details.forLocale(locale)?.filter({ $0.value.rarityIndex == rarity }).count {
                                                Text("\(cardsCount)")
                                                    .foregroundStyle(.secondary)
                                            }
                                            Image(systemName: "chevron.forward")
                                                .foregroundStyle(.secondary)
                                                .rotationEffect(Angle(degrees: (raritySectionIsExpanded[rarity] ?? false) ? 90 : 0))
                                        }
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            withAnimation {
                                                _ = raritySectionIsExpanded.updateValue(raritySectionIsExpanded[rarity]?.reversed() ?? true, forKey: rarity)
                                            }
                                        }
                                        
                                        if raritySectionIsExpanded[rarity] ?? false {
                                            if let _details = information.gacha.details.forPreferredLocale() {
                                                let details = _details.filter { $0.value.rarityIndex == rarity }
                                                ForEach(Set(details.values.map { $0.weight }).sorted(by: >), id: \.self) { weight in
                                                    let pickups = details.filter { $0.value.weight == weight }
                                                    HStack(alignment: .top) {
                                                        Text(verbatim: "\(unsafe String(format: "%.2f", Double(pickups.first!.value.weight) / Double(rates[rarity]!.weightTotal) * rates[rarity]!.rate))%")
                                                            .frame(width: 60, alignment: .leading)
                                                        CardImageGridContent(cards: information.cardDetails[rarity]!.filter { details[$0.id]?.weight == weight })
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: infoContentMaxWidth)
            }, header: {
                HStack {
                    Text("Gacha.cards")
                        .font(.title2)
                        .bold()
                    DetailSectionOptionPicker(selection: $locale, options: DoriLocale.allCases)
                    Spacer()
                }
                .frame(maxWidth: 615)
            })
        }
    }
    
    struct CardImageGridContent: View {
        var cards: [PreviewCard]
        @State private var isExpanded = false
        var body: some View {
            VStack {
                WrappingHStack(alignment: .trailing, contentWidth: 60) {
                    ForEach(isExpanded ? cards : Array(cards.prefix(20))) { card in
                        CardPreviewImage(card, sideLength: 60)
                    }
                }
                if cards.count > 20 {
                    Button(action: {
                        isExpanded.toggle()
                    }, label: {
                        HStack {
                            Spacer()
                            if isExpanded {
                                Text("显示更少")
                            } else {
                                Text("显示更多(\(cards.count - 20))")
                            }
                            Spacer()
                        }
                    })
                }
            }
        }
    }
}

// MARK: GachaDetailPossibilityView
struct GachaDetailPossibilityView: View {
    var information: ExtendedGacha
    @State var locale: DoriLocale = .primaryLocale
    @State var selectedCard: PreviewCard?
    @State var calculatePlaysByPossibility = true
    @State var possibility: Double = 99
    @State var plays: Int = 1
    var body: some View {
        
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                VStack {
                    CustomGroupBox {
                        VStack {
                            ListItem(title: {
                                Text("Gacha.possibility.card")
                            }, value: {
                                ItemSelectorButton(selection: $selectedCard, updateList: {
                                    information.cardDetails.flatMap({ $0.value })
                                })
                            })
                            
                            Divider()
                            
                            ListItem(title: {
                                Text("Gacha.possibility.calculate")
                            }, value: {
                                Picker(selection: $calculatePlaysByPossibility, content: {
                                    Text("Gacha.possibility.calculate.plays-by-possibility")
                                        .tag(true)
                                    Text("Gacha.possibility.calculate.possibility-by-plays")
                                        .tag(false)
                                }, label: {
                                    EmptyView()
                                })
                                .labelsHidden()
                            })
                            
                            Divider()
                            
                            if calculatePlaysByPossibility {
                                ListItem(title: {
                                    Text("Gacha.possibility.possibility")
                                }, value: {
                                    HStack {
                                        TextField("", value: $possibility, formatter: PossibilityNumberFormatter())
                                            .labelsHidden()
                                    }
                                })
                            } else {
                                ListItem(title: {
                                    Text("Gacha.possibility.plays")
                                }, value: {
                                    HStack {
                                        TextField("", value: $plays, formatter: PlaysNumberFormatter())
                                            .labelsHidden()
                                    }
                                })
                            }
                        }
                    }
                    if let selectedCard {
                        CustomGroupBox {
                            HStack {
                                Text({ () -> LocalizedStringKey in
                                    guard let rates = information.gacha.rates.forLocale(locale)?[selectedCard.rarity] else {
                                        return ""
                                    }
                                    guard let weight = information.gacha.details.forLocale(locale)?[selectedCard.id]?.weight else {
                                        return ""
                                    }
                                    let rate = rates.rate
                                    let weightTotal = (consume rates).weightTotal
                                    let e = rate / 100 * Double(weight) / Double(weightTotal)
                                    var i = 250
                                    if information.gacha.paymentMethods.count == 1 {
                                        i = information.gacha.paymentMethods[0].quantity
                                    }
                                    if calculatePlaysByPossibility {
                                        let n = possibility / 100
                                        guard n >= 0 && n < 1 else {
                                            return ""
                                        }
                                        let t = Int(ceil(log(1 - n) / log(1 - e)))
                                        return "Gacha.possibility.possibility.\(t).\(t * i).\(unsafe String(format: "%.1f", n * 100))"
                                    } else {
                                        let r = Double(plays)
                                        guard r >= 0 else {
                                            return ""
                                        }
                                        let t = 1 - pow(1.0 - e, r)
                                        return "Gacha.possibility.plays.\(plays).\(plays * i).\(unsafe String(format: "%.1f", t * 100))"
                                    }
                                }())
                                Spacer(minLength: 0)
                            }
                            .multilineTextAlignment(.leading)
                        }
                    }
                }
                .frame(maxWidth: infoContentMaxWidth)
            }, header: {
                HStack {
                    Text("Gacha.possibility")
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

class PossibilityNumberFormatter: NumberFormatter {
    override init() {
//        self.condition = condition
        super.init()
        self.numberStyle = .decimal
        self.minimumFractionDigits = 0
//        self.maximumFractionDigits = 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        guard let value = Double(string) else { return false }
        guard value >= 0 && value < 100 else { return false }
        obj?.pointee = NSNumber(value: value)
        return true
    }
    
    override func string(for obj: Any?) -> String? {
        guard let number = obj as? NSNumber else { return nil }
        let value = number.doubleValue
        guard value >= 0 && value < 100 else { return nil }
        return super.string(for: number)
    }
}


class PlaysNumberFormatter: NumberFormatter {
    override init() {
        //        self.condition = condition
        super.init()
        self.numberStyle = .decimal
        self.minimumFractionDigits = 0
        //        self.maximumFractionDigits = 2
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        guard let value = Double(string) else { return false }
        guard value >= 0 else { return false }
        obj?.pointee = NSNumber(value: value)
        return true
    }
    
    override func string(for obj: Any?) -> String? {
        guard let number = obj as? NSNumber else { return nil }
        let value = number.doubleValue
        guard value >= 0 else { return nil }
        return super.string(for: number)
    }
}
