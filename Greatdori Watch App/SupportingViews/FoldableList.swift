//===---*- Greatdori! -*---------------------------------------------------===//
//
// FoldableList.swift
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

struct FoldableList<T: Sendable, C: View>: View {
    private var items: [T]
    @State private var _builtinExpanded: Bool?
    @Binding private var isExpanded: Bool
    private var comparison: (T, T) -> Bool
    private var content: (T) -> C
    private var forEachView: (@escaping (T) -> C?) -> AnyView
    
    init(
        _ items: [T],
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping (T) -> C
    ) where T: Equatable, T: Identifiable {
        self.items = items
        self._isExpanded = isExpanded
        self.comparison = (==)
        self.content = content
        self.forEachView = { c in
            AnyView(ForEach(items) { item in
                c(item)
            })
        }
    }
    @_disfavoredOverload
    init(
        _ items: [T],
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping (T) -> C
    ) where T: Equatable, T: Hashable {
        self.items = items
        self._isExpanded = isExpanded
        self.comparison = (==)
        self.content = content
        self.forEachView = { c in
            AnyView(ForEach(items, id: \.self) { item in
                c(item)
            })
        }
    }
    init(
        _ items: [T],
        isExpanded: Binding<Bool>,
        isEqual comparison: @escaping (T, T) -> Bool,
        @ViewBuilder content: @escaping (T) -> C
    ) where T: Identifiable {
        self.items = items
        self._isExpanded = isExpanded
        self.comparison = comparison
        self.content = content
        self.forEachView = { c in
            AnyView(ForEach(items) { item in
                c(item)
            })
        }
    }
    init(
        _ items: [T],
        isExpanded: Binding<Bool>,
        @ViewBuilder content: @escaping (T) -> C
    ) where T: Identifiable {
        self.items = items
        self._isExpanded = isExpanded
        self.comparison = { $0.id == $1.id }
        self.content = content
        self.forEachView = { c in
            AnyView(ForEach(items) { item in
                c(item)
            })
        }
    }
    @_disfavoredOverload
    init(
        _ items: [T],
        isExpanded: Binding<Bool>,
        isEqual comparison: @escaping (T, T) -> Bool,
        @ViewBuilder content: @escaping (T) -> C
    ) where T: Hashable {
        self.items = items
        self._isExpanded = isExpanded
        self.comparison = comparison
        self.content = content
        self.forEachView = { c in
            AnyView(ForEach(items, id: \.self) { item in
                c(item)
            })
        }
    }
    init(
        _ items: [T],
        @ViewBuilder content: @escaping (T) -> C
    ) where T: Equatable, T: Identifiable {
        self.items = items
        self._builtinExpanded = false
        self._isExpanded = .constant(false)
        self.comparison = (==)
        self.content = content
        self.forEachView = { c in
            AnyView(ForEach(items) { item in
                c(item)
            })
        }
    }
    @_disfavoredOverload
    init(
        _ items: [T],
        @ViewBuilder content: @escaping (T) -> C
    ) where T: Equatable, T: Hashable {
        self.items = items
        self._builtinExpanded = false
        self._isExpanded = .constant(false)
        self.comparison = (==)
        self.content = content
        self.forEachView = { c in
            AnyView(ForEach(items, id: \.self) { item in
                c(item)
            })
        }
    }
    init(
        _ items: [T],
        isEqual comparison: @escaping (T, T) -> Bool,
        @ViewBuilder content: @escaping (T) -> C
    ) where T: Identifiable {
        self.items = items
        self._builtinExpanded = false
        self._isExpanded = .constant(false)
        self.comparison = comparison
        self.content = content
        self.forEachView = { c in
            AnyView(ForEach(items) { item in
                c(item)
            })
        }
    }
    init(
        _ items: [T],
        @ViewBuilder content: @escaping (T) -> C
    ) where T: Identifiable {
        self.items = items
        self._builtinExpanded = false
        self._isExpanded = .constant(false)
        self.comparison = { $0.id == $1.id }
        self.content = content
        self.forEachView = { c in
            AnyView(ForEach(items) { item in
                c(item)
            })
        }
    }
    @_disfavoredOverload
    init(
        _ items: [T],
        isEqual comparison: @escaping (T, T) -> Bool,
        @ViewBuilder content: @escaping (T) -> C
    ) where T: Hashable {
        self.items = items
        self._builtinExpanded = false
        self._isExpanded = .constant(false)
        self.comparison = comparison
        self.content = content
        self.forEachView = { c in
            AnyView(ForEach(items, id: \.self) { item in
                c(item)
            })
        }
    }
    
    var body: some View {
        if !items.isEmpty {
            forEachView { item in
                if (_builtinExpanded ?? isExpanded) || comparison(item, items.first!) {
                    content(item)
                } else {
                    nil
                }
            }
            if items.count > 1 {
                Button(
                    _builtinExpanded ?? isExpanded ? "收起" : "显示所有",
                    systemImage: _builtinExpanded ?? isExpanded ? "rectangle.compress.vertical" : "rectangle.expand.vertical"
                ) {
                    withAnimation {
                        if _builtinExpanded != nil {
                            _builtinExpanded!.toggle()
                        } else {
                            isExpanded.toggle()
                        }
                    }
                }
            }
        }
    }
}
