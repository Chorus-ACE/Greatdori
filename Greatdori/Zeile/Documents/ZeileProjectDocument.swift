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

final class ZeileProjectDocument: ReferenceFileDocument, @unchecked Sendable {
    static var readableContentTypes: [UTType] {
        [.zeileProject]
    }
    
    let _wrapperLock = NSLock()
    nonisolated(unsafe) var _wrapper: FileWrapper
    
    var configuration: ZeileProjectConfig
    
    init(emptyWithName name: String) {
        let plistEncoder = PropertyListEncoder()
        plistEncoder.outputFormat = .xml
        
        self.configuration = .init(
            codePhases: ["Main.zeile"]
        )
        let zieprojData = try! plistEncoder.encode(self.configuration)
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
        guard configuration.file.isDirectory else {
            throw CocoaError(.fileReadUnsupportedScheme)
        }
        
        unsafe self._wrapper = configuration.file
        
        if let configWrapper = configuration.file.fileWrappers?["project.zieproj"],
           let _data = configWrapper.regularFileContents,
           let config = try? PropertyListDecoder().decode(ZeileProjectConfig.self, from: _data) {
            self.configuration = config
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    var wrapper: FileWrapper {
        _wrapperLock.withLock { unsafe _wrapper }
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

extension ZeileProjectDocument {
    var codeFolderWrapper: FileWrapper {
        if let wrapper = self.wrapper.fileWrappers!["Code"] {
            _onFastPath()
            return wrapper
        } else {
            let newWrapper = FileWrapper(directoryWithFileWrappers: [:])
            newWrapper.filename = "Code"
            self.wrapper.addFileWrapper(newWrapper)
            return newWrapper
        }
    }
    
    func codeFileWrapper(name: String) -> FileWrapper? {
        self.codeFolderWrapper.fileWrappers?[name]
    }
}
