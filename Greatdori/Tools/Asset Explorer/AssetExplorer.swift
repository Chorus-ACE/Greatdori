////===---*- Greatdori! -*---------------------------------------------------===//
////
//// AssetExplorer.swift
////
//// This source file is part of the Greatdori! open source project
////
//// Copyright (c) 2025 the Greatdori! project authors
//// Licensed under Apache License v2.0
////
//// See https://greatdori.com/LICENSE.txt for license information
//// See https://greatdori.com/CONTRIBUTORS.txt for the list of Greatdori! project authors
////
////===----------------------------------------------------------------------===//
//
import AVKit
import DoriKit
import SwiftUI
import Alamofire
import UniformTypeIdentifiers
@_spi(Advanced) import SwiftUIIntrospect

struct AssetItem: @unchecked Sendable, Hashable {
    var type: AssetType
    var name: String
    var view: AnyView
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.type == rhs.type && lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(name)
    }
    
    enum AssetType {
        case file
        case folder
        case rip
    }
}

extension AssetItem {
    init(type: AssetType, name: String, @ViewBuilder content: () -> some View) {
        self.init(type: type, name: name, view: AnyView(content()))
    }
}
extension Array<AssetItem> {
    init(_ info: _DoriAPI.Assets.AssetList, path: _DoriAPI.Assets.PathDescriptor) {
        func resolveInfo(_ info: _DoriAPI.Assets.AssetList, path: _DoriAPI.Assets.PathDescriptor) -> [AssetItem] {
            var result = [AssetItem]()
            let keys = info.keys.sorted()
            for key in keys {
                var newPath = path
                let value = info.access(key, updatingPath: &newPath)!
                switch value {
                case .files:
                    result.append(.init(type: .rip, name: key) {
                        AssetListView(currentPath: newPath)
                    })
                case .list(let list):
                    result.append(.init(type: .folder, name: key) {
                        AssetListView(items: resolveInfo(list, path: newPath), currentPath: newPath)
                    })
                }
            }
            return result
        }
        
        self = resolveInfo(info, path: path)
    }
}

struct AssetFileDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [] // readnone
    }
    static var writableContentTypes: [UTType] {
        [.content]
    }
    
    private let data: Data
    
    init(data: Data) {
        self.data = data
    }
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        .init(regularFileWithContents: data)
    }
}
