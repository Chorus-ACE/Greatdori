//===---*- Greatdori! -*---------------------------------------------------===//
//
// DetailsGachasSection.swift
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


// MARK: DetailsGachasSection
struct DetailsGachasSection: View {
    var gachas: [PreviewGacha]?
    var sources: LocalizedData<Set<ExtendedCard.Source>>?
    var applyLocaleFilter: Bool = false
    @State var gachasFromList = LocalizedData<[PreviewGacha]>(repeating: nil)
    @State var gachasFromSources = LocalizedData<[PreviewGacha]>(repeating: nil)
    @State var probabilityDict: [Int /* Gacha ID */: Double] = [:]
    @State var showAll = false
    @State var sourcePreference: Int
    
    init(gachas: [PreviewGacha], applyLocaleFilter: Bool = false) {
        self.gachas = gachas
        self.sources = nil
        self.applyLocaleFilter = applyLocaleFilter
        self.sourcePreference = 0
    }
    init(sources: LocalizedData<Set<ExtendedCard.Source>>) {
        self.gachas = nil
        self.sources = sources
        self.applyLocaleFilter = true
        self.sourcePreference = 1
    }
    
    var body: some View {
        DetailSectionBase(elements: sourcePreference == 0 ? gachasFromList : gachasFromSources, showLocalePicker: applyLocaleFilter) { item in
            if sourcePreference == 0 {
                NavigationLink(destination: {
                    GachaDetailView(id: item.id)
                }, label: {
                    GachaInfo(item)
                        .regularInfoImageSizeFactor(0.85)
                        .frame(maxWidth: infoContentMaxWidth)
                })
            } else {
                NavigationLink(destination: {
                    GachaDetailView(id: item.id)
                }, label: {
                    GachaInfo(item, subtitle: unsafe "Details.gachas.source.chance.\(String(format: "%.2f", (probabilityDict[item.id] ?? 0)*100) + String("%"))", showDetails: true)
                        .frame(maxWidth: infoContentMaxWidth)
                })
            }
        }
        .onAppear {
            handleGachas()
        }
    }
    
    func handleGachas() {
        gachasFromList = .init(repeating: nil)
        gachasFromSources = .init(repeating: nil)
        probabilityDict = [:]
        
        if sourcePreference == 0 {
            if let gachas {
                for locale in DoriLocale.allCases {
                    gachasFromList.set(
                        gachas
                            .filter { applyLocaleFilter ? $0.publishedAt.availableInLocale(locale) : true }
                            .sorted(withDoriSorter: .init(keyword: .releaseDate(in: locale))),
                        forLocale: locale
                    )
                }
            }
        } else {
            if let sources {
                for locale in DoriLocale.allCases {
                    for item in Array(sources.forLocale(locale) ?? Set()) {
                        switch item {
                        case .gacha(let dict):
                            for (gacha, probability) in dict {
                                gachasFromSources.set(
                                    (gachasFromSources.forLocale(locale) ?? []) + [gacha],
                                    forLocale: locale
                                )
                                probabilityDict.updateValue(probability, forKey: gacha.id)
                            }
                            gachasFromSources[locale]?.sort(withDoriSorter: .init(keyword: .releaseDate(in: locale)))
                        default: break
                        }
                    }
                }
            }
        }
    }
}
