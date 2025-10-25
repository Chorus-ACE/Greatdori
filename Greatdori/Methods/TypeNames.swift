//===---*- Greatdori! -*---------------------------------------------------===//
//
// TypeNames.swift
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
import Foundation

protocol DoriTypeDescribable {
    static var singularName: LocalizedStringResource { get }
    static var pluralName: LocalizedStringResource { get }
    static var symbol: String { get }
}

extension PreviewCharacter: DoriTypeDescribable {
    static var singularName: LocalizedStringResource { "Type.character.singular" }
    static var pluralName: LocalizedStringResource { "Type.character.plural" }
    static var symbol: String { "person.2" }
}

extension PreviewCard: DoriTypeDescribable {
    static var singularName: LocalizedStringResource { "Type.card.singular" }
    static var pluralName: LocalizedStringResource { "Type.card.plural" }
    static var symbol: String { "person.crop.square.on.square.angled" }
}

extension CardWithBand: DoriTypeDescribable {
    static var singularName: LocalizedStringResource { "Type.card.singular" }
    static var pluralName: LocalizedStringResource { "Type.card.plural" }
    static var symbol: String { "person.crop.square.on.square.angled" }
}

extension PreviewCostume: DoriTypeDescribable {
    static var singularName: LocalizedStringResource { "Type.costume.singular" }
    static var pluralName: LocalizedStringResource { "Type.costume.plural" }
    static var symbol: String { "swatchpalette" }
}

extension PreviewEvent: DoriTypeDescribable {
    static var singularName: LocalizedStringResource { "Type.event.singular" }
    static var pluralName: LocalizedStringResource { "Type.event.plural" }
    static var symbol: String { "star.hexagon" }
}

extension PreviewGacha: DoriTypeDescribable {
    static var singularName: LocalizedStringResource { "Type.gacha.singular" }
    static var pluralName: LocalizedStringResource { "Type.gacha.plural" }
    static var symbol: String { "line.horizontal.star.fill.line.horizontal" }
}

extension PreviewSong: DoriTypeDescribable {
    static var singularName: LocalizedStringResource { "Type.song.singular" }
    static var pluralName: LocalizedStringResource { "Type.song.plural" }
    static var symbol: String { "music.note" }
}

extension PreviewLoginCampaign: DoriTypeDescribable {
    static var singularName: LocalizedStringResource { "Type.login-campaign.singular" }
    static var pluralName: LocalizedStringResource { "Type.login-campaign.plural" }
    static var symbol: String { "calendar" }
}

extension Comic: DoriTypeDescribable {
    static var singularName: LocalizedStringResource { "Type.comic.singular" }
    static var pluralName: LocalizedStringResource { "Type.comic.plural" }
    static var symbol: String { "book" }
}
