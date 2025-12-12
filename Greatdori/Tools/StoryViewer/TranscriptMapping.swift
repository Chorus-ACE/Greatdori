//===---*- Greatdori! -*---------------------------------------------------===//
//
// TranscriptMapping.swift
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

// WindowsMEMZ refused to put this into DoriKit. Reasonable but regretful. --ThreeManager785

public struct NeoTranscript: Sendable, Hashable {
    public var isTelop: Bool = false
    public var text: String
    public var sourceIndex: Int?
    public var characterID: Int?
    public var characterName: String?
    public var voiceID: String?
    
    public var characterType: PersonGroupType {
        guard let characterName else { return .single }
        
        if characterName == "一同"
            || characterName == "全员"
            || characterName == "全員"
            || characterName == "All"
            || characterName.middleContains("・")
            || characterName.middleContains("と")
            || characterName.middleContains("&") {
            return .multiple
        } else if characterName == "???" || characterName == "？？？" {
            return .unknown
        }
        
        return .single
    }
    
    @inlinable
    public var characterIconImageURL: URL? {
        if let characterID, characterID > 0 {
            .init(string: "https://bestdori.com/res/icon/chara_icon_\(characterID).png")!
        } else {
            nil
        }
    }
    
    public enum PersonGroupType {
        case single
        case multiple
        case unknown
    }
    
    init(isTelop: Bool, text: String, sourceIndex: Int? = nil, characterID: Int? = nil, characterName: String? = nil, voiceID: String? = nil) {
        self.isTelop = isTelop
        self.text = text
        self.sourceIndex = sourceIndex
        self.characterID = characterID
        self.characterName = characterName
        self.voiceID = voiceID
    }
    
    init(_ standarizedTranscript: _DoriAPI.Misc.StoryAsset.Transcript) {
        switch standarizedTranscript {
        case .notation(let text):
            self.init(isTelop: true, text: text)
        case .talk(let talk):
            self.init(isTelop: false, text: talk.text, characterID: talk._characterID, characterName: talk.characterName, voiceID: talk.voiceID)
        @unknown default:
            fatalError()
        }
    }
    
    // No Enough Access Level
//    func standardlize() -> _DoriAPI.Misc.StoryAsset.Transcript {
//        if self.isTelop {
//            return .notation(self.text)
//        } else {
//            return .talk(_DoriAPI.Misc.StoryAsset.Transcript.Talk(_characterID: characterID ?? -1, characterName: characterName ?? "", text: text, voiceID: voiceID))
//        }
//    }
}

extension DoriStoryBuilder {
    public enum Conversion {
        public static func neoTranscript(fromIR ir: StoryIR) -> [NeoTranscript] {
            var result: [NeoTranscript] = []
            for index in 0..<ir.actions.count {
                switch ir.actions[index] {
                case .talk(let text, let characterIDs, let characterNames, let voicePath):
                    result.append(NeoTranscript(isTelop: false, text: text, sourceIndex: index, characterID: characterIDs.first, characterName: characterNames.first, voiceID: voicePath))
                case .telop(let text):
                    result.append(NeoTranscript(isTelop: true, text: text, sourceIndex: index))
                default:
                    break
                }
            }
            return result
        }
    }
}

extension String {
    fileprivate func middleContains(_ other: some StringProtocol) -> Bool {
        if _fastPath(self.count > 2) {
            self.dropFirst().dropLast().contains(other)
        } else {
            false
        }
    }
}
