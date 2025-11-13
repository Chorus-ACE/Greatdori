//===---*- Greatdori! -*---------------------------------------------------===//
//
// ZeileProjectDocument.swift
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

import Combine
import SwiftUI
import UniformTypeIdentifiers

final class ZeileProjectDocument: ReferenceFileDocument {
    static var readableContentTypes: [UTType] {
        [.zeileProject]
    }
    
    let _wrapperLock = NSLock()
    nonisolated(unsafe) var _wrapper: FileWrapper
    
    init(emptyWithName name: String) {
        let plistEncoder = PropertyListEncoder()
        plistEncoder.outputFormat = .xml
        
        let zieprojData = try! plistEncoder.encode(ZeileProjectConfig(
            codePhases: ["Main.zeile"]
        ))
        let zieprojWrapper = FileWrapper(
            regularFileWithContents: zieprojData
        )
        
        let mainCodeWrapper = FileWrapper(
            regularFileWithContents: CodeTemplates.initialZeile.data(using: .utf8)!
        )
        
        unsafe self._wrapper = .init(directoryWithFileWrappers: [
            "project.zieproj": zieprojWrapper,
            "Assets": .init(directoryWithFileWrappers: [:]),
            "Code": .init(directoryWithFileWrappers: [
                "Main.zeile": mainCodeWrapper
            ])
        ])
        unsafe self._wrapper.filename = name
    }
    
    init(configuration: ReadConfiguration) throws {
        unsafe self._wrapper = configuration.file
    }
    
    func snapshot(contentType: UTType) throws -> FileWrapper {
        return _wrapperLock.withLock { unsafe self._wrapper }
    }
    
    func fileWrapper(
        snapshot: Snapshot,
        configuration: WriteConfiguration
    ) throws -> FileWrapper {
        return snapshot
    }
}
