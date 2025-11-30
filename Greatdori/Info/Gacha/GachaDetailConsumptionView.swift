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
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section {
                CustomGroupBox {
                    VStack {
                        Table(information.gacha.paymentMethods) {
                            TableColumn("抽卡的数量") { paymentMethod in
                                Text("\(paymentMethod.count)次抽卡")
                            }
                            TableColumn("消耗星石") { paymentMethod in
                                HStack {
                                    WebImage(url: paymentMethod.paymentMethod.iconImageURL)
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                    Text(verbatim: "\(paymentMethod.paymentMethod.localizedString) x\(paymentMethod.count)")
                                }
                            }
                            TableColumn("备注") { paymentMethod in
                                if paymentMethod.behavior != .normal {
                                    Text(verbatim: "\(paymentMethod.behavior.localizedString)" + (paymentMethod.maxSpinLimit != nil ? ", " + String(localized: "最多\(paymentMethod.maxSpinLimit!)次") : ""))
                                }
                            }
                        }
                        .frame(height: 200)
                    }
                }
                .frame(maxWidth: infoContentMaxWidth)
            } header: {
                HStack {
                    Text("Gacha.consumption")
                        .font(.title2)
                        .bold()
                    Spacer()
                }
                .frame(maxWidth: 615)
            }
        }
    }
}

extension Gacha.PaymentMethod: @retroactive Identifiable {
    public var id: Int { self.hashValue }
}
