//===---*- Greatdori! -*---------------------------------------------------===//
//
// DetailCostumesSection.swift
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
import SDWebImageSwiftUI
import SwiftUI

// MARK: DetailsCostumesSection
struct DetailsCostumesSection: View {
    var costumes: [PreviewCostume]
    var body: some View {
        DetailSectionBase(elements: costumes.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .releaseDate(in: .jp)))) { item in
            NavigationLink(destination: {
                CostumeDetailView(id: item.id)
            }, label: {
                CostumeInfo(item)
                    .frame(maxWidth: infoContentMaxWidth)
            })
        }
    }
}
