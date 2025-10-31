//===---*- Greatdori! -*---------------------------------------------------===//
//
// InteractiveStoryView.swift
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
import Combine
import DoriKit
import SwiftUI
import MetalKit
import Alamofire
import SDWebImageSwiftUI
@_spi(Advanced) import SwiftUIIntrospect

@safe
struct InteractiveStoryView: View {
    var asset: _DoriAPI.Misc.StoryAsset
    var voiceBundleURL: URL
    var locale: DoriLocale
    @Environment(\.dismiss) var dismiss
    
    @State var backgroundImageURL: URL?
    @State var scenarioImageURL: URL?
    
    @State var isScenarioImageFilter = false
    
    @State var bgmPlayer = AVQueuePlayer()
    @State var bgmLooper: AVPlayerLooper!
    @State var sePlayer = AVPlayer()
    var voicePlayer: UnsafeMutablePointer<AVAudioPlayer>
    @State var currentSnippetIndex = -1
    @State var currentTelop: String?
    
    @State var allDiffLayouts = [_DoriAPI.Misc.StoryAsset.LayoutData]()
    @State var showingLayoutIndexs = [Int]()
    @State var currentTalk: _DoriAPI.Misc.StoryAsset.TalkData?
    @State var talkAudios = [_DoriAPI.Misc.StoryAsset.TalkData.Voice: Data]()
    
    @State var isDelaying = false
    @State var whiteCoverIsDisplaying = false
    @State var blackCoverIsShowing = false
    
    @State var lineIsAnimating = false
    @State var uiIsHiding = false
    @State var backlogIsPresenting = false
    @State var isAutoPlaying = false
    
    @State var autoPlayTimer: Timer?
    @State var fastForwardTimer: Timer?
    @State var talkShakeDuration = 0.0
    @State var screenShakeDuration = 0.0
    
    init(asset: _DoriAPI.Misc.StoryAsset, voiceBundleURL: URL, locale: DoriLocale) {
        self.asset = asset
        self.voiceBundleURL = voiceBundleURL
        self.locale = locale
        unsafe voicePlayer = .allocate(capacity: 1)
        unsafe voicePlayer.initialize(to: .init())
        
        #if os(iOS)
        setDeviceOrientation(to: .landscapeLeft, allowing: .landscape)
        #endif
    }
    
