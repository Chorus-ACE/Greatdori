//===---*- Greatdori! -*---------------------------------------------------===//
//
// WrapIf.swift
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
    @ViewBuilder
    func wrapIf(
        _ condition: Bool,
        @ViewBuilder in container: (Self) -> some View
    ) -> some View {
        if condition {
            container(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func wrapIf(
        _ condition: Bool,
        @ViewBuilder in container: (Self) -> some View,
        @ViewBuilder else elseContainer: (Self) -> some View
    ) -> some View {
        if condition {
            container(self)
        } else {
            elseContainer(self)
        }
    }
    
    @ViewBuilder
    func wrapIfLet<T>(
        _ optional: T?,
        @ViewBuilder in container: (Self, T) -> some View
    ) -> some View {
        if let wrapped = optional {
            container(self, wrapped)
        } else {
            self
        }
    }
}
