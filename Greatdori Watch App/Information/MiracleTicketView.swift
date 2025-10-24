//===---*- Greatdori! -*---------------------------------------------------===//
//
// MiracleTicketView.swift
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

import SwiftUI
import DoriKit

struct MiracleTicketView: View {
    @State var tickets: [ExtendedMiracleTicket]?
    @State var availability = true
    @State var selectedTicket: ExtendedMiracleTicket?
    var body: some View {
        List {
            if let tickets {
                Section {
                    Picker("自选券", selection: $selectedTicket) {
                        Text("(选择一项)").tag(Optional<ExtendedMiracleTicket>.none)
                        ForEach(tickets) { ticket in
                            Text(ticket.ticket.name.forPreferredLocale() ?? "")
                                .tag(ticket)
                        }
                    }
                } header: {
                    Text("自选券可以选择卡池里任何一张卡牌")
                }
                if let selectedTicket {
                    Section {
                        InfoTextView("标题", text: selectedTicket.ticket.name)
                        InfoTextView("发布日期", date: selectedTicket.ticket.exchangeStartAt)
                        InfoTextView("结束日期", date: selectedTicket.ticket.exchangeEndAt)
                        InfoTextView(verbatim: "ID", text: String(selectedTicket.ticket.id))
                    } header: {
                        Text("信息")
                    }
                    .listRowBackground(Color.clear)
                    if let cards = selectedTicket.cards.forPreferredLocale(),
                       !cards.isEmpty {
                        Section {
                            ForEach(cards) { card in
                                ThumbCardCardView(card)
                            }
                        } header: {
                            Text(selectedTicket.ticket.name.forPreferredLocale() ?? "")
                        }
                    }
                }
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入自选券时出错", systemImage: "ticket.fill", retryHandler: getTickets)
                }
            }
        }
        .navigationTitle("自选券")
        .task {
            await getTickets()
        }
    }
    
    func getTickets() async {
        availability = true
        withDoriCache(id: "MiracleTicketList") {
            await ExtendedMiracleTicket.all()
        }.onUpdate {
            if let tickets = $0 {
                self.tickets = tickets
            } else {
                availability = false
            }
        }
    }
}