    var body: some View {
        ZStack {
            // Characters
            GeometryReader { geometry in
                ZStack {
                    ForEach(Array(allDiffLayouts.enumerated()), id: \.element.costumeType) { index, layout in
                        HStack {
                            Spacer(minLength: 0)
                            VStack {
                                Spacer(minLength: 0)
                                unsafe InteractiveStoryLive2DView(data: layout, voicePlayer: voicePlayer, currentSpeckerID: currentTalk?.talkCharacters.first?.characterID ?? -1)
                                    .frame(width: geometry.size.height, height: geometry.size.height)
                                    .offset(x: {
                                        switch layout.sideTo {
                                        case .none: 0
                                        case .left: -(geometry.size.width / 4)
                                        case .leftOver: -(geometry.size.width / 3)
                                        case .leftInside: -(geometry.size.width / 6)
                                        case .center: 0
                                        case .right: geometry.size.width / 4
                                        case .rightOver: geometry.size.width / 3
                                        case .rightInside: geometry.size.width / 6
                                        case .leftUnder: -(geometry.size.width / 4)
                                        case .leftInsideUnder: -(geometry.size.width / 6)
                                        case .centerUnder: 0
                                        case .rightUnder: geometry.size.width / 4
                                        case .rightInsideUnder: geometry.size.width / 6
                                        @unknown default: 0
                                        }
                                    }(), y: {
                                        switch layout.sideTo {
                                        case .leftUnder,
                                                .leftInsideUnder,
                                                .centerUnder,
                                                .rightUnder,
                                                .rightInsideUnder: geometry.size.height / 6
                                        default: 0
                                        }
                                    }())
                                    .opacity(showingLayoutIndexs.contains(index) ? 1 : 0)
                                    .environment(\._layoutViewVisible, showingLayoutIndexs.contains(index))
                                    .animation(.spring(duration: 0.4, bounce: 0.2), value: layout)
                                    .animation(.spring(duration: 0.4, bounce: 0.25), value: showingLayoutIndexs)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
            }
            #if os(iOS)
            .ignoresSafeArea()
            #endif
            
            // Dialog Box
            if let currentTalk, !uiIsHiding {
                VStack {
                    Spacer()
                    InteractiveStoryDialogBoxView(
                        data: currentTalk,
                        locale: locale,
                        isDelaying: isDelaying,
                        isAutoPlaying: isAutoPlaying,
                        isAnimating: $lineIsAnimating,
                        shakeDuration: $talkShakeDuration
                    )
                    .padding(isMACOS ? .all : .horizontal)
                }
            }
            
            // Telop
            if let currentTelop {
                ZStack {
                    Capsule()
                        .fill(Color.red.opacity(0.7))
                        .rotationEffect(.degrees(-0.5))
                        .frame(width: 400, height: 35)
                    Capsule()
                        .fill(Color.white)
                        .rotationEffect(.degrees(0.5))
                        .frame(width: 380, height: 32)
                    Text(currentTelop)
                        .font(.custom(fontName(in: locale), size: 18))
                        .foregroundStyle(Color(red: 80 / 255, green: 80 / 255, blue: 80 / 255))
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
            }
            
//            #if os(iOS)
            if !uiIsHiding {
                HStack {
                    Spacer()
                    VStack {
                        // FIXME: [251031] Glass Style Where?
                        if #available(iOS 26.0, macOS 26.0, *) {
                            actionMenu
                                .buttonStyle(.glass)
                        } else {
//                            actionMenu
//                                .buttonStyle(.bordered)
//                                .buttonBorderShape(.circle)
                        }
                        Spacer()
                    }
//                    .border(.blue)
                }
                .padding()
            }
//            #endif
            
            // Black & White Covers
            Group {
                Rectangle()
                    .fill(Color.white)
                    .opacity(whiteCoverIsDisplaying ? 1 : 0)
                    .ignoresSafeArea(edges: isMACOS ? .vertical : .all)
                Rectangle()
                    .fill(Color.black)
                    .opacity(blackCoverIsShowing ? 1 : 0)
                    .ignoresSafeArea(edges: isMACOS ? .vertical : .all)
            }
        }
        .background {
            WebImage(url: backgroundImageURL)
                .resizable()
                .aspectRatio(4 / 3, contentMode: .fill)
                .clipped()
                .ignoresSafeArea(edges: isMACOS ? .vertical : .all)
            if let scenarioImageURL {
                WebImage(url: scenarioImageURL)
                    .resizable()
                    .aspectRatio(4 / 3, contentMode: .fill)
                    .clipped()
                    .opacity(isScenarioImageFilter ? 0.5 : 1)
                    .ignoresSafeArea(edges: isMACOS ? .vertical : .all)
            }
        }
        .modifier(ShakeScreenModifier(shakeDuration: $screenShakeDuration))
//        #if os(macOS)
//        .toolbar {
//            ToolbarItem {
//                actionMenu
//            }
//        }
//        #else
//        .toolbar(.hidden, for: .navigationBar)
//        .toolbar(.hidden, for: .tabBar)
//        .navigationBarBackButtonHidden()
//        #endif
        .onTapGesture {
            if uiIsHiding {
                uiIsHiding = false
                return
            }
            if isAutoPlaying {
                autoPlayTimer?.invalidate()
                isAutoPlaying = false
                return
            }
            if lineIsAnimating {
                lineIsAnimating = false
                return
            }
            next()
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress(keys: [.return, .space], phases: [.down]) { _ in
            if uiIsHiding {
                uiIsHiding = false
                return .handled
            }
            if isAutoPlaying {
                autoPlayTimer?.invalidate()
                isAutoPlaying = false
                return .handled
            }
            if lineIsAnimating {
                lineIsAnimating = false
                return .handled
            }
            next()
            return .handled
        }
        .sheet(isPresented: $backlogIsPresenting) {
            if let talk = currentTalk {
                NavigationStack {
                    BacklogView(asset: asset, currentTalk: talk, locale: locale, audios: talkAudios)
                    #if os(macOS)
                        .frame(width: 500, height: 350)
                    #endif
                }
            }
        }
        .onAppear {
            if backgroundImageURL != nil {
                return
            }
            
            backgroundImageURL = .init(string: "https://bestdori.com/assets/jp/\(asset.firstBackgroundBundleName)_rip/\(asset.firstBackground).png")!
            let bgmItem = AVPlayerItem(url: .init(string: "https://bestdori.com/assets/jp/sound/scenario/bgm/\(asset.firstBGM.lowercased())_rip/\(asset.firstBGM).mp3")!)
            bgmLooper = .init(player: bgmPlayer, templateItem: bgmItem)
            bgmPlayer.play()
            
            for layout in asset.layoutData {
                if !layout.costumeType.isEmpty && !allDiffLayouts.contains(where: {
                    $0.characterID == layout.characterID
                    && $0.costumeType == layout.costumeType
                }) {
                    allDiffLayouts.append(layout)
                }
            }
            
            for talk in asset.talkData {
                for voice in talk.voices {
                    AF.request("\(voiceBundleURL.absoluteString)_rip/\(voice.voiceID).mp3").response { response in
                        if let data = response.data {
                            DispatchQueue.main.async {
                                talkAudios.updateValue(data, forKey: voice)
                            }
                        }
                    }
                }
            }
            
            next()
        }
        .onDisappear {
            exitViewer(dismiss: false)
        }
        .introspect(.window) { window in
            // 初始状态下设置
            updateTitleBar(for: window)
            
            // 添加全屏监听
            NotificationCenter.default.addObserver(
                forName: NSWindow.didEnterFullScreenNotification,
                object: window,
                queue: .main
            ) { _ in
                updateTitleBar(for: window)
            }
            
            NotificationCenter.default.addObserver(
                forName: NSWindow.willExitFullScreenNotification,
                object: window,
                queue: .main
            ) { _ in
                updateTitleBar(for: window)
            }
        }
    }
    
    @ViewBuilder
    var actionMenu: some View {
        Menu {
            Section {
                Button(isAutoPlaying ? "取消自动" : "自动", systemImage: isAutoPlaying ? "play.slash" : "play") {
                    isAutoPlaying.toggle()
                    if isAutoPlaying {
                        next()
                    } else {
                        autoPlayTimer?.invalidate()
                    }
                }
                Button("全屏自动播放", systemImage: "pano.badge.play") {
                    isAutoPlaying = true
                    uiIsHiding = true
                    next()
                }
                .disabled(talkAudios.isEmpty)
                Button(action: {
                    if fastForwardTimer != nil {
                        fastForwardTimer?.invalidate()
                        fastForwardTimer = nil
                        return
                    }
                    fastForwardTimer = .scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                        DispatchQueue.main.async {
                            next(ignoresDelay: true)
                        }
                    }
                }, label: {
                    if fastForwardTimer == nil {
                        Label("快进", systemImage: "forward")
                    } else {
                        Label("取消快进", image: "custom.forward.slash")
                    }
                })
                Button("记录", systemImage: "text.document") {
                    backlogIsPresenting = true
                }
                .disabled(currentTalk == nil)
                Button("不显示", systemImage: "xmark") {
                    uiIsHiding = true
                }
                Button("退出", systemImage: "escape", role: .destructive) {
                    exitViewer()
                }
                .foregroundStyle(.red)
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.title)
            #if os(iOS)
                .font(.system(size: 20))
                .padding(12)
            #endif
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
    }
    
    func next(ignoresDelay: Bool = false) {
        func withDelay(_ closure: @escaping () async -> Void, onFinish finish: @escaping () -> Void = {}) {
            Task(priority: .userInitiated) {
                isDelaying = true
                await closure()
                isDelaying = false
                finish()
            }
        }
        
        guard !isDelaying || ignoresDelay else { return }
        
        currentSnippetIndex += 1
        
        if currentSnippetIndex == asset.snippets.endIndex {
            return
        }
        if currentSnippetIndex > asset.snippets.endIndex {
            exitViewer()
            return
        }
        
        let snippet = asset.snippets[currentSnippetIndex]
        
        if currentTelop != nil {
            if snippet.actionType == .effect,
               asset.specialEffectData[snippet.referenceIndex].effectType == .telop {
                isDelaying = true
                currentSnippetIndex -= 1
                withAnimation {
                    currentTelop = nil
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    isDelaying = false
                    next()
                }
                return
            } else {
                withAnimation {
                    currentTelop = nil
                }
            }
        }
        
        switch snippet.actionType {
        case .none:
            withDelay {
                try? await Task.sleep(for: .seconds(snippet.delay))
            } onFinish: {
                next()
            }
        case .talk:
            let talkData = asset.talkData[snippet.referenceIndex]
            currentTalk = talkData
            if let voice = talkData.voices.first,
               let data = talkAudios[voice],
               let newPlayer = try? AVAudioPlayer(data: data) {
                newPlayer.isMeteringEnabled = true
                unsafe voicePlayer.pointee = newPlayer
                unsafe voicePlayer.pointee.play()
                if isAutoPlaying {
                    autoPlayTimer = .scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                        if unsafe !voicePlayer.pointee.isPlaying {
                            timer.invalidate()
                            autoPlayTimer = .scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                                DispatchQueue.main.async {
                                    next()
                                }
                            }
                        }
                    }
                }
            } else if isAutoPlaying {
                autoPlayTimer = .scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                    DispatchQueue.main.async {
                        next()
                    }
                }
            }
            for motion in talkData.motions {
                if let index = showingLayoutIndexs.first(where: { allDiffLayouts[$0].characterID == motion.characterID }) {
                    allDiffLayouts[index].motionName = motion.motionName
                    allDiffLayouts[index].expressionName = motion.expressionName
                } else {
                    print("Talk requires motion change to character \(motion.characterID), but she's not visible?!")
                }
            }
            if currentSnippetIndex + 1 < asset.snippets.endIndex
                && (asset.snippets[currentSnippetIndex + 1].actionType == .motion
                    || (asset.snippets[currentSnippetIndex + 1].actionType == .effect
                        && (asset.specialEffectData[asset.snippets[currentSnippetIndex + 1].referenceIndex].effectType == .shakeScreen
                            || asset.specialEffectData[asset.snippets[currentSnippetIndex + 1].referenceIndex].effectType == .shakeWindow))) {
                next()
            }
        case .layout, .motion:
            let layoutData = asset.layoutData[snippet.referenceIndex]
            withDelay {
                if snippet.delay > 0 {
                    if currentSnippetIndex + 1 < asset.snippets.endIndex {
                        // Motions can appear continuously
                        // and share the same start time for delay.
                        // We find the motion snippets immediately after this
                        // (if present) and perform them
                        let s = asset.snippets[currentSnippetIndex + 1]
                        if s.actionType == .motion && s.delay > 0 {
                            // If the snippet after the next is still a motion,
                            // the same code here in this call handles it
                            next(ignoresDelay: true)
                        }
                        // Effects are like this, too
                        if s.actionType == .effect && s.delay > 0 {
                            next(ignoresDelay: true)
                        }
                    }
                    try? await Task.sleep(for: .seconds(snippet.delay))
                }
                switch layoutData.type {
                case .none, .move, .appear:
                    var newData = layoutData
                    // Find before for each empty data
                    let dataBefore = asset.layoutData[asset.layoutData.startIndex...snippet.referenceIndex]
                        .filter { $0.characterID == layoutData.characterID }
                        .reversed()
                    if newData.costumeType.isEmpty {
                        for data in dataBefore where !data.costumeType.isEmpty {
                            newData.costumeType = data.costumeType
                            break
                        }
                    }
                    if newData.motionName.isEmpty {
                        for data in dataBefore where !data.motionName.isEmpty {
                            newData.motionName = data.motionName
                            break
                        }
                    }
                    if newData.expressionName.isEmpty {
                        for data in dataBefore where !data.expressionName.isEmpty {
                            newData.expressionName = data.expressionName
                            break
                        }
                    }
                    if let index = allDiffLayouts.firstIndex(where: { $0.costumeType == newData.costumeType }) {
                        if layoutData.type == .none {
                            newData.sideFrom = allDiffLayouts[index].sideFrom
                            newData.sideTo = allDiffLayouts[index].sideTo
                            newData.sideFromOffsetX = allDiffLayouts[index].sideFromOffsetX
                            newData.sideToOffsetX = allDiffLayouts[index].sideToOffsetX
                        }
                        allDiffLayouts[index] = newData
                        if !showingLayoutIndexs.contains(index) {
                            if layoutData.type == .appear {
                                showingLayoutIndexs.append(index)
                            } else {
                                print("Scheduled a layout change, but it's not even visible?!")
                            }
                        }
                    } else {
                        print("A combined layout '\(newData)' doesn't match any layout in full list '\(allDiffLayouts)'?!")
                    }
                case .hide:
                    showingLayoutIndexs.removeAll {
                        allDiffLayouts[$0].characterID == layoutData.characterID
                    }
                case .shakeX:
                    print("Not Implemented Layout: shakeY")
                case .shakeY:
                    print("Not Implemented Layout: shakeY")
                @unknown default: break
                }
            } onFinish: {
                if snippet.actionType == .layout {
                    next()
                }
            }
        case .input:
            print("Not Implemented Action: input")
        case .selectable:
            print("Not Implemented Action: selectable")
        case .effect:
            let effect = asset.specialEffectData[snippet.referenceIndex]
            switch effect.effectType {
            case .none:
                break
            case .blackIn:
                withAnimation(.linear(duration: effect.duration)) {
                    blackCoverIsShowing = false
                }
                next()
            case .blackOut:
                withAnimation(.linear(duration: effect.duration)) {
                    blackCoverIsShowing = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + effect.duration) {
                    whiteCoverIsDisplaying = false
                }
                next()
            case .whiteIn:
                withAnimation(.linear(duration: effect.duration)) {
                    whiteCoverIsDisplaying = false
                }
                next()
            case .whiteOut:
                withAnimation(.linear(duration: effect.duration)) {
                    whiteCoverIsDisplaying = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + effect.duration) {
                    blackCoverIsShowing = false
                }
                next()
            case .shakeScreen:
                withDelay {
                    try? await Task.sleep(for: .seconds(snippet.delay))
                    screenShakeDuration = effect.duration
                }
            case .shakeWindow:
                withDelay {
                    try? await Task.sleep(for: .seconds(snippet.delay))
                    talkShakeDuration = effect.duration
                }
            case .changeBackground, .changeBackgroundStill, .changeCardStill:
                withAnimation {
                    backgroundImageURL = .init(string: "https://bestdori.com/assets/jp/\(effect.stringVal)_rip/\(effect.stringValSub).png")!
                }
                next()
            case .telop:
                withAnimation {
                    currentTalk = nil
                    currentTelop = effect.stringVal
                }
                if isAutoPlaying {
                    autoPlayTimer = .scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                        DispatchQueue.main.async {
                            next()
                        }
                    }
                }
            case .flashbackIn:
                print("Not Implemented Effect: flashbackIn")
                next()
            case .flashbackOut:
                print("Not Implemented Effect: flashbackOut")
                next()
            case .ambientColorNormal:
                // FIXME: What does this action change?
                next()
            case .ambientColorEvening:
                // FIXME: What does this action change?
                next()
            case .ambientColorNight:
                // FIXME: What does this action change?
                next()
            case .playScenarioEffect:
                let lastStringVal = effect.stringValSub.components(separatedBy: "/").last
                isScenarioImageFilter = lastStringVal?.hasPrefix("filter") ?? false || lastStringVal?.hasPrefix("fillter") ?? false
                // Actually I only found `scenario/effects/fillter_damage` needs extra opacity,    |    expected ~~~^~~~
                // they even typed an extra "l" in the name
                withAnimation {
                    scenarioImageURL = .init(string: "https://bestdori.com/assets/jp/\(effect.stringValSub)_rip/bg.png")!
                }
                next()
            case .stopScenarioEffect:
                withAnimation {
                    scenarioImageURL = nil
                }
                next()
            @unknown default: break
            }
        case .sound:
            let soundData = asset.soundData[snippet.referenceIndex]
            if !soundData.bgm.isEmpty {
                bgmPlayer.pause()
                bgmPlayer.removeAllItems()
                let bgmItem = AVPlayerItem(url: .init(string: "https://bestdori.com/assets/jp/sound/scenario/bgm/\(soundData.bgm.lowercased())_rip/\(soundData.bgm).mp3")!)
                bgmLooper = .init(player: bgmPlayer, templateItem: bgmItem)
                bgmPlayer.play()
            } else if !soundData.se.isEmpty {
                sePlayer.replaceCurrentItem(with: .init(url: .init(string: "https://bestdori.com/assets/jp/sound/se/\(soundData.seBundleName)_rip/\(soundData.se).mp3")!))
                sePlayer.play()
            }
            next()
        @unknown default: break
        }
    }
    
    func exitViewer(dismiss doDismiss: Bool = true) {
        // clean up
        autoPlayTimer?.invalidate()
        fastForwardTimer?.invalidate()
        bgmPlayer.pause()
        sePlayer.pause()
        unsafe voicePlayer.pointee.stop()
        
        if doDismiss {
            dismiss()
        }
        
        #if os(iOS)
        setDeviceOrientation(to: .portrait, allowing: .portrait)
        #endif
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            unsafe voicePlayer.deinitialize(count: 1)
            unsafe voicePlayer.deallocate()
        }
    }
    
