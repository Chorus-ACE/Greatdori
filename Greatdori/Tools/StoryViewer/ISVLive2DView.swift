//===---*- Greatdori! -*---------------------------------------------------===//
//
// InteractiveStoryLive2DView.swift
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

@safe
struct ISVLive2DView: View {
    var modelPath: String
    var state: LayoutState?
//    var voicePlayer: UnsafeMutablePointer<AVAudioPlayer>
    var currentSpeckerID: Int
    @Environment(\._layoutViewVisible) private var isVisible
    @Environment(\._safeVoicePlayer) private var safeVoicePlayer
    @State private var motions = [Live2DMotion]()
    @State private var expressions = [Live2DExpression]()
    @State private var lipSyncValue = 0.0
    @State private var lipSyncTimer: Timer?
    var body: some View {
        Live2DView(resourceURL: URL(string: "https://bestdori.com/assets/\(modelPath)_rip/buildData.asset")!)
            .live2dPauseAnimations(!isVisible) // performance
            .live2dMotion(isVisible ? motions.first(where: { $0.name == state?.motion }) : nil)
            .live2dExpression(isVisible ? expressions.first(where: { $0.name == state?.expression }) : nil)
            .live2dLipSync(value: currentSpeckerID == state?.characterID ? lipSyncValue : nil)
            ._live2dZoomFactor(1.9)
            ._live2dCoordinateMatrix("""
            [ s, 0, 0, 0,
              0,-s, 0, 0,
              0, 0, 1, 0,
              -19/20, 6/5, 0, 1 ]
            """)
            .onLive2DMotionsUpdate { motions in
                self.motions = motions
            }
            .onLive2DExpressionsUpdate { expressions in
                self.expressions = expressions
            }
            .onChange(of: isVisible) {
                if isVisible {
                    lipSyncTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { _ in
                        DispatchQueue.main.async {
                            if _fastPath(safeVoicePlayer.wrappedValue != nil) {
                                safeVoicePlayer.wrappedValue!.updateMeters()
                                
                                // -160.0...0.0
                                let power = Double(safeVoicePlayer.wrappedValue!.peakPower(forChannel: 0))
                                lipSyncValue = pow(10, power / 20) - 0.3
                            }
                        }
                    }
                } else {
                    lipSyncTimer?.invalidate()
                }
            }
            .onDisappear {
                lipSyncTimer?.invalidate()
            }
    }
}

extension View {
    func safeVoicePlayer(_ safePlayer: Binding<AVAudioPlayer?>) -> some View {
        environment(\._safeVoicePlayer, safePlayer)
    }
}
extension EnvironmentValues {
    @Entry var _safeVoicePlayer: Binding<AVAudioPlayer?> = .constant(nil)
}
