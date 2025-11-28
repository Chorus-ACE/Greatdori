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
    @State var locale: DoriLocale = DoriLocale.primaryLocale
    @State var gachasFromList: [PreviewGacha] = []
    @State var gachasFromSources: [PreviewGacha] = []
    @State var probabilityDict: [PreviewGacha: Double] = [:]
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
                    GachaInfo(item, subtitle: unsafe "Details.gachas.source.chance.\(String(format: "%.2f", (probabilityDict[item] ?? 0)*100) + String("%"))", showDetails: true)
                        .frame(maxWidth: infoContentMaxWidth)
                })
            }
        }
        .onAppear {
            handleGachas()
        }
        .onChange(of: locale) {
            handleGachas()
        }
    }
    
    func handleGachas() {
        gachasFromList = []
        gachasFromSources = []
        probabilityDict = [:]
        
        if sourcePreference == 0 {
            if let gachas {
                gachasFromList = gachas.sorted(withDoriSorter: _DoriFrontend.Sorter(keyword: .releaseDate(in: applyLocaleFilter ? locale : .jp)))
                if applyLocaleFilter {
                    gachasFromList = gachasFromList.filter {$0.publishedAt.availableInLocale(locale)}
                }
            }
        } else {
            if let sources {
                for item in Array(sources.forLocale(locale) ?? Set()) {
                    switch item {
                    case .gacha(let dict):
                        for (key, value) in dict {
                            gachasFromSources.append(key)
                            probabilityDict.updateValue(value, forKey: key)
                        }
                        gachasFromSources = gachasFromSources.sorted(withDoriSorter: DoriSorter(keyword: .releaseDate(in: locale)))
                    default: break
                    }
                }
            }
        }
    }
    
    func getGachasCount() -> Int {
        if sourcePreference == 0 {
            return gachasFromList.count
        } else {
            return gachasFromSources.count
        }
    }
}
