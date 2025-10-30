//===---*- Greatdori! -*---------------------------------------------------===//
//
// SearchView.swift
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
import DoriKit

struct SearchView<T: _DoriFrontend.Searchable>: View {
    var items: [T]
    @Binding var text: String
    var completion: ([T]) -> Void
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Form {
            Section {
                TextField("搜索...", text: $text)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit {
                        completion(items.search(for: text))
                    }
            }
        }
    }
}
