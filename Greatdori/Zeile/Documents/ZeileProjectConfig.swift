//===---*- Greatdori! -*---------------------------------------------------===//
//
// ZeileProjectConfig.swift
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
import Foundation

struct ZeileProjectConfig: Hashable {
    var version: Int = 1
    
    var metadata: ProjectMetadata = .init()
    var codePhases: [String] = []
    
    struct ProjectMetadata: Hashable {
        var locale: DoriLocale = .jp
        var projectName: String = ""
        var author: String = ""
        var description: String = ""
    }
}

extension ZeileProjectConfig: Codable {
    enum CodingKeys: CodingKey {
        case version
        case metadata
        case codePhases
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.version = try container.decode(Int.self, forKey: .version)
        self.metadata = try container.decode(ProjectMetadata.self, forKey: .metadata)
        self.codePhases = try container.decode([String].self, forKey: .codePhases)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.version, forKey: .version)
        try container.encode(self.metadata, forKey: .metadata)
        try container.encode(self.codePhases, forKey: .codePhases)
    }
}

extension ZeileProjectConfig.ProjectMetadata: Codable {
    enum CodingKeys: CodingKey {
        case locale
        case projectName
        case author
        case description
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.locale = try container.decode(DoriLocale.self, forKey: .locale)
        self.projectName = try container.decode(String.self, forKey: .projectName)
        self.author = try container.decode(String.self, forKey: .author)
        self.description = try container.decode(String.self, forKey: .description)
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.locale, forKey: .locale)
        try container.encode(self.projectName, forKey: .projectName)
        try container.encode(self.author, forKey: .author)
        try container.encode(self.description, forKey: .description)
    }
}
