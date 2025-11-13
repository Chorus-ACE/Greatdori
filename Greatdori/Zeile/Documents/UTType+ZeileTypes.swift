//===---*- Greatdori! -*---------------------------------------------------===//
//
// UTType+ZeileTypes.swift
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

import Foundation
import UniformTypeIdentifiers

extension UTType {
    static var zeileSource: UTType {
        .init("com.memz233.Greatdori.type.zeile")!
    }
    
    static var zeileProject: UTType {
        .init("com.memz233.Greatdori.type.zeile-project")!
    }
    
    static var zeileIR: UTType {
        .init("com.memz233.Greatdori.type.zeile-ir")!
    }
    
    static var storyArchive: UTType {
        .init("com.memz233.Greatdori.type.story-archive")!
    }
    
    static var zeileProjectData: UTType {
        .init("com.memz233.Greatdori.type.zeile-project.data")!
    }
}
