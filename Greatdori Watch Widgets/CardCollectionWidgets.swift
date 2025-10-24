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
        .supportedFamilies([.accessoryRectangular])
        .contentMarginsDisabled()
        .configurationDisplayName("Widget.collections")
        .description("Widget.collections.description")
    }
}

private struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CardEntry {
        .init()
    }
    
    func recommendations() -> [AppIntentRecommendation<CardCollectionWidgetIntent>] {
        let collections = CardCollectionManager.shared.allCollections
        return collections.map {
            let intent = CardCollectionWidgetIntent()
            intent.collectionName = $0.name
            return .init(intent: intent, description: Text($0.name))
        }
    }

    func snapshot(for configuration: CardCollectionWidgetIntent, in context: Context) async -> CardEntry {
        return entry(for: Date(), align: configuration.shuffleFrequency != .onTap, in: configuration.collectionName)
    }
    
    func timeline(for configuration: CardCollectionWidgetIntent, in context: Context) async -> Timeline<Entry> {
        let now = Date()
        let calendar = Calendar.current
        let shouldAlign = configuration.shuffleFrequency != .onTap
        let currentEntry = entry(for: now, align: shouldAlign, in: configuration.collectionName)

        let next: Date? = {
            switch configuration.shuffleFrequency {
            case .onTap:
                return nil
            case .hourly:
                let nextHour = calendar.date(byAdding: .hour, value: 1, to: calendar.date(bySetting: .minute, value: 0, of: now)!)!
                return calendar.date(bySetting: .second, value: 5, of: nextHour)
            case .daily:
                let startOfDay = calendar.startOfDay(for: now)
                let nextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                return calendar.date(bySetting: .second, value: 5, of: nextDay)
            @unknown default:
                return nil
            }
        }()

        if let next = next {
            let nextEntry = entry(for: next, align: true, in: configuration.collectionName)
            return Timeline(entries: [currentEntry, nextEntry], policy: .after(next))
        } else {
            return Timeline(entries: [currentEntry], policy: .never)
        }
    }
    
    func entry(for date: Date = .now, align: Bool = true, in collection: String?) -> CardEntry {
        guard let collectionName = collection else { return .init() }
        guard let collection = CardCollectionManager.shared._collection(named: collectionName) else { return .init() }
        var generator = seed(for: date, align: align)
        guard let card = collection.cards.randomElement(using: &generator) else { return .init() }
        guard let image = card.file.image?.resized(to: .init(width: 204, height: 90)) else { return .init() }
        return .init(date: date, image: image)
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
    var image: UIImage?
}

private struct CardWidgetsEntryView : View {
    var entry: Provider.Entry
    var body: some View {
        if let image = entry.image {
            Button(intent: CardCollectionWidgetIntent()) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            }
            .buttonStyle(.plain)
        }
    }
}

extension UIImage {
    func resized(to newSize: CGSize) -> UIImage {
        let widthRatio = newSize.width / size.width
        let heightRatio = newSize.height / size.height
        let scaleFactor = max(widthRatio, heightRatio)
        let scaledSize = CGSize(
            width: size.width * scaleFactor,
            height: size.height * scaleFactor
        )
        let x = (scaledSize.width - newSize.width) / 2
        let y = (scaledSize.height - newSize.height) / 2
        let cropRect = CGRect(origin: CGPoint(x: -x, y: -y), size: scaledSize)
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        defer { UIGraphicsEndImageContext() }
        draw(in: cropRect)
        return UIGraphicsGetImageFromCurrentImageContext()!
    }
}
