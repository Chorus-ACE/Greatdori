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
    @inline(never)
    public var image: UIImage {
        #if !os(watchOS)
        .init(resource: .init(name: fileName, bundle: #bundle))
        #else
        .init(named: fileName, in: #bundle, with: nil)!
        #endif
    }
    #else
    @inline(never)
    public var image: NSImage {
        .init(resource: .init(name: fileName, bundle: #bundle))
    }
    #endif
}

public let builtinCardCollectionNames = [
    "BUILTIN_CARD_COLLECTION_GREATDORI",
    "BUILTIN_CARD_COLLECTION_MYGO"
]

#if !os(macOS)
public func builtinImage(named name: String) -> UIImage {
    #if !os(watchOS)
    .init(resource: .init(name: name, bundle: #bundle))
    #else
    .init(named: name, in: #bundle, with: nil)!
    #endif
}
#else
public func builtinImage(named name: String) -> NSImage {
    .init(resource: .init(name: name, bundle: #bundle))
}
#endif

extension BuiltinCardCollection {
    @inline(never)
    @_optimize(size)
    public init?(named name: String) {
        let decoder = PropertyListDecoder()
        let data = NSDataAsset(name: name, bundle: #bundle)!.data
        if let collection = try? decoder.decode(BuiltinCardCollection.self, from: data) {
            self = collection
        } else {
            return nil
        }
    }
}

extension Array<BuiltinCardCollection> {
    @_optimize(size)
    public static func all() -> Self {
        let decoder = PropertyListDecoder()
        var result = Self()
        for name in builtinCardCollectionNames {
            let data = NSDataAsset(name: name, bundle: #bundle)!.data
            result.append(try! decoder.decode(BuiltinCardCollection.self, from: data))
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
