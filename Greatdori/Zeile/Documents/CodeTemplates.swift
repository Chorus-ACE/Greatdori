//===---*- Greatdori! -*---------------------------------------------------===//
//
// CodeTemplates.swift
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

public enum CodeTemplates {
    static var initialZeile: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        
        return """
        //
        // Main.zeile
        //
        // Created on \(formatter.string(from: .now))
        //
        
        let kasumi = Character.kasumi
        
        Background.change(to: "scenario0/bg00001.png")
        BGM.change(to: "04_nobiri/04_Nobiri.mp3")
        
        say(<#String#>, by: kasumi)
        
        """
    }
}
