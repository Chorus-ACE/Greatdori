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

import Foundation

@dynamicMemberLookup
struct AppFlag {
    private init() {}
    
    static subscript(dynamicMember dynamicMember: String) -> Bool {
        UserDefaults.standard.bool(forKey: "AppFlag_\(dynamicMember)")
    }
    
    static func set(_ value: Bool, forKey key: String) {
        UserDefaults.standard.set(value, forKey: "AppFlag_\(key)")
    }
}
