//===---*- Greatdori! -*---------------------------------------------------===//
//
// AudioPlaying.swift
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
import AVFoundation

@MainActor var _globalAudioPlayer = AVPlayer()

func playAudio(url: URL) {
    Task {
        await MainActor.run {
            _globalAudioPlayer.replaceCurrentItem(with: .init(url: url))
            _globalAudioPlayer.seek(to: .init(seconds: 0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
            _globalAudioPlayer.play()
        }
    }
}
