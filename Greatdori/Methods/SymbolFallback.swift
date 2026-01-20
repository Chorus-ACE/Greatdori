//===---*- Greatdori! -*---------------------------------------------------===//
//
// SymbolFallback.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2026 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.com/LICENSE.txt for license information
// See https://greatdori.com/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import SymbolAvailability

extension SFSymbol {
    enum Fallbackable {
        static var clockArrowTriangleheadClockwiseRotate90PathDotted: SFSymbol {
            if #available(macOS 26.0, iOS 26.0, visionOS 26.0, *) {
                SFSymbol.clockArrowTriangleheadClockwiseRotate90PathDotted
            } else {
                SFSymbol.clockArrowCirclepath
            }
        }
    }
}
