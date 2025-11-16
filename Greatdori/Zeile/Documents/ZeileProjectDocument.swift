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
    
    @Published var configuration: ZeileProjectConfig
    
    init(emptyWithName name: String) {
        let plistEncoder = PropertyListEncoder()
        plistEncoder.outputFormat = .xml
        
        let configuration = ZeileProjectConfig(
            codePhases: ["Main.zeile"]
        )
        self._configuration = .init(initialValue: configuration)
        let zieprojData = try! plistEncoder.encode(configuration)
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
        unsafe self._wrapper.preferredFilename = name
    }
    
    init(wrapper: FileWrapper) throws {
        guard wrapper.isDirectory else {
            throw CocoaError(.fileReadUnsupportedScheme)
        }
        
        unsafe self._wrapper = wrapper
        
        if let configWrapper = wrapper.fileWrappers?["project.zieproj"],
           let _data = configWrapper.regularFileContents,
           let config = try? PropertyListDecoder().decode(ZeileProjectConfig.self, from: _data) {
            self.configuration = config
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    convenience init(configuration: ReadConfiguration) throws {
        try self.init(wrapper: configuration.file)
    }
    
    var wrapper: FileWrapper {
        _wrapperLock.withLock { unsafe _wrapper }
    }
    
    func snapshot(contentType: UTType) throws -> FileWrapper {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        let newConfigData = try encoder.encode(self.configuration)
        return _wrapperLock.withLock {
            unsafe self._wrapper.updateFile(named: "project.zieproj", data: newConfigData)
            return unsafe self._wrapper
        }
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
            newWrapper.preferredFilename = "Code"
            self.wrapper.addFileWrapper(newWrapper)
            return newWrapper
        }
    }
    
    func codeFileWrapper(name: String) -> FileWrapper? {
        self.codeFolderWrapper.fileWrappers?[name]
    }
}

extension ZeileProjectDocument: Hashable {
    static func == (lhs: ZeileProjectDocument, rhs: ZeileProjectDocument) -> Bool {
        lhs._wrapperLock.withLock { unsafe lhs._wrapper }
        == rhs._wrapperLock.withLock { unsafe rhs._wrapper }
    }
    
    func hash(into hasher: inout Hasher) {
        _wrapperLock.withLock {
            hasher.combine(unsafe _wrapper)
        }
    }
}

extension FileWrapper {
    func updateFile(named name: String, data: Data) {
        if let file = self.fileWrappers?[name] {
            self.removeFileWrapper(file)
        }
        let file = FileWrapper(regularFileWithContents: data)
        file.preferredFilename = name
        self.addFileWrapper(file)
    }
    
    func renameFile(from oldName: String, to newName: String) {
        let oldWrapper = self.fileWrappers![oldName]!
        let newWrapper = FileWrapper(
            regularFileWithContents: oldWrapper.regularFileContents!
        )
        newWrapper.preferredFilename = newName
        self.removeFileWrapper(oldWrapper)
        self.addFileWrapper(newWrapper)
    }
}
