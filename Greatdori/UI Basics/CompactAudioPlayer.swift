//===---*- Greatdori! -*---------------------------------------------------===//
//
// CompactAudioPlayer.swift
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

import AVKit
import DoriKit
import SwiftUI

struct CompactAudioPlayer: View {
    var url: URL
    @State private var player: AVPlayer
    
    init(url: URL) {
        self.url = url
        self._player = .init(initialValue: .init(url: url))
    }
    
    @State private var isPlaying = false
    @State private var currentTime = 0.0
    @State private var duration = 0.0
    @State private var timeUpdateTimer: Timer?
    @State private var isTimeEditing = false
    
    var body: some View {
        CustomGroupBox(cornerRadius: 114514) {
            HStack {
                Button(action: {
                    if isPlaying {
                        player.pause()
                    } else {
                        if duration - currentTime < 0.1 {
                            player.seek(to: .init(seconds: 0, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                        }
                        player.play()
                    }
                }, label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                })
                Text(verbatim: "\(formatTime(currentTime)) / \(formatTime(duration))")
                Slider(value: $currentTime, in: 0...duration) { isEditing in
                    if !isEditing {
                        player.seek(to: .init(seconds: currentTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                    }
                    isTimeEditing = isEditing
                }
            }
        }
        .onAppear {
            timeUpdateTimer = .scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                DispatchQueue.main.async {
                    if !isTimeEditing {
                        currentTime = player.currentTime().seconds
                    }
                }
            }
        }
        .onDisappear {
            timeUpdateTimer?.invalidate()
        }
        .onReceive(player.publisher(for: \.timeControlStatus)) { status in
            isPlaying = status == .playing
        }
        .onReceive(player.publisher(for: \.currentItem?.duration)) { duration in
            if let duration, duration.seconds.isFinite {
                self.duration = duration.seconds
            }
        }
    }
    
    private func formatTime(_ time: Double) -> String {
        var minutes = String(Int(time) / 60)
        var seconds = String(Int(time.truncatingRemainder(dividingBy: 60)))
        if minutes.count == 1 {
            minutes = "0" + minutes
        }
        if seconds.count == 1 {
            seconds = "0" + seconds
        }
        return "\(minutes):\(seconds)"
    }
}
