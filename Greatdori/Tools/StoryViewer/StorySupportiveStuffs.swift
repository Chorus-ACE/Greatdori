//===---*- Greatdori! -*---------------------------------------------------===//
//
// StorySupportiveStuffs.swift
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
@_spi(Advanced) import SwiftUIIntrospect

enum StoryType: String, CaseIterable, Hashable {
    case event
    case main
    case band
    case card
    case actionSet
    case afterLive
    
    var name: LocalizedStringKey {
        switch self {
        case .event: "Story-viewer.type.event"
        case .main: "Story-viewer.type.main"
        case .band: "Story-viewer.type.band"
        case .card: "Story-viewer.type.card"
        case .actionSet: "Story-viewer.type.action-set"
        case .afterLive: "Story-viewer.type.after-live"
        }
    }
}

public struct CustomStory: Sendable, Identifiable, Hashable, DoriCache.Cacheable, Equatable {
    public var scenarioID: String
    public var caption: String
    public var title: LocalizedData<String>
    public var synopsis: String
    public var voiceAssetBundleName: String?
    public var note: String? = nil
    public var characterIDs: [Int]? = nil
    
    public var id: String { scenarioID }
}

extension _DoriAPI.Story {
    func convertToLocalizedData() -> LocalizedData<CustomStory> {
        var result = LocalizedData<CustomStory>()
        for locale in DoriLocale.allCases {
            if self.title.availableInLocale(locale) {
                result._set(
                    CustomStory(
                        scenarioID: self.scenarioID,
                        caption: self.caption.forLocale(locale) ?? "",
                        title: self.title,
                        synopsis: self.synopsis.forLocale(locale) ?? "",
                        voiceAssetBundleName: self.voiceAssetBundleName
                    ),
                    forLocale: locale
                )
            }
        }
        return result
    }
}

extension Array<_DoriAPI.Story> {
    func convertToLocalizedData() -> LocalizedData<[CustomStory]> {
        var result = LocalizedData<[CustomStory]>()
        for story in self {
            for locale in DoriLocale.allCases {
                if story.title.availableInLocale(locale) {
                    result._set(
                        (result.forLocale(locale) ?? []) + [CustomStory(
                            scenarioID: story.scenarioID,
                            caption: story.caption.forLocale(locale) ?? "",
                            title: story.title,
                            synopsis: story.synopsis.forLocale(locale) ?? "",
                            voiceAssetBundleName: story.voiceAssetBundleName
                        )],
                        forLocale: locale
                    )
                }
            }
        }
        return result
    }
}

struct MultiCharacterSelectorButton: View {
    @Binding var filter: DoriFilter
    var characterMatchesOthers: Bool = false
    @State private var selectorWindowIsPresented = false
    var body: some View {
        Button(action: {
            selectorWindowIsPresented = true
        }, label: {
            HStack {
                Text(multiCharSelectorLabel(for: filter))
                    .multilineTextAlignment(.trailing)
                Image(systemName: "chevron.up.chevron.down")
                    .bold(isMACOS)
                    .font(.footnote)
            }
        })
        .padding(.vertical, isMACOS ? 0 : 3)
        .onDisappear {
            selectorWindowIsPresented = false
        }
        .window(isPresented: $selectorWindowIsPresented) {
            NavigationStack {
                FilterView(filter: $filter, includingKeys: Set([.character, .characterRequiresMatchAll] + (characterMatchesOthers ? [.characterMatchesOthers] : [])))
                    .formStyle(.grouped)
            }
            .navigationTitle("Selector.multi-char")
            #if os(macOS)
            .introspect(.window, on: .macOS(.v14...)) { window in
                window.standardWindowButton(.zoomButton)?.isEnabled = false
                window.standardWindowButton(.miniaturizeButton)?.isEnabled = false
                window.collectionBehavior = [.fullScreenAuxiliary, .fullScreenNone]
                window.level = .floating
            }
            #endif
        }
    }
    
    func multiCharSelectorLabel(for filter: DoriFilter) -> LocalizedStringResource {
        let characters = filter.character.sorted(by: { $0.rawValue < $1.rawValue }) + (filter.characterMatchesOthers == .includeOthers ? [nil] : [])
        if characters.isEmpty {
            return "Selector.multi-char.none"
        } else if characters.count == 1 {
            return "Selector.multi-char.one.\(filter.character.first?.name ?? String(localized: "Character.other"))"
        } else if characters.count == 2 {
            if filter.characterRequiresMatchAll {
                return "Selector.multi-char.two.and.\(characters[0]?.name ?? String(localized: "Character.other")).\(characters[1]?.name ?? String(localized: "Character.other"))"
            } else {
                return "Selector.multi-char.two.or.\(characters[0]?.name ?? String(localized: "Character.other")).\(characters[1]?.name ?? String(localized: "Character.other"))"
            }
        } else {
            if filter.characterRequiresMatchAll {
                return "Selector.multi-char.mutliple.and.\(characters.count)"
            } else {
                return "Selector.multi-char.mutliple.or.\(characters.count)"
            }
        }
    }
}

