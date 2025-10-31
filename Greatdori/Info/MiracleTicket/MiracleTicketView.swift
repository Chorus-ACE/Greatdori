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
                                        Text("Miracle-ticket.ticket")
                                    } value: {
                                        if #available(iOS 18.0, macOS 15.0, *) {
                                            Picker(selection: $selectedTicket, content: {
                                                ForEach(tickets) { ticket in
                                                    if let name = ticket.ticket.name.forLocale(locale) {
                                                        Text(name).tag(ticket)
                                                    }
                                                }
                                            }, label: {
                                                EmptyView()
                                            }, currentValueLabel: {
                                                if let selectedTicket {
                                                    Text(selectedTicket.ticket.name.forLocale(locale) ?? "")
                                                } else {
                                                    Text("Miracle-ticket.ticket.select")
                                                }
                                            })
                                            .labelsHidden()
                                        } else {
                                            Picker(selection: $selectedTicket, content: {
                                                ForEach(tickets) { ticket in
                                                    if let name = ticket.ticket.name.forLocale(locale) {
                                                        Text(name).tag(ticket)
                                                    }
                                                }
                                            }, label: {
                                                EmptyView()
                                            })
                                            .labelsHidden()
                                        }
                                    }
                                    Divider()
                                    ListItemView {
                                        Text("Miracle-ticket.locale")
                                    } value: {
                                        Picker(selection: $locale) {
                                            ForEach(DoriLocale.allCases, id: \.rawValue) { locale in
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
                                DetailSectionsSpacer(height: 15)
                                CustomGroupBox {
                                    VStack {
                                        ListItemView {
                                            Text("Miracle-ticket.title")
                                        } value: {
                                            MultilingualText(selectedTicket.ticket.name)
                                        }
                                        if let date = selectedTicket.ticket.exchangeStartAt.forLocale(locale) {
                                            Divider()
                                            ListItemView {
                                                Text("Miracle-ticket.release-date")
                                            } value: {
                                                Text(dateFormatter.string(from: date))
                                            }
                                        }
                                        if let date = selectedTicket.ticket.exchangeEndAt.forLocale(locale) {
                                            Divider()
                                            ListItemView {
                                                Text("Miracle-ticket.close-date")
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
                                                Button(action: {
                                                    withAnimation {
                                                        isExpanded = true
                                                    }
                                                }, label: {
                                                    Label("Miracle.expand.\(trimmedCount)", systemImage: "chevron.down")
                                                })
                                            }
                                        } else {
                                            HStack {
                                                Spacer()
                                                Text("Miracle-ticket.unavailable")
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
                        ContentUnavailableView("Miracle-ticket.error", systemImage: "ticket")
                    }
                    .onTapGesture {
                        isTicketsAvailable = true
                    }
                }
            }
        }
        .withSystemBackground()
        .navigationTitle("Miracle-ticket")
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
