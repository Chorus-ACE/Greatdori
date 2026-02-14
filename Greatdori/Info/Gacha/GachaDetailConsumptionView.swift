//===---*- Greatdori! -*---------------------------------------------------===//
//
// GachaDetailConsumptionView.swift
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
import SDWebImageSwiftUI

struct GachaDetailConsumptionView: View {
    var information: ExtendedGacha
    @Environment(\.horizontalSizeClass) private var sizeClass
    var body: some View {
        Section {
            CustomGroupBox {
                VStack {
                    if sizeClass == .regular {
                        Table(information.gacha.paymentMethods) {
                            TableColumn("Gacha.costs.type") { paymentMethod in
                                Text("Gacha.costs.type.plays.\(paymentMethod.count)")
                            }
                            TableColumn("Gacha.costs.costs") { paymentMethod in
                                HStack {
                                    WebImage(url: paymentMethod.paymentMethod.iconImageURL)
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                    Text(verbatim: "\(paymentMethod.paymentMethod.localizedString) x\(paymentMethod.count)")
                                }
                            }
                            TableColumn("Gacha.costs.note") { paymentMethod in
                                if paymentMethod.behavior != .normal {
                                    Text(verbatim: "\(paymentMethod.behavior.localizedString)" + (paymentMethod.maxSpinLimit != nil ? ", " + String(localized: "Gacha.costs.note.maximum.\(paymentMethod.maxSpinLimit!)") : ""))
                                }
                            }
                        }
                        .scrollDisabled(true)
                        .frame(height: 30*CGFloat(information.gacha.paymentMethods.count + 1))
                    } else {
                        Grid(alignment: .leading) {
                            GridRow {
                                Text("Gacha.costs.type")
                                Text("Gacha.costs.costs")
                                Text("Gacha.costs.note")
                            }
                            ForEach(Array(information.gacha.paymentMethods.enumerated()), id: \.element.id) { (index, paymentMethod) in
                                Divider()
                                GridRow {
                                    Text("Gacha.costs.type.plays.\(paymentMethod.count)")
                                    HStack {
                                        WebImage(url: paymentMethod.paymentMethod.iconImageURL)
                                            .resizable()
                                            .frame(width: 20, height: 20)
                                        Text(verbatim: "\(paymentMethod.paymentMethod.localizedString) x\(paymentMethod.count)")
                                    }
                                    if paymentMethod.behavior != .normal {
                                        Text(verbatim: "\(paymentMethod.behavior.localizedString)" + (paymentMethod.maxSpinLimit != nil ? ", " + String(localized: "Gacha.costs.note.maximum.\(paymentMethod.maxSpinLimit!)") : ""))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: infoContentMaxWidth)
        } header: {
            HStack {
                Text("Gacha.costs")
                    .font(.title2)
                    .bold()
                Spacer()
            }
            .frame(maxWidth: 615)
            .detailSectionHeader()
        }
    }
}

extension Gacha.PaymentMethod: @retroactive Identifiable {
    public var id: Int { self.hashValue }
}
