//===---*- Greatdori! -*---------------------------------------------------===//
//
// FileMerger.swift
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
import UniformTypeIdentifiers

struct FileMergerView: View {
    @State var fileImporterIsPresented = false
    @State var fileImporterIsFocusedOnPrimaryDict = true
    @State var fileExporterIsPresented = false
    @State var exportingFile: PropertyListFileDocument?
    @State var primaryDict: [Int: PlainLyrics] = [:]
    @State var secondaryDict: [Int: PlainLyrics] = [:]
    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Primary File")
                    Spacer()
                    if !primaryDict.isEmpty {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(.red)
                    }
                    Button(action: {
                        fileImporterIsFocusedOnPrimaryDict = true
                        fileImporterIsPresented = true
                    }, label: {
                        Text("Import...")
                    })
                }
                HStack {
                    Text("Secondary File")
                    Spacer()
                    if !secondaryDict.isEmpty {
                        Image(systemName: "checkmark.circle")
                            .foregroundStyle(.green)
                    } else {
                        Image(systemName: "xmark.circle")
                            .foregroundStyle(.red)
                    }
                    Button(action: {
                        fileImporterIsFocusedOnPrimaryDict = false
                        fileImporterIsPresented = true
                    }, label: {
                        Text("Import...")
                    })
                }
                HStack {
                    Button(action: {
                        var result: [Int: PlainLyrics] = primaryDict
                        for (key, secondaryValue) in secondaryDict {
                            if let primaryValue = result[key] {
                                var newSource = primaryValue.source.isEmpty ? secondaryValue.source : primaryValue.source
                                
                                var newLyrics = ""
                                if primaryValue.lyrics.count >= 50 && secondaryValue.lyrics.count >= 50 {
                                    newLyrics = primaryValue.lyrics
                                } else {
                                    newLyrics = primaryValue.lyrics.count >= secondaryValue.lyrics.count ? primaryValue.lyrics : secondaryValue.lyrics
                                }
                                result.updateValue(PlainLyrics(lyrics: newLyrics, source: newSource), forKey: key)
                            } else {
                                result.updateValue(secondaryValue, forKey: key)
                            }
                        }
                        
                        let encoder = PropertyListEncoder()
                        if let data = try? encoder.encode(result) {
                            exportingFile = .init(data)
                            fileExporterIsPresented = true
                        }
                    }, label: {
                        Text("Export...")
                    })
                    .disabled(primaryDict.isEmpty || secondaryDict.isEmpty)
                    Spacer()
                }
            }
        }
        .formStyle(.grouped)
        .fileImporter(
            isPresented: $fileImporterIsPresented,
            allowedContentTypes: [.propertyList]
        ) { result in
            if case .success(let url) = result {
                _ = url.startAccessingSecurityScopedResource()
                defer { url.stopAccessingSecurityScopedResource() }
                if let data = try? Data(contentsOf: url),
                   let decodedResults = try? PropertyListDecoder().decode([Int: PlainLyrics].self, from: data) {
                    if fileImporterIsFocusedOnPrimaryDict {
                        primaryDict = decodedResults
                    } else {
                        secondaryDict = decodedResults
                    }
                }
            }
        }
        .fileExporter(
            isPresented: $fileExporterIsPresented,
            document: exportingFile,
            contentType: .propertyList,
            defaultFilename: "MergedPlainLyrics.plist"
        ) { _ in
            exportingFile = nil
        }
    }
}
