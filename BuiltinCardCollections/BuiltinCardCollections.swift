//===---*- Greatdori! -*---------------------------------------------------===//
//
// BuiltinCardCollections.swift
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

#if os(macOS)
import AppKit
#else
import UIKit
#endif

@_eagerMove
public struct BuiltinCardCollection: Codable {
    public var name: String
    public var cards: [BuiltinCard]
}
@_eagerMove
public struct BuiltinCard: Codable {
    public var localizedName: DoriAPI.LocalizedData<String>
    public var fileName: String
    
    #if !os(macOS)
    @inlinable
    public var image: UIImage {
        builtinImage(named: fileName)
    }
    #else
    @inlinable
    public var image: NSImage {
        builtinImage(named: fileName)
    }
    #endif
}

public let builtinCardCollectionNames = [
    "BUILTIN_CARD_COLLECTION_GREATDORI",
    "BUILTIN_CARD_COLLECTION_MYGO",
    "BUILTIN_CARD_COLLECTION_HIKAWA_TWINS"
]

#if !os(macOS)
public func builtinImage(named name: String) -> UIImage {
    UIImage(contentsOfFile: #bundle.path(forResource: name, ofType: "png", inDirectory: "Collections")!)!
}
#else
public func builtinImage(named name: String) -> NSImage {
    NSImage(contentsOfFile: #bundle.path(forResource: name, ofType: "png", inDirectory: "Collections")!)!
}
#endif

extension BuiltinCardCollection {
    @inline(never)
    public init?(named name: String) {
        let decoder = PropertyListDecoder()
        guard let _url = #bundle.url(
            forResource: name,
            withExtension: "plist",
            subdirectory: "Collections"
        ), let data = try? Data(contentsOf: consume _url) else { return nil }
        if let collection = try? decoder.decode(BuiltinCardCollection.self, from: data) {
            self = collection
        } else {
            return nil
        }
    }
}

extension Array<BuiltinCardCollection> {
    public static func all() -> Self {
        var result = Self()
        for name in builtinCardCollectionNames {
            result.append(.init(named: name)!)
        }
        return result
    }
}

extension BuiltinCard {
    @inlinable
    public var id: Int {
        let dropped = fileName.dropFirst("Card".count)
        return if dropped.hasSuffix("After") {
            Int(dropped.dropLast("After".count))!
        } else {
            Int(dropped.dropLast("Before".count))!
        }
    }
    @inlinable
    public var isTrained: Bool {
        fileName.hasSuffix("After")
    }
}
