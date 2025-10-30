//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongDifficultyIndicators.swift
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
import SDWebImageSwiftUI
import SwiftUI


// MARK: SongDifficultiesIndicator
struct SongDifficultiesIndicator: View {
    var information: [_DoriAPI.Songs.DifficultyType: Int]
    var allAvailableDifficulties: [_DoriAPI.Songs.DifficultyType]
    
    init(_ difficulty: [_DoriAPI.Songs.DifficultyType : _DoriAPI.Songs.Song.Difficulty]) {
        self.information = difficulty.mapValues{ $0.playLevel }
        
        var allAvailableDifficultiesTemp: [_DoriAPI.Songs.DifficultyType] = []
        for difficulty in _DoriAPI.Songs.DifficultyType.allCases {
            if information[difficulty] != nil {
                allAvailableDifficultiesTemp.append(difficulty)
            }
        }
        self.allAvailableDifficulties = allAvailableDifficultiesTemp
    }
    
    init(_ difficulty: [_DoriAPI.Songs.DifficultyType : _DoriAPI.Songs.PreviewSong.Difficulty]) {
        self.information = difficulty.mapValues{ $0.playLevel }
        
        var allAvailableDifficultiesTemp: [_DoriAPI.Songs.DifficultyType] = []
        for difficulty in _DoriAPI.Songs.DifficultyType.allCases {
            if information[difficulty] != nil {
                allAvailableDifficultiesTemp.append(difficulty)
            }
        }
        self.allAvailableDifficulties = allAvailableDifficultiesTemp
    }
    
    init (_ difficulty: [_DoriAPI.Songs.DifficultyType : Int]) {
        self.information = difficulty
        
        var allAvailableDifficultiesTemp: [_DoriAPI.Songs.DifficultyType] = []
        for difficulty in _DoriAPI.Songs.DifficultyType.allCases {
            if information[difficulty] != nil {
                allAvailableDifficultiesTemp.append(difficulty)
            }
        }
        self.allAvailableDifficulties = allAvailableDifficultiesTemp
    }
    
    var body: some View {
        HStack {
            if !allAvailableDifficulties.isEmpty {
                ForEach(allAvailableDifficulties, id: \.self) { item in
                    SongDifficultyIndicator(difficulty: item, level: information[item]!)
                }
            }
        }
    }
}


// MARK: SongDifficultyIndicator
struct SongDifficultyIndicator: View {
    @Environment(\.colorScheme) var colorScheme
    var difficulty: _DoriAPI.Songs.DifficultyType
    var level: Int
    let diameter: CGFloat = imageButtonSize*0.75
    
    var body: some View {
        Circle()
            .foregroundStyle(colorScheme == .dark ? difficulty.darkColor : difficulty.color)
            .frame(width: diameter, height: diameter)
            .overlay {
                Text("\(level)")
                    .fontWeight(.semibold)
            }
            .frame(width: diameter, height: diameter)
    }
}
