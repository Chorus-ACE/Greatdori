//===---*- Greatdori! -*---------------------------------------------------===//
//
// GachaDetailPossibilityView.swift
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
import SwiftUI

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
                                Text("Gacha.possibility.locale")
                            }, value: {
                                LocalePicker($locale)
                            })
                            
                            Divider()
                            
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
                                            .frame(maxWidth: 100)
                                        Stepper("", value: $possibility, in: 0...99)
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
                                            .frame(maxWidth: 100)
                                        Stepper("", value: $plays, in: 0...Int.max)
                                            .labelsHidden()
                                    }
                                })
                            }
                        }
                    }
                    CustomGroupBox {
                        HStack {
                            Text(calculateProbability())
                            Spacer(minLength: 0)
                        }
                        .multilineTextAlignment(.leading)
                    }
                }
                .frame(maxWidth: infoContentMaxWidth)
            }, header: {
                HStack {
                    Text("Gacha.possibility")
                        .font(.title2)
                        .bold()
                    Spacer()
                }
                .frame(maxWidth: 615)
            })
        }
    }
    
    func calculateProbability() -> LocalizedStringKey {
        guard let selectedCard else {
            return "Gacha.possibility.error.card-not-selected"
        }
        
        guard let rates = information.gacha.rates.forLocale(locale)?[selectedCard.rarity] else {
            return "Gacha.possibility.error.\(-101)"
        }
        guard let weight = information.gacha.details.forLocale(locale)?[selectedCard.id]?.weight else {
            return "Gacha.possibility.error.\(-102)"
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
                return "Gacha.possibility.error.\(-201)"
            }
            let t = Int(ceil(log(1 - n) / log(1 - e)))
            return "Gacha.possibility.possibility.\(t).\(t * i).\(unsafe String(format: "%.1f", n * 100))"
        } else {
            let r = Double(plays)
            guard r >= 0 else {
                return "Gacha.possibility.error.\(-301)"
            }
            let t = 1 - pow(1.0 - e, r)
            return "Gacha.possibility.plays.\(plays).\(plays * i).\(unsafe String(format: "%.1f", t * 100))"
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
