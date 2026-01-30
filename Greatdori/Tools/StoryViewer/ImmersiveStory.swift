//===---*- Greatdori! -*---------------------------------------------------===//
//
// ImmersiveStory.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2026 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.com/LICENSE.txt for license information
// See https://greatdori.com/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

#if os(visionOS)

import ARKit
import DoriKit
import SwiftUI
import RealityKit

struct ImmersiveStoryPresentor: ViewModifier {
    @Binding var isPresented: Bool
    var storyIR: StoryIR?
    var locale: DoriLocale
    @Binding var isMuted: Bool
    @Binding var interactivePlayerIsInFullScreen: Bool
    @Binding var isvCurrentBlockingActionIndex: Int?
    @State private var currentTalk: TalkData?
    @State private var isAutoPlaying = false
    @State private var isLineAnimating: Binding<Bool> = .constant(false)
    @State private var talkShakeDuration: Binding<Double> = .constant(0)
    @State private var storyWindowFrame = Rect3D.zero
    func body(content: Content) -> some View {
        content
            .window(isPresented: $isPresented) {
                StoryWindowView(
                    storyIR: storyIR,
                    locale: locale,
                    isMuted: $isMuted,
                    interactivePlayerIsInFullScreen: $interactivePlayerIsInFullScreen,
                    isvCurrentBlockingActionIndex: $isvCurrentBlockingActionIndex,
                    currentTalk: $currentTalk,
                    isAutoPlaying: $isAutoPlaying,
                    isLineAnimating: $isLineAnimating,
                    talkShakeDuration: $talkShakeDuration,
                    storyWindowFrame: $storyWindowFrame
                )
            }
            .immersiveSpace(isPresented: $isPresented) {
                SpaceView(
                    locale: locale,
                    currentTalk: $currentTalk,
                    isAutoPlaying: $isAutoPlaying,
                    isLineAnimating: $isLineAnimating,
                    talkShakeDuration: $talkShakeDuration,
                    storyWindowFrame: $storyWindowFrame
                )
            }
    }
}

private struct StoryWindowView: View {
    var storyIR: StoryIR?
    var locale: DoriLocale
    @Binding var isMuted: Bool
    @Binding var interactivePlayerIsInFullScreen: Bool
    @Binding var isvCurrentBlockingActionIndex: Int?
    @Binding var currentTalk: TalkData?
    @Binding var isAutoPlaying: Bool
    @Binding var isLineAnimating: Binding<Bool>
    @Binding var talkShakeDuration: Binding<Double>
    @Binding var storyWindowFrame: Rect3D
    @Environment(SceneDelegate.self) private var sceneDelegate
    var body: some View {
        Group {
            if let storyIR {
                InteractiveStoryView(storyIR, locale: locale) { talk, autoPlaying, lineAnimating, shakeDuration in
                    currentTalk = talk
                    isAutoPlaying = autoPlaying
                    isLineAnimating = lineAnimating
                    talkShakeDuration = shakeDuration
                }
                .onGeometryChange3D(for: Rect3D.self) { proxy in
                    proxy.frame(in: .immersiveSpace)
                } action: { rect in
                    storyWindowFrame = rect
                }
                .onAppear {
                    guard let windowScene = sceneDelegate.windowScene else {
                        return
                    }
                    windowScene.requestGeometryUpdate(.Vision(resizingRestrictions: .uniform))
                }
            } else {
                ProgressView()
            }
        }
        .aspectRatio(16/10, contentMode: .fit)
        .frame(minWidth: 400)
        .isvIsMuted($isMuted)
        .isvIsInFullScreen($interactivePlayerIsInFullScreen)
        .isvCurrentBlockingActionIndex($isvCurrentBlockingActionIndex)
    }
}

private struct SpaceView: View {
    var locale: DoriLocale
    @Binding var currentTalk: TalkData?
    @Binding var isAutoPlaying: Bool
    @Binding var isLineAnimating: Binding<Bool>
    @Binding var talkShakeDuration: Binding<Double>
    @Binding var storyWindowFrame: Rect3D
    private let session = ARKitSession()
    private let worldTrackingProvider = WorldTrackingProvider()
    var body: some View {
        RealityView { content, attachments in
            try? await session.run([worldTrackingProvider])
        } update: { content, attachments in
            if let box = attachments.entity(for: "DialogBox") {
                content.entities.removeAll()
                let anchor = AnchorEntity(.head)
                anchor.anchoring.trackingMode = .continuous
                box.setParent(anchor)
                
                var windowPoint = content.convert(storyWindowFrame.center, from: .immersiveSpace, to: .scene)
                let deviceTransform: Transform
                if let deviceAnchor = worldTrackingProvider.queryDeviceAnchor(atTimestamp: CACurrentMediaTime()) {
                    deviceTransform = .init(matrix: deviceAnchor.originFromAnchorTransform)
                } else {
                    deviceTransform = .identity
                }
                windowPoint -= deviceTransform.translation
                let baseDistance = -(sqrt(pow(windowPoint.z, 2) + pow(windowPoint.x, 2) + pow(windowPoint.y, 2)))
                box.transform.translation.z = baseDistance + abs(baseDistance) * 0.15
                box.transform.translation.y = -0.15
                box.transform.rotation.vector.x = -0.1
                
                content.add(anchor)
            }
        } attachments: {
            if let currentTalk {
                Attachment(id: "DialogBox") {
                    ISVDialogBoxView(
                        data: currentTalk,
                        locale: locale,
                        isDelaying: false,
                        isAutoPlaying: isAutoPlaying,
                        usedInImmersive: true,
                        isAnimating: isLineAnimating,
                        shakeDuration: talkShakeDuration
                    )
                    .frame(width: 600)
                    .allowsHitTesting(false)
                }
            }
        }
    }
}

#endif // os(visionOS)