    #if os(macOS)
    func updateTitleBar(for window: NSWindow) {
        let isFullscreen = window.styleMask.contains(.fullScreen)
        window.titleVisibility = isFullscreen ? .hidden : .visible
        window.titlebarAppearsTransparent = isFullscreen
    }
    #endif
}

@safe
private struct InteractiveStoryLive2DView: View {
    var data: _DoriAPI.Misc.StoryAsset.LayoutData
    var voicePlayer: UnsafeMutablePointer<AVAudioPlayer>
    var currentSpeckerID: Int
    @Environment(\._layoutViewVisible) private var isVisible
    @State private var motions = [Live2DMotion]()
    @State private var expressions = [Live2DExpression]()
    @State private var lipSyncValue = 0.0
    @State private var lipSyncTimer: Timer?
    var body: some View {
        Live2DView(resourceURL: URL(string: "https://bestdori.com/assets/jp/live2d/chara/\(data.costumeType)_rip/buildData.asset")!)
            .live2dPauseAnimations(!isVisible) // performance
            .live2dMotion(isVisible ? motions.first(where: { $0.name == data.motionName }) : nil)
            .live2dExpression(isVisible ? expressions.first(where: { $0.name == data.expressionName }) : nil)
            .live2dLipSync(value: currentSpeckerID == data.characterID ? lipSyncValue : nil)
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
                            unsafe voicePlayer.pointee.updateMeters()
                            lipSyncValue = pow(10, Double(unsafe voicePlayer.pointee.peakPower(forChannel: 0)) / 20) - 0.3
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

private struct InteractiveStoryDialogBoxView: View {
    var data: _DoriAPI.Misc.StoryAsset.TalkData
    var locale: DoriLocale
    var isDelaying: Bool
    var isAutoPlaying: Bool
    @AppStorage("interactiveStoryViewerShowsNextIndicator") var interactiveStoryViewerShowsNextIndicator = false
    @Binding var isAnimating: Bool
    @Binding var shakeDuration: Double
    @State private var currentBody = ""
    @State private var bodyAnimationTimer: Timer?
    @State private var shakeTimer: Timer?
    @State private var shakingOffset = CGSize(width: 0, height: 0)
    @State private var autoPlayLabelBlinkTimer: Timer?
    @State private var isShowingAutoPlayLabel = false
    var body: some View {
        ZStack(alignment: .topLeading) {
            backgroundLayer
            textLayer
            labelLayer
        }
        .offset(shakingOffset)
        .onAppear {
            animateText()
        }
        .onChange(of: data.body) {
            animateText()
        }
        .onChange(of: isAutoPlaying) {
            if isAutoPlaying {
                autoPlayLabelBlinkTimer = .scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    DispatchQueue.main.async {
                        isShowingAutoPlayLabel.toggle()
                    }
                }
            } else {
                autoPlayLabelBlinkTimer?.invalidate()
                isShowingAutoPlayLabel = false
            }
        }
        .onChange(of: isAnimating) {
            if !isAnimating {
                bodyAnimationTimer?.invalidate()
                currentBody = data.body
            }
        }
        .onChange(of: shakeDuration) {
            if shakeDuration > 0 {
                let startTime = CFAbsoluteTimeGetCurrent()
                shakeTimer = .scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                    DispatchQueue.main.async {
                        if _fastPath(CFAbsoluteTimeGetCurrent() - startTime < shakeDuration) {
                            shakingOffset = .init(width: .random(in: -5...5), height: .random(in: -5...5))
                        } else {
                            shakeTimer?.invalidate()
                            shakingOffset = .init(width: 0, height: 0)
                            shakeDuration = 0
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var backgroundLayer: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.8))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.gray.opacity(0.8))
            }
            .overlay {
                HStack {
                    Spacer()
                    VStack(spacing: 0) {
                        Spacer()
                        if !isDelaying && interactiveStoryViewerShowsNextIndicator {
                            TimelineView(.animation(minimumInterval: 1 / 120)) { context in
                                Image("ContinuableMark")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 25)
                                    .visualEffect { content, geometry in
                                        content
                                            .colorEffect(ShaderLibrary.continuableMark(.float2(geometry.size)))
                                    }
                                    .offset(y: sin(context.date.timeIntervalSince1970 * 5) * 7)
                                    .scaleEffect(x: 1, y: 0.95 + (1.05 - 0.95) * sin(-context.date.timeIntervalSince1970 * 5), anchor: .bottom)
                            }
                            .zIndex(1)
                            Circle()
                                .fill(Color.gray.opacity(0.8))
                                .blur(radius: 5)
                                .transformEffect(.init(scaleX: 1, y: 0.5))
                                .frame(width: 25, height: 25)
                                .offset(x: -3)
                        }
                    }
                    .transition(.opacity)
                    .animation(.spring(duration: 0.2, bounce: 0.15), value: isDelaying)
                }
                .padding(.trailing)
            }
            .containerRelativeFrame(.vertical) { length, _ in
                min(length / 2 - 80, 130)
            }
    }
    @ViewBuilder
    private var textLayer: some View {
        Text({
            var result = AttributedString()
            for character in currentBody {
                var str = AttributedString(String(character))
                if locale == .cn && "[，。！？；：（）【】「」『』、“”‘’——…]".contains(character) {
                    // The font for cn has too wide punctuations,
                    // we have to fix it here.
                    // System font seems higher than cn font,
                    // we use a smaller size for it to prevent
                    // the line height being changed during animation
                    #if os(macOS)
                    str.font = .system(size: 19, weight: .medium)
                    #else
                    str.font = .system(size: 15, weight: .medium)
                    #endif
                }
                result.append(str)
            }
            return result
        }())
        #if os(macOS)
        .font(.custom(fontName(in: locale), size: 20))
        #else
        .font(.custom(fontName(in: locale), size: 16))
        #endif
        .wrapIf(locale == .en || locale == .tw) { content in
            content
                .lineSpacing(locale == .en ? 10 : -5)
        }
        .typesettingLanguage(locale.nsLocale().language)
        .textSelection(.enabled)
        .foregroundStyle(Color(red: 80 / 255, green: 80 / 255, blue: 80 / 255))
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    @ViewBuilder
    private var labelLayer: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .fill(Color(red: 255 / 255, green: 59 / 255, blue: 114 / 255))
                .overlay {
                    HStack {
                        Spacer()
                        Image("NameSideStar")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 31)
                    }
                    .clipShape(Capsule())
                }
                .overlay {
                    Capsule()
                        .strokeBorder(Color.white, lineWidth: 2)
                }
                .frame(width: 200, height: 32)
            Text(data.windowDisplayName)
            #if os(macOS)
                .font(.custom(fontName(in: locale), size: 21))
            #else
                .font(.custom(fontName(in: locale), size: 17))
            #endif
                .foregroundStyle(.white)
                .padding()
        }
        .offset(y: -38)
        HStack {
            Spacer()
            if isShowingAutoPlayLabel {
                HStack(spacing: 2) {
                    Image(systemName: "arrowtriangle.forward.fill")
                        .scaleEffect(x: 0.7, y: 1, anchor: .trailing)
                    Text(verbatim: "AUTO")
                }
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .modifier(StrokeTextModifier(width: Double(1.5), color: .white))
                .foregroundStyle(Color(red: 255 / 255, green: 59 / 255, blue: 114 / 255))
            }
        }
        .padding(.horizontal, 30)
        .offset(y: -5)
    }
    
    func animateText() {
        isAnimating = true
        currentBody = ""
        var iterator = data.body.makeIterator()
        bodyAnimationTimer?.invalidate()
        bodyAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            DispatchQueue.main.async {
                if let character = iterator.next() {
                    currentBody += String(character)
                } else {
                    isAnimating = false
                }
            }
        }
    }
}

