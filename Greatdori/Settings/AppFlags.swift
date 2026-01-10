//===---*- Greatdori! -*---------------------------------------------------===//
//
// AppFlags.swift
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
import Foundation

@dynamicMemberLookup
struct AppFlag {
    private init() {}
    
    static subscript(dynamicMember dynamicMember: String) -> Bool {
        AppFlag.get(key: dynamicMember)
    }
    
    static func set(_ value: Bool, forKey key: String) {
        UserDefaults.standard.set(value, forKey: "AppFlag_\(key)")
    }
    
    static func get(key: String) -> Bool {
        UserDefaults.standard.bool(forKey: "AppFlag_\(key)")
    }
    
    static func bindingValue(forKey key: String) -> Binding<Bool> {
        .init(get: { AppFlag.get(key: key) }, set: { AppFlag.set($0, forKey: key) })
    }
}
