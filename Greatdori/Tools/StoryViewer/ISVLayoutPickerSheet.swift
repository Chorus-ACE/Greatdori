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
    @AppStorage("ISVHadChosenOption") var ISVHadChosenOption = false
    @AppStorage("ISVAlwaysFullScreen") var isvAlwaysFullScreen = false
    @State var selection = "N"
    var body: some View {
        NavigationStack {
            /*
            VStack {
                Text("Story-viewer.layout-test-sheet.title")
                    .font(.largeTitle)
                    .bold()
                //            Text()
                Text("Story-viewer.layout-test-sheet.body")
                
                HStack {
                    Text(verbatim: "1")
                    Text(verbatim: "2")
                }
                Spacer()
#if os(iOS)
                Button(action: {
                    
                }, label: {
                    Text(verbatim: "3")
                })
#endif
            }
             */
            EmptyView()
            .padding()
            .toolbar {
#if os(macOS)
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        submit()
                    }, label: {
                        Text(verbatim: "Story-viewer.layout-test-sheet.done")
                    })
                    .disabled(selection == "N")
                }
#endif
            }
        }
    }
    private func submit() {
        isvAlwaysFullScreen = selection == "F"
        ISVHadChosenOption = true
    }
}
