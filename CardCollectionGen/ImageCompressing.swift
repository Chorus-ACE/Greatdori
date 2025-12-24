//===---*- Greatdori! -*---------------------------------------------------===//
//
// ImageCompressing.swift
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

import ImageIO
import Foundation

func compressImages(at path: String) throws {
    let contents = try FileManager.default.contentsOfDirectory(atPath: path)
    for content in contents where content.hasSuffix(".png") {
        let imagePath = path + "/\(content)"
        guard let inputImage = CGImageSourceCreateWithURL(URL(filePath: imagePath) as CFURL, nil) else {
            continue
        }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: 0.3
        ]
        guard let destination = CGImageDestinationCreateWithURL(URL(filePath: imagePath) as CFURL, "public.heic" as CFString, 1, nil) else {
            continue
        }
        CGImageDestinationAddImageFromSource(destination, inputImage, 0, options as CFDictionary)
        CGImageDestinationFinalize(destination)
    }
}