private struct BacklogView: View {
    var asset: _DoriAPI.Misc.StoryAsset
    var currentTalk: _DoriAPI.Misc.StoryAsset.TalkData
    var locale: DoriLocale
    var audios: [_DoriAPI.Misc.StoryAsset.TalkData.Voice: Data]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        VStack(spacing: 0) {
            #if os(macOS)
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark")
                        .fontWeight(.semibold)
                        .padding(8)
                })
                .buttonBorderShape(.circle)
                .wrapIf(true) { content in
                    if #available(macOS 26.0, *) {
                        content
                            .buttonStyle(.glass)
                    } else {
                        content
                            .buttonStyle(.bordered)
                    }
                }
                .padding([.top, .trailing], 10)
            }
            .padding(.bottom, 5)
            Divider()
                .padding(.horizontal, -15)
            #endif
            ScrollView {
                HStack {
                    VStack(alignment: .leading) {
                        ForEach(asset.talkData[asset.talkData.startIndex...asset.talkData.firstIndex(of: currentTalk)!], id: \.self) { talk in
                            HStack(alignment: .top) {
                                ZStack(alignment: .bottomTrailing) {
                                    WebImage(url: URL(string: "https://bestdori.com/res/icon/chara_icon_\(talk.talkCharacters.first?.characterID ?? -1).png"))
                                        .resizable()
                                        .frame(width: 40, height: 40)
                                    if let voice = talk.voices.first, let audioData = audios[voice] {
                                        Button(action: {
                                            if let player = try? AVAudioPlayer(data: audioData) {
                                                player.play()
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                                    _fixLifetime(player)
                                                }
                                            }
                                        }, label: {
                                            Image(systemName: "speaker.wave.3.fill")
                                                .modifier(StrokeTextModifier(width: 1, color: .white))
                                                .foregroundStyle(Color(red: 255 / 255, green: 59 / 255, blue: 114 / 255))
                                                .shadow(radius: 1)
                                        })
                                        .buttonStyle(.plain)
                                        .offset(x: 5, y: 5)
                                    }
                                }
                                VStack(alignment: .leading) {
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color(red: 255 / 255, green: 59 / 255, blue: 114 / 255))
                                            .frame(width: 200, height: 20)
                                        Text(talk.windowDisplayName)
                                            .font(.custom(fontName(in: locale), size: 15))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 10)
                                    }
                                    Text(talk.body)
                                        .font(.custom(fontName(in: locale), size: 16))
                                        .textSelection(.enabled)
                                        .foregroundStyle(colorScheme == .light ? Color(red: 80 / 255, green: 80 / 255, blue: 80 / 255) : .init(red: 238 / 255, green: 238 / 255, blue: 238 / 255))
                                        .padding(.leading, 20)
                                }
                            }
                            .padding(.bottom)
                        }
                    }
                    Spacer()
                }
                .padding()
            }
        }
        #if !os(macOS)
        .toolbar {
            ToolbarItem {
                Button(action: {
                    dismiss()
                }, label: {
                    Image(systemName: "xmark")
                })
            }
        }
        #endif
    }
}

