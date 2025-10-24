//===---*- Greatdori! -*---------------------------------------------------===//
//
// OnChange+.swift
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

extension View {
    func onChange<each V: Equatable>(
        of value: repeat each V,
        initial: Bool = false,
        _ action: @escaping () -> Void
    ) -> some View {
        var result = AnyView(self)
        for v in repeat each value {
            result = AnyView(result.onChange(of: v, initial: initial, action))
        }
        return result
    }
}
