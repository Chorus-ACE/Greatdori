//===---*- Greatdori! -*---------------------------------------------------===//
//
// ImagePrefetch.swift
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

import SDWebImage
import Foundation

func prefetchImages(_ urls: [URL]) {
    DispatchQueue.main.async {
        if !NetworkMonitor.shared.preferConstrained {
            Task.detached {
                _ = SDWebImagePrefetcher.shared.prefetchURLs(urls)
            }
        }
    }
}