private struct ShakeScreenModifier: ViewModifier {
    @Binding var shakeDuration: Double
    @State private var shakeTimer: Timer?
    @State private var shakingOffset = CGSize(width: 0, height: 0)
    #if os(macOS)
    @State private var currentWindow: NSWindow?
    #endif
    func body(content: Content) -> some View {
        content
        #if os(macOS)
            .introspect(.window, on: .macOS(.v14...)) { window in
                DispatchQueue.main.async {
                    currentWindow = window
                }
            }
        #else
            .offset(shakingOffset)
        #endif
            .onChange(of: shakeDuration) {
                if shakeDuration > 0 {
                    let startTime = CFAbsoluteTimeGetCurrent()
                    #if os(macOS)
                    let startFrame = currentWindow?.frame
                    #endif
                    shakeTimer = .scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                        DispatchQueue.main.async {
                            if _fastPath(CFAbsoluteTimeGetCurrent() - startTime < shakeDuration) {
                                #if os(macOS)
                                if let startFrame {
                                    currentWindow?.setFrameOrigin(.init(x: startFrame.origin.x + .random(in: -5...5), y: startFrame.origin.y + .random(in: -5...5)))
                                }
                                #else
                                shakingOffset = .init(width: .random(in: -5...5), height: .random(in: -5...5))
                                #endif
                            } else {
                                shakeTimer?.invalidate()
                                #if os(macOS)
                                if let startFrame {
                                    currentWindow?.setFrameOrigin(startFrame.origin)
                                }
                                #else
                                shakingOffset = .init(width: 0, height: 0)
                                #endif
                                shakeDuration = 0
                            }
                        }
                    }
                }
            }
    }
}

private struct StrokeTextModifier: ViewModifier {
    var width: CGFloat
    var color: Color
    func body(content: Content) -> some View {
        ZStack {
            ZStack {
                content
                    .offset(x: width, y: width)
                content
                    .offset(x: -width, y: -width)
                content
                    .offset(x: -width, y: width)
                content
                    .offset(x: width, y: -width)
                content
                    .offset(x: width * sqrt(2), y: 0)
                content
                    .offset(x: 0, y: width * sqrt(2))
                content
                    .offset(x: -width * sqrt(2), y: 0)
                content
                    .offset(x: 0, y: -width * sqrt(2))
            }
            .foregroundStyle(color)
            content
        }
    }
}

func fontName(in locale: DoriLocale) -> String {
    switch locale {
    case .jp: "RodinPro-DB"
    case .en: "NewRodinPro-DB"
    case .tw: "SourceHanSansTC-Bold"
    case .cn: "Tensentype-JiaLiDaYuanGB18030"
    case .kr: "JejuGothic"
    }
}

extension EnvironmentValues {
    @Entry fileprivate var _layoutViewVisible: Bool = false
}
