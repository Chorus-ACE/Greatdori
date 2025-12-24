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

func imageCompressing() throws {
    print("""
    XCAsset folder path
    Example: ~/Desktop/Assets.xcassets
    """)
    print("> ", terminator: .init())
    let path = (readLine()! as NSString).expandingTildeInPath as String
    print("")
    
    let contents = try FileManager.default.contentsOfDirectory(atPath: path)
    for content in contents where content.hasSuffix(".imageset") {
        let imageSetPath = path + "/\(content)"
        if FileManager.default.fileExists(atPath: imageSetPath + "/.compressed") {
            continue
        }
        guard let _imageName = (try? FileManager.default.contentsOfDirectory(atPath: imageSetPath))?
            .first(where: { $0.hasSuffix(".png") }) else {
            continue
        }
        let imagePath = imageSetPath + "/\(consume _imageName)"
        
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
        try? "CardCollectionGen".write(
            toFile: imageSetPath + "/.compressed",
            atomically: true,
            encoding: .utf8
        )
    }
}
