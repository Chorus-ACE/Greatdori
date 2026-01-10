//===---*- Greatdori! -*---------------------------------------------------===//
//
// main.swift
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

import Darwin
import AppKit
import DoriKit
import Foundation

print("""
Localization Key for Collection Name
Example: BUILTIN_CARD_COLLECTION_MYGO
""")
print("> ", terminator: .init())
let collectionNameKey = readLine()!
print("")

print("""
Comma Separated Card ID with Training Status
[ID1]:[before|after], [ID2]:[before|after]...
Example: 2125:before, 1954:after
""")
print("> ", terminator: .init())
let formattedCardInfoString = readLine()!
print("")

print("""
Output Path
Default: ~/Desktop/CardCollections
""")
print("> ", terminator: .init())
let _outputPath = readLine() ?? ""
let outputPath = ((_outputPath.isEmpty ? "~/Desktop/CardCollections" : _outputPath) as NSString)
    .expandingTildeInPath as String
print("")

if !FileManager.default.fileExists(atPath: outputPath) {
    try FileManager.default.createDirectory(atPath: outputPath, withIntermediateDirectories: false)
}

print("Fetching...")

let ids = formattedCardInfoString
    .replacingOccurrences(of: " ", with: "")
    .components(separatedBy: ",")
    .compactMap {
        if let direct = Int($0) {
            // "2125"
            return (id: direct, trained: false)
        } else if $0.contains(":") {
            // "1954:after"
            let separated = $0.components(separatedBy: ":")
            guard separated.count == 2 else { return nil }
            guard let id = Int(separated[0]) else { return nil }
            return (id: id, trained: separated[1].lowercased() == "after")
        } else {
            return nil
        }
    }
print("Please wait...", terminator: .init())
fflush(stdout)
if let cards = await DoriAPI.Cards.all() {
    var relatedCards = cards.flatMap { card in
        ids.filter { $0.id == card.id }.map {
            (card: card, trained: $0.trained)
        }
    }
    for (index, card) in relatedCards.enumerated() {
        if index == 0 { continue }
        if relatedCards[0..<index].contains(where: { $0 == card }) {
            relatedCards.remove(at: index)
        }
    }
    
    printProgressBar(0, total: relatedCards.count)
    var resultCards = [Card]()
    var resultImageData = [(Data, String)]()
    for (index, (card, trained)) in relatedCards.enumerated() {
        let imageURL = trained ? (card.coverAfterTrainingImageURL ?? card.coverNormalImageURL) : card.coverNormalImageURL
        let data = try Data(contentsOf: imageURL)
        let fileName = "Card\(card.id)\(trained ? "After" : "Before")"
        resultImageData.append((data, fileName))
        resultCards.append(
            .init(
                localizedName: card.cardName,
                fileName: fileName
            )
        )
        printProgressBar(index + 1, total: relatedCards.count)
    }
    print("")
    for (data, fileName) in resultImageData {
        try! data.write(to: URL(filePath: outputPath + "/\(fileName).png"))
        if NSImage(data: data) == nil {
            print("warning: data integrity check failed: image data of card '\(fileName)' is invalid")
        }
    }
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let collection = Collection(name: collectionNameKey, cards: resultCards)
    let data = try encoder.encode(collection)
    try data.write(to: URL(filePath: outputPath + "/\(collectionNameKey).plist"))
    
    print("Compressing...")
    try compressImages(at: outputPath)
    print("Successfully generated card collection files at \(outputPath)")
} else {
    print("Failed to get cards from API")
}

func printProgressBar(_ progress: Int, total: Int) {
    func terminalWidth() -> Int {
        var w = winsize()
        if ioctl(STDOUT_FILENO, TIOCGWINSZ, &w) == 0 {
            return Int(w.ws_col)
        } else {
            return 80
        }
    }
    
    let width = terminalWidth()
    let reservedSpace = 8
    let barLength = max(10, width - reservedSpace)
    let progress = Double(progress) / Double(total)
    let percent = Int(progress * 100)
    let filledLength = Int(progress * Double(barLength))
    let bar = String(repeating: "█", count: filledLength) + String(repeating: "-", count: barLength - filledLength)
    print("\r[\(bar)] \(percent)%", terminator: "")
    fflush(stdout)
}

struct Collection: Codable {
    var name: String
    var cards: [Card]
}
struct Card: Codable {
    var localizedName: DoriAPI.LocalizedData<String>
    var fileName: String
}
