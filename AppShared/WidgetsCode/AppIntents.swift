//===---*- Greatdori! -*---------------------------------------------------===//
//
// AppIntents.swift
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
import WidgetKit
import AppIntents

@available(visionOS 26.0, *)
struct CardCollectionWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Widget.collections" }
    static var description: IntentDescription { "Widget.collections.description" }
    
    @Parameter(title: "Widget.collections.parameter.name", optionsProvider: CollectionOptionsProvider())
    var collectionName: String?
    @Parameter(title: "Widget.collections.parameter.shuffle-frequency", default: .onTap)
    var shuffleFrequency: ShuffleFrequency
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
    
    struct CollectionOptionsProvider: DynamicOptionsProvider {
        func results() async throws -> [String] {
            let collections = CardCollectionManager.shared.allCollections
            return collections.map { $0.name }
        }
    }
    
    enum ShuffleFrequency: String, CaseIterable, AppEnum {
        case onTap
        case hourly
        case daily
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation {
            "Widget.shuffle-frequency"
        }
        
        static var caseDisplayRepresentations: [ShuffleFrequency: DisplayRepresentation] {
            [
                .onTap: "Widget.shuffle-frequency.on-tap",
                .hourly: "Widget.shuffle-frequency.hourly",
                .daily: "Widget.shuffle-frequency.daily"
            ]
        }
    }
}

struct EventWidgetIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Widget.event" }
    static var description: IntentDescription { "Widget.event.description" }
    
    @Parameter(title: "Widget.event.parameter.locale", default: .jp)
    var locale: WidgetDoriLocale
}

enum WidgetDoriLocale: String, CaseIterable, AppEnum {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "Widget.locale"
    
    static let caseDisplayRepresentations: [Self: DisplayRepresentation] = [
        .jp: "JP",
        .en: "EN",
        .tw: "TW",
        .cn: "CN",
        .kr: "KR"
    ]
    
    case jp
    case en
    case tw
    case cn
    case kr
    
    var doriLocale: DoriLocale {
        switch self {
        case .jp: .jp
        case .en: .en
        case .tw: .tw
        case .cn: .cn
        case .kr: .kr
        }
    }
}
