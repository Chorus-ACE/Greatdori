//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardCollectionWidgets.swift
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
import WidgetKit
import AppIntents

struct CardCollectionWidgets: Widget {
    let kind: String = "com.memz233.Greatdori.Widgets.CardCollection"
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: CardCollectionWidgetIntent.self, provider: Provider()) { entry in
            CardWidgetsEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemMedium, .systemLarge, .systemExtraLarge])
        .contentMarginsDisabled()
        .configurationDisplayName("Widget.collections")
        .description("Widget.collections.description")
    }
}

private struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CardEntry {
        .init()
    }

    func snapshot(for configuration: CardCollectionWidgetIntent, in context: Context) async -> CardEntry {
        if context.isPreview {
            return entry(in: "BUILTIN_CARD_COLLECTION_GREATDORI", frequency: configuration.shuffleFrequency)
        }
        return entry(in: configuration.collectionName, frequency: configuration.shuffleFrequency)
    }
    
    func timeline(for configuration: CardCollectionWidgetIntent, in context: Context) async -> Timeline<Entry> {
        let policy: TimelineReloadPolicy = switch configuration.shuffleFrequency {
        case .onTap: .never
        case .hourly: .after(Date.now.addingTimeInterval(60 * 60).componentsRewritten(minute: 0, second: 0))
        case .daily: .after(Date.now.addingTimeInterval(60 * 60 * 24).componentsRewritten(hour: 0, minute: 0, second: 0))
        }
        return .init(
            entries: [
                entry(align: false, in: configuration.collectionName, frequency: configuration.shuffleFrequency)
            ],
            policy: policy
        )
    }
    
    func entry(
        for date: Date = .now,
        align: Bool = true,
        in collection: String?,
        frequency: CardCollectionWidgetIntent.ShuffleFrequency
    ) -> CardEntry {
        guard let collectionName = collection else { return .init(frequency: frequency) }
        guard let collection = CardCollectionManager.shared._collection(named: collectionName) else { return .init(frequency: frequency) }
        var generator = seed(for: date, align: align)
        guard let card = collection.cards.randomElement(using: &generator) else { return .init(frequency: frequency) }
        guard let image = card.image else { return .init(frequency: frequency, emptyReason: 1) }
        return .init(date: date, frequency: frequency, cardID: card.id, image: image)
    }
    
    func seed(for date: Date = .now, align: Bool = true) -> some RandomNumberGenerator {
        struct RandomNumberGeneratorWithSeed: RandomNumberGenerator {
            private var state: UInt64
            init(seed: UInt64) {
                self.state = UInt64(seed) ^ 0x5DEECE66D
            }
            mutating func next() -> UInt64 {
                state = state &* 0x5851F42D4C957F2D &+ 1
                return state
            }
        }
        
        var date = date
        if align {
            date = date.componentsRewritten(second: 0)
        }
        let seed = align ? UInt64(date.timeIntervalSince1970) : UInt64(date.timeIntervalSince1970 * 1000000)
        return RandomNumberGeneratorWithSeed(seed: seed)
    }
}

private struct CardEntry: TimelineEntry {
    var date: Date = .now
    var frequency: CardCollectionWidgetIntent.ShuffleFrequency = .onTap
    var emptyReason: UInt8 = 0
    var cardID: Int?
    #if !os(macOS)
    var image: UIImage?
    #else
    var image: NSImage?
    #endif
}

private struct CardWidgetsEntryView : View {
    var entry: Provider.Entry
    var body: some View {
        if let image = entry.image {
            if entry.frequency != .onTap, let cardID = entry.cardID {
                Group {
                    #if !os(macOS)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                    #else
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                    #endif
                }
                .widgetURL(URL(string: "greatdori://info/cards/\(cardID)"))
            } else {
                Button(intent: CardCollectionWidgetIntent()) {
                    #if !os(macOS)
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                    #else
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                    #endif
                }
                .buttonStyle(.plain)
            }
        } else {
            switch entry.emptyReason {
            case 0x1:
                HStack {
                    Spacer()
                    VStack {
                        Image(systemName: "network.slash")
                        Text("Widget.collections.no-internet")
                    }
                    Spacer()
                }
                .bold()
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding()
            default:
                Text("Widget.collections.edit-tip")
                    .bold()
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
            }
        }
    }
}
