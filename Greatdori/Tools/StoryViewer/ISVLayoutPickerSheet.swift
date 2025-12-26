//===---*- Greatdori! -*---------------------------------------------------===//
//
// ISVLayoutPickerSheet.swift
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
import SwiftUI

struct ISVLayoutPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("ISVHadChosenOption") private var ISVHadChosenOption = false
    @State private var hasSelectedLayout = false
    var body: some View {
        NavigationStack {
            Form {
                SettingsStoryView(hasSelectedLayout: $hasSelectedLayout)
            }
            .formStyle(.grouped)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Story-viewer.layout-test-sheet.done", systemImage: "checkmark") {
                        submit()
                    }
                    .disabled(!hasSelectedLayout)
                }
            }
        }
    }
    
    private func submit() {
        ISVHadChosenOption = true
        dismiss()
    }
}
