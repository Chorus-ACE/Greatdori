//===---*- Greatdori! -*---------------------------------------------------===//
//
// View+Variadic.swift
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
    func _variadic<V: View>(@ViewBuilder process: @escaping (_VariadicView.Children) -> V) -> some View {
        modifier(VariadicModifier(process: process))
    }
}
private struct VariadicModifier<V: View>: ViewModifier {
    var process: (_VariadicView.Children) -> V
    func body(content: Content) -> some View {
        _VariadicView.Tree(Root(process: process)) {
            content
        }
    }
    
    private struct Root<Result: View>: _VariadicView_MultiViewRoot {
        var process: (_VariadicView.Children) -> Result
        func body(children: _VariadicView.Children) -> some View {
            process(children)
        }
    }
}

extension View {
    func insert<V: View>(@ViewBuilder content: @escaping () -> V) -> some View {
        self._variadic { children in
            if let c = children.first {
                c
                ForEach(children.dropFirst(1)) { child in
                    content()
                    child
                }
            }
        }
    }
}
