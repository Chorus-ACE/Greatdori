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

import DoriKit
import SwiftUI

struct MiracleTicketView: View {
    @State private var locale = DoriLocale.primaryLocale
    @State private var isTicketsAvailable = true
    @State private var tickets: [ExtendedMiracleTicket]?
    @State private var selectedTicket: ExtendedMiracleTicket?
    @State private var isExpanded = false
    @State private var cardsGridWidth: CGFloat = 0
    var body: some View {
        Group {
            if let tickets {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
                            CustomGroupBox {
                                VStack {
                                    ListItemView {
                                        Text("自选券")
                                    } value: {
                                        Picker(selection: $selectedTicket) {
                                            Text("(选择一项)").tag(Optional<ExtendedMiracleTicket>.none)
                                            ForEach(tickets) { ticket in
                                                if let name = ticket.ticket.name.forLocale(locale) {
                                                    Text(name).tag(ticket)
                                                }
                                            }
                                        } label: {
                                            EmptyView()
                                        }
                                        .labelsHidden()
                                    }
                                    Divider()
                                    ListItemView {
                                        Text("地区")
                                    } value: {
                                        Picker(selection: $locale) {
                                            ForEach(_DoriAPI.Locale.allCases, id: \.rawValue) { locale in
                                                Text(locale.rawValue.uppercased())
                                                    .tag(locale)
                                            }
                                        } label: {
                                            EmptyView()
                                        }
                                        .labelsHidden()
                                    }
                                }
                            }
                            if let selectedTicket {
                                Spacer()
                                    .frame(height: 15)
                                CustomGroupBox {
                                    VStack {
                                        ListItemView {
                                            Text("标题")
                                        } value: {
                                            MultilingualText(selectedTicket.ticket.name)
                                        }
                                        if let date = selectedTicket.ticket.exchangeStartAt.forLocale(locale) {
                                            Divider()
                                            ListItemView {
                                                Text("发布日期")
                                            } value: {
                                                Text(dateFormatter.string(from: date))
                                            }
                                        }
                                        if let date = selectedTicket.ticket.exchangeEndAt.forLocale(locale) {
                                            Divider()
                                            ListItemView {
                                                Text("结束日期")
                                            } value: {
                                                Text(dateFormatter.string(from: date))
                                            }
                                        }
                                        Divider()
                                        ListItemView {
                                            Text(verbatim: "ID")
                                        } value: {
                                            Text(String(selectedTicket.ticket.id))
                                        }
                                    }
                                }
                                Spacer()
                                    .frame(height: 15)
                                CustomGroupBox {
                                    VStack {
                                        if let cards = selectedTicket.cards.forLocale(locale) {
                                            LazyVGrid(columns: [.init(.adaptive(minimum: 70))]) {
                                                ForEach(trimmedCards(cards)) { card in
                                                    CardPreviewImage(card, showNavigationHints: true)
                                                }
                                            }
                                            .onFrameChange { geometry in
                                                cardsGridWidth = geometry.size.width
                                            }
                                            let trimmedCount = trimmedCount(of: cards)
                                            if trimmedCount > 0 {
                                                Button("展开 (\(trimmedCount))", systemImage: "chevron.down") {
                                                    withAnimation {
                                                        isExpanded = true
                                                    }
                                                }
                                            }
                                        } else {
                                            HStack {
                                                Spacer()
                                                Text("自选券不可用")
                                                    .bold()
                                                    .foregroundStyle(.secondary)
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: 600)
                        Spacer(minLength: 0)
                    }
                }
                .scrollDisablesPopover()
            } else {
                if isTicketsAvailable {
                    ExtendedConstraints {
                        ProgressView()
                            .controlSize(.large)
                            .onAppear {
                                loadTickets()
                            }
                    }
                } else {
                    ExtendedConstraints {
                        ContentUnavailableView("载入自选券时出错", systemImage: "ticket")
                    }
                    .onTapGesture {
                        isTicketsAvailable = true
                    }
                }
            }
        }
        .withSystemBackground()
        .navigationTitle("自选券")
    }
    
    private var dateFormatter: DateFormatter {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .short
        return df
    }
    
    func loadTickets() {
        isTicketsAvailable = true
        withDoriCache(id: "MiracleTicketList") {
            await ExtendedMiracleTicket.all()
        }.onUpdate {
            if let tickets = $0 {
                self.tickets = tickets
            } else {
                isTicketsAvailable = false
            }
        }
    }
    
    func trimmedCards(_ cards: [PreviewCard]) -> [PreviewCard] {
        if !isExpanded {
            let lineContent = Int(cardsGridWidth / 80)
            return Array(cards.prefix(lineContent * 2))
        } else {
            return cards
        }
    }
    func trimmedCount(of cards: [PreviewCard]) -> Int {
        max(cards.count - trimmedCards(cards).count, 0)
    }
}
