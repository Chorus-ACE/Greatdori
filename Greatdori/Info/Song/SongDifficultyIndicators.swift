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
    var information: [DoriAPI.Songs.DifficultyType: Int]
    var allAvailableDifficulties: [DoriAPI.Songs.DifficultyType]
    
    init(_ difficulty: [DoriAPI.Songs.DifficultyType : DoriAPI.Songs.Song.Difficulty]) {
        self.information = difficulty.mapValues{ $0.playLevel }
        
        var allAvailableDifficultiesTemp: [DoriAPI.Songs.DifficultyType] = []
        for difficulty in DoriAPI.Songs.DifficultyType.allCases {
            if information[difficulty] != nil {
                allAvailableDifficultiesTemp.append(difficulty)
            }
        }
        self.allAvailableDifficulties = allAvailableDifficultiesTemp
    }
    
    init(_ difficulty: [DoriAPI.Songs.DifficultyType : DoriAPI.Songs.PreviewSong.Difficulty]) {
        self.information = difficulty.mapValues{ $0.playLevel }
        
        var allAvailableDifficultiesTemp: [DoriAPI.Songs.DifficultyType] = []
        for difficulty in DoriAPI.Songs.DifficultyType.allCases {
            if information[difficulty] != nil {
                allAvailableDifficultiesTemp.append(difficulty)
            }
        }
        self.allAvailableDifficulties = allAvailableDifficultiesTemp
    }
    
    init (_ difficulty: [DoriAPI.Songs.DifficultyType : Int]) {
        self.information = difficulty
        
        var allAvailableDifficultiesTemp: [DoriAPI.Songs.DifficultyType] = []
        for difficulty in DoriAPI.Songs.DifficultyType.allCases {
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
    var difficulty: DoriAPI.Songs.DifficultyType
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
