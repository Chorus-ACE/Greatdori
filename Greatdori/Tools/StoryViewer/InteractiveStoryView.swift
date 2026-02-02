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
import SymbolAvailability
@_spi(Advanced) import SwiftUIIntrospect

@safe
struct InteractiveStoryView: View {
    var viewID: UUID
    var ir: StoryIR
    var assetFolder: URL?
    
    @TaskLocal nonisolated private static var performingActionCount = ReferenceCountingContainer(parentID: nil)
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\._isvIsMuted) private var isMuted
    @Environment(\._isvIsInFullScreen) private var interactivePlayerIsInFullScreen
    @Environment(\._isvCurrentBlockingActionIndex) private var currentBlockingActionIndex
    
    @AppStorage("ISVAlwaysFullScreen") var isvAlwaysFullScreen = false
    
    @State private var backgroundImageURL: URL?
    @State private var isBackgroundImageNative = true
    
    @State private var bgmPlayer = AVQueuePlayer()
    @State private var bgmLooper: AVPlayerLooper!
    @State private var sePlayer = AVPlayer()
    @State private var voicePlayer: AVAudioPlayer? = nil
    @State private var currentSnippetIndex = -1
    @State private var currentTelop: String?
    
    @State private var allDiffLayouts = [(characterID: Int, modelPath: String)]()
    @State private var showingLayoutIndexs = [Int: LayoutState]()
    @State private var currentTalk: TalkData?
    @State private var talkAudios = [String: Data]()
    
    @State private var currentInteractBlockingContinuation: CheckedContinuation<Void, Never>?
    @State private var whiteCoverIsDisplaying = false
    @State private var blackCoverIsShowing = false
    
    @State private var lineIsAnimating = false
    @State private var uiIsHiding = false
    @State private var backlogIsPresenting = false
    @State private var isAutoPlaying = false
    
    @State private var autoPlayTimer: Timer?
    @State private var fastForwardTimer: Timer?
    @State private var talkShakeDuration = 0.0
    @State private var screenShakeDuration = 0.0
    
    @State private var frameWidth: CGFloat = 0
    @State private var frameHeight: CGFloat = 0
    
    @State var locale: DoriLocale = .jp
    
    private var fullScreenToggleIsAvailable: Bool
    private var mutingIsAvailable: Bool
    
    private var onTalkUpdate: ((TalkData?, Bool, Binding<Bool>, Binding<Double>) -> Void)?
    
    init(_ ir: StoryIR, assetFolder: URL? = nil, fullScreenToggleIsAvailable: Bool = false, mutingIsAvailable: Bool = false, locale: DoriLocale = DoriLocale.primaryLocale) {
        // We assign an ID for ISV so that we can identify data related
        // to this view in some global states
        self.viewID = .init()
        
        self.ir = ir
        self.assetFolder = assetFolder
        self.fullScreenToggleIsAvailable = fullScreenToggleIsAvailable
        self.mutingIsAvailable = mutingIsAvailable
        self.locale = locale
    }
    init(asset: DoriAPI.Misc.StoryAsset, voiceBundlePath: String, locale: DoriLocale) {
        let ir = DoriStoryBuilder.Conversion.zeileIR(
            fromBandori: asset,
            in: locale,
            voiceBundlePath: voiceBundlePath
        )
        self.init(ir)
        self.fullScreenToggleIsAvailable = true
        self.mutingIsAvailable = true
        self.locale = locale
    }
    
    #if os(visionOS)
    init(
        _ ir: StoryIR,
        assetFolder: URL? = nil,
        locale: DoriLocale = DoriLocale.primaryLocale,
        onTalkUpdate: @escaping (TalkData?, Bool, Binding<Bool>, Binding<Double>) -> Void
    ) {
        self.init(
            ir,
            assetFolder: assetFolder,
            fullScreenToggleIsAvailable: false,
            mutingIsAvailable: true,
            locale: locale
        )
        self.onTalkUpdate = onTalkUpdate
    }
    #endif
    
    var body: some View {
        ZStack {
            // MARK: - Characters
            GeometryReader { geometry in
                ZStack {
                    ForEach(Array(allDiffLayouts.enumerated()), id: \.element.modelPath) { index, layout in
                        HStack {
                            Spacer(minLength: 0)
                            VStack {
                                Spacer(minLength: 0)
                                let offsetX = { () -> CGFloat in
                                    if let state = showingLayoutIndexs[index] {
                                        return switch state.position.base {
                                        case .left: -(geometry.size.width / 4)
                                        case .leftOutside: -(geometry.size.width / 3)
                                        case .leftInside: -(geometry.size.width / 6)
                                        case .center: 0
                                        case .centerBottom: 0
                                        case .right: geometry.size.width / 4
                                        case .rightOutside: geometry.size.width / 3
                                        case .rightInside: geometry.size.width / 6
                                        case .leftBottom: -(geometry.size.width / 4)
                                        case .leftInsideBottom: -(geometry.size.width / 6)
                                        case .rightBottom: geometry.size.width / 4
                                        case .rightInsideBottom: geometry.size.width / 6
                                        @unknown default: 0
                                        }
                                    } else {
                                        return 0
                                    }
                                }()
                                let offsetY = { () -> CGFloat in
                                    if let state = showingLayoutIndexs[index] {
                                        return switch state.position.base {
                                        case .leftBottom,
                                                .leftInsideBottom,
                                                .centerBottom,
                                                .rightBottom,
                                                .rightInsideBottom: geometry.size.height / 6
                                        default: 0
                                        }
                                    } else {
                                        return 0
                                    }
                                }()
                                ISVLive2DView(modelPath: layout.modelPath, state: showingLayoutIndexs[index], currentSpeckerID: currentTalk?.characterIDs.first ?? -1)
                                    .safeVoicePlayer($voicePlayer)
                                    .frame(width: geometry.size.height, height: geometry.size.height)
                                    .offset(x: offsetX, y: offsetY)
                                    .opacity(showingLayoutIndexs[index] != nil ? 1 : 0)
                                    .environment(\._layoutViewVisible, showingLayoutIndexs[index] != nil)
                                    .animation(.spring(duration: 0.4, bounce: 0.25), value: showingLayoutIndexs)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
                #if os(visionOS)
                .offset(z: 10)
                #endif
            }
            #if os(iOS)
            .ignoresSafeArea()
            #endif
            
            // MARK: - Dialog Box
            if let currentTalk, !uiIsHiding {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        ISVDialogBoxView(
                            data: currentTalk,
                            locale: ir.locale,
                            isDelaying: false,
                            isAutoPlaying: isAutoPlaying,
                            isAnimating: $lineIsAnimating,
                            shakeDuration: $talkShakeDuration
                        )
                        .padding(platform != .iOS ? .all : .horizontal)
                        Spacer()
                    }
                    .padding(.bottom)
                }
                .typesettingLanguage(locale.nsLocale().language)
                #if os(visionOS)
                .offset(z: 40)
                .opacity(onTalkUpdate == nil ? 1 : 0)
                #endif
            }
            
            // MARK: - Telop
            if let currentTelop {
                ZStack {
                    Capsule()
                        .fill(Color.red.opacity(0.7))
                        .rotationEffect(.degrees(-0.5))
                        .frame(width: 400 * frameWidth/400/2*1.3, height: 35 * frameWidth/400/2*1.3)
                    Capsule()
                        .fill(Color.white)
                        .rotationEffect(.degrees(0.5))
                        .frame(width: 380 * frameWidth/400/2*1.3, height: 32 * frameWidth/400/2*1.3)
                    Text(currentTelop)
                        .font(.custom(fontName(in: ir.locale), size: 18 * frameWidth/400/2*1.3))
                        .foregroundStyle(Color(red: 80 / 255, green: 80 / 255, blue: 80 / 255))
                }
                .typesettingLanguage(locale.nsLocale().language)
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
                #if os(visionOS)
                .offset(z: 40)
                #endif
            }
            
            // MARK: - Menu
            Group {
                if !uiIsHiding && (platform == .iOS || (platform == .visionOS && onTalkUpdate != nil)) {
                    HStack {
                        Spacer()
                        VStack {
                            #if !os(visionOS)
                            if #available(iOS 26.0, macOS 26.0, *) {
                                actionMenu
                                    .buttonStyle(.glass)
                                    .buttonBorderShape(.circle)
                            } else {
                                actionMenu
                                    .buttonStyle(.bordered)
                                    .buttonBorderShape(.circle)
                            }
                            #else
                            actionMenu
                                .buttonStyle(.bordered)
                                .buttonBorderShape(.circle)
                                .padding(20)
                            #endif
                            Spacer()
                        }
                    }
                    .padding(.vertical, 7)
                }
            }
            // MARK: - Black & White Covers
            Group {
                Rectangle()
                    .fill(Color.white)
                    .opacity(whiteCoverIsDisplaying ? 1 : 0)
                    .ignoresSafeArea(edges: platform == .macOS ? .vertical : .all)
                Rectangle()
                    .fill(Color.black)
                    .opacity(blackCoverIsShowing ? 1 : 0)
                    .ignoresSafeArea(edges: platform == .macOS ? .vertical : .all)
            }
            #if os(visionOS)
            .offset(z: 50)
            #endif
        }
        // MARK: - Modifiers
        .focusable()
        .focusEffectDisabled()
        .frame(minWidth: 300, minHeight: 75)
        .onFrameChange { geometry in
            frameWidth = geometry.size.width
            frameHeight = geometry.size.height
        }
        .background {
            WebImage(url: backgroundImageURL)
                .resizable()
                .aspectRatio(isBackgroundImageNative ? 4 / 3 : nil, contentMode: .fill)
                .clipped()
                .ignoresSafeArea(edges: platform == .macOS ? .vertical : .all)
        }
        .modifier(ShakeScreenModifier(shakeDuration: $screenShakeDuration))
        #if os(visionOS)
        .preferredSurroundingsEffect(.ultraDark)
        #endif
        .onAppear {
            #if !os(macOS)
            try? AVAudioSession.sharedInstance().setActive(true)
            #endif
            if backgroundImageURL != nil {
                return
            }
            
            #if os(visionOS)
            if #available(visionOS 26.0, *) {
                bgmPlayer.intendedSpatialAudioExperience = .fixed
                // Other players have default head-tracked experiences
            }
            #endif
            
            func resolvePre(actions: [StoryIR.StepAction]) {
                for action in actions {
                    if case let .showModel(characterID: charaID, modelPath: modelPath, position: _) = action {
                        if !allDiffLayouts.contains(where: {
                            $0.characterID == charaID
                            && $0.modelPath == modelPath
                        }) {
                            allDiffLayouts.append((charaID, modelPath))
                        }
                    } else if case let .talk(_, characterIDs: _, characterNames: _, voicePath: voicePath) = action,
                              let voicePath {
                        AF.request(resolveURL(from: voicePath, assetFolder: assetFolder)).response { response in
                            if let data = response.data {
                                DispatchQueue.main.async {
                                    talkAudios.updateValue(data, forKey: voicePath)
                                }
                            }
                        }
                    } else if case let .blocking(actions) = action {
                        resolvePre(actions: actions)
                    } else if case let .forkTask(actions) = action {
                        resolvePre(actions: actions)
                    }
                }
            }
            resolvePre(actions: ir.actions)
            
            start()
        }
        .onDisappear {
            exitViewer(dismiss: false)
        }
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
        .onChange(of: isMuted.wrappedValue, initial: true) {
            bgmPlayer.isMuted = isMuted.wrappedValue
            sePlayer.isMuted = isMuted.wrappedValue
            if let voicePlayer {
                voicePlayer.volume = isMuted.wrappedValue ? 0 : 1
            }
        }
        .sheet(isPresented: $backlogIsPresenting) {
            if let talk = currentTalk {
                NavigationStack {
                    ISVBacklogView(ir: ir, currentTalk: talk, locale: ir.locale, audios: talkAudios)
                    #if os(macOS)
                        .frame(width: 500, height: 350)
                    #endif
                }
            }
        }
        #if !os(iOS)
        .toolbar {
            ToolbarItem {
                actionMenu
                    .buttonBorderShape(.circle)
            }
            if interactivePlayerIsInFullScreen.wrappedValue {
                ToolbarItem(placement: .navigation) {
                    Button(action: {
                        interactivePlayerIsInFullScreen.wrappedValue = false
                    }, label: {
                        Image(systemName: .xmark)
                    })
                    .buttonBorderShape(.circle)
                }
            }
        }
        #endif
        #if os(visionOS)
        .onChange(of: currentTalk, isAutoPlaying) {
            onTalkUpdate?(currentTalk, isAutoPlaying, $lineIsAnimating, $talkShakeDuration)
        }
        #endif
    }
    
    // MARK: - actionMenu
    @ViewBuilder
    var actionMenu: some View {
        Menu {
            Section {
                // AUTO-PLAY
                Button(action: {
                    isAutoPlaying.toggle()
                    if isAutoPlaying {
                        next()
                    } else {
                        autoPlayTimer?.invalidate()
                    }
                }, label: {
                    Label(isAutoPlaying ? "Story-viewer.menu.auto.cancel" : "Story-viewer.menu.auto", systemImage: isAutoPlaying ? "play.slash" : "play")
                })
                
                // HIDE & AUTO-PLAY
                Button(action: {
                    isAutoPlaying = true
                    uiIsHiding = true
                    next()
                }, label: {
                    Label("Story-viewer.menu.hide-ui-auto", systemImage: "pano.badge.play")
                })
                .disabled(talkAudios.isEmpty)
                
                // FAST FORWARD
                Button(action: {
                    if fastForwardTimer != nil {
                        fastForwardTimer?.invalidate()
                        fastForwardTimer = nil
                        return
                    }
                    fastForwardTimer = .scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
                        DispatchQueue.main.async {
                            ReferenceCountingContainer.all[viewID]?.forEach {
                                $0.count = 0
                                $0.tappingActionCount = 0
                            }
                            next()
                        }
                    }
                }, label: {
                    if fastForwardTimer == nil {
                        Label("Story-viewer.menu.fast-forward", systemImage: "forward")
                    } else {
                        Label("Story-viewer.menu.fast-forward.cancel", image: "custom.forward.slash")
                    }
                })
                
                // BACKLOG
                Button(action: {
                    backlogIsPresenting = true
                }, label: {
                    Label("Story-viewer.menu.backlog", systemImage: "text.document")
                })
                .disabled(currentTalk == nil)
                
                // HIDE UI
                Button(action: {
                    uiIsHiding = true
                }, label: {
                    Label("Story-viewer.menu.hide", systemImage: "xmark")
                })
                
                // MUTE
                if mutingIsAvailable {
                    Button(action: {
                        isMuted.wrappedValue.toggle()
                    }, label: {
                        if isMuted.wrappedValue {
                            Label("Story-viewer.menu.mute.quit", systemImage: "speaker.wave.2")
                        } else {
                            Label("Story-viewer.menu.mute", systemImage: "speaker.slash")
                        }
                    })
                }
                
                if isvAlwaysFullScreen || !fullScreenToggleIsAvailable {
                    // QUIT
                    Button(role: .destructive, action: {
                        dismiss()
                    }, label: {
                        Label("Story-viewer.menu.quit", systemImage: "escape")
                    })
                    .foregroundStyle(.red)
                } else {
                    // FULL SCREEN
                    Button(action: {
                        interactivePlayerIsInFullScreen.wrappedValue.toggle()
                    }, label: {
                        if interactivePlayerIsInFullScreen.wrappedValue {
                            Label("Story-viewer.menu.full-screen.quit", systemImage: "arrow.up.forward.and.arrow.down.backward")
                        } else {
                            Label("Story-viewer.menu.full-screen.enter", systemImage: "arrow.down.backward.and.arrow.up.forward")
                        }
                    })
                }
            }
        } label: {
            Image(systemName: .ellipsis)
                .wrapIf(!isMACOS) {
                    $0.font(.system(size: 20)).padding(5)
                        .wrapIf(isvAlwaysFullScreen) { content in
                            content.padding(7)
                        }
                }
        }
        .menuStyle(.button)
        .menuIndicator(.hidden)
    }
    
    // MARK: - start
    func start() {
        @safe nonisolated(unsafe) let ir = ir
        detachedReferenceCountedTask { @Sendable in
            for (index,action) in ir.actions.enumerated() {
                await perform(action: action, actionSeriesIndex: index)
            }
        }
    }
    
    // MARK: - next
    func next() {
        currentBlockingActionIndex.wrappedValue = nil
        currentInteractBlockingContinuation?.resume()
        currentInteractBlockingContinuation = nil
    }
    
    // MARK: - perform
    func perform(action: StoryIR.StepAction, actionSeriesIndex: Int? = nil) async {
        Self.performingActionCount.count += 1
        
        if currentTelop != nil {
            if case .telop = action {
                withAnimation {
                    currentTelop = nil
                }
                try? await Task.sleep(for: .seconds(1))
            } else {
                withAnimation {
                    currentTelop = nil
                }
            }
        }
        
        switch action {
        case .talk(let text, characterIDs: let characterIDs, characterNames: let characterNames, voicePath: let voicePath):
            Task {
                Self.performingActionCount.tappingActionCount += 1
                
                currentTalk = .init(
                    text: text,
                    characterIDs: characterIDs,
                    characterNames: characterNames,
                    voicePath: voicePath
                )
                
                if let voicePath,
                   let voice = talkAudios[voicePath],
                   let newPlayer = try? AVAudioPlayer(data: voice) {
                    newPlayer.isMeteringEnabled = true
                    voicePlayer?.stop()
                    voicePlayer = newPlayer
                    if let voicePlayer {
                        voicePlayer.volume = isMuted.wrappedValue ? 0 : 1
                        voicePlayer.play()
                        if isAutoPlaying {
                            autoPlayTimer = .scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
                                if !voicePlayer.isPlaying {
                                    timer.invalidate()
                                    autoPlayTimer = .scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                                        DispatchQueue.main.async {
                                            next()
                                        }
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
                
                await withCheckedContinuation { continuation in
                    currentBlockingActionIndex.wrappedValue = actionSeriesIndex
                    currentInteractBlockingContinuation = continuation
                }
                
                Self.performingActionCount.count -= 1
                Self.performingActionCount.tappingActionCount -= 1
            }
        case .telop(let text):
            Task {
                Self.performingActionCount.tappingActionCount += 1
                
                await MainActor.run {
                    withAnimation {
                        currentTalk = nil
                        currentTelop = text
                    }
                }
                
                if isAutoPlaying {
                    autoPlayTimer = .scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                        DispatchQueue.main.async {
                            next()
                        }
                    }
                }
                
                await withCheckedContinuation { continuation in
                    currentBlockingActionIndex.wrappedValue = actionSeriesIndex
                    currentInteractBlockingContinuation = continuation
                }
                
                Self.performingActionCount.count -= 1
                Self.performingActionCount.tappingActionCount -= 1
            }
        case .showModel(characterID: let characterID, modelPath: let modelPath, position: let position):
            if let index = allDiffLayouts.firstIndex(where: {
                $0.characterID == characterID && $0.modelPath == modelPath
            }) {
                showingLayoutIndexs.updateValue(.init(characterID: characterID, position: position), forKey: index)
            }
            
            // Showing a model takes constant time
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                Self.performingActionCount.count -= 1
            }
        case .hideModel(characterID: let characterID):
            let indexs = allDiffLayouts.enumerated()
                .filter({ $0.element.characterID == characterID })
                .map({ $0.offset })
            for index in indexs {
                showingLayoutIndexs.removeValue(forKey: index)
            }
            
            // Hiding a model takes constant time
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                Self.performingActionCount.count -= 1
            }
        case .moveModel(characterID: let characterID, position: let position):
            let indexs = allDiffLayouts.enumerated()
                .filter({ $0.element.characterID == characterID })
                .map({ $0.offset })
            for index in indexs {
                if var currentState = showingLayoutIndexs[index] {
                    currentState.position = position
                    showingLayoutIndexs.updateValue(currentState, forKey: index)
                }
            }
            
            // Moving a model takes constant time
            Task {
                try? await Task.sleep(for: .seconds(0.3))
                Self.performingActionCount.count -= 1
            }
        case .act(characterID: let characterID, motionName: let motionName):
            let indexs = allDiffLayouts.enumerated()
                .filter({ $0.element.characterID == characterID })
                .map({ $0.offset })
            for index in indexs {
                if var currentState = showingLayoutIndexs[index] {
                    currentState.motion = motionName
                    showingLayoutIndexs.updateValue(currentState, forKey: index)
                }
            }
            
            // FIXME: Resume when the action is really finished
            Task {
                try? await Task.sleep(for: .seconds(0.5))
                Self.performingActionCount.count -= 1
            }
        case .express(characterID: let characterID, expressionName: let expressionName):
            let indexs = allDiffLayouts.enumerated()
                .filter({ $0.element.characterID == characterID })
                .map({ $0.offset })
            for index in indexs {
                if var currentState = showingLayoutIndexs[index] {
                    currentState.expression = expressionName
                    showingLayoutIndexs.updateValue(currentState, forKey: index)
                }
            }
            
            // FIXME: Resume when the action is really finished
            Task {
                try? await Task.sleep(for: .seconds(0.5))
                Self.performingActionCount.count -= 1
            }
        case .horizontalShake(characterID: let characterID):
            Self.performingActionCount.count -= 1
            break // FIXME: horizontalShake
        case .verticalShake(characterID: let characterID):
            Self.performingActionCount.count -= 1
            break // FIXME: verticalShake
        case .showBlackCover(duration: let duration):
            withAnimation(.linear(duration: duration)) {
                blackCoverIsShowing = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                whiteCoverIsDisplaying = false
            }
            Task {
                try? await Task.sleep(for: .seconds(duration))
                Self.performingActionCount.count -= 1
            }
        case .hideBlackCover(duration: let duration):
            withAnimation(.linear(duration: duration)) {
                blackCoverIsShowing = false
            }
            Task {
                try? await Task.sleep(for: .seconds(duration))
                Self.performingActionCount.count -= 1
            }
        case .showWhiteCover(duration: let duration):
            withAnimation(.linear(duration: duration)) {
                whiteCoverIsDisplaying = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                blackCoverIsShowing = false
            }
            Task {
                try? await Task.sleep(for: .seconds(duration))
                Self.performingActionCount.count -= 1
            }
        case .hideWhiteCover(duration: let duration):
            withAnimation(.linear(duration: duration)) {
                whiteCoverIsDisplaying = false
            }
            Task {
                try? await Task.sleep(for: .seconds(duration))
                Self.performingActionCount.count -= 1
            }
        case .shakeScreen(duration: let duration):
            screenShakeDuration = duration
            
            Task {
                try? await Task.sleep(for: .seconds(duration))
                Self.performingActionCount.count -= 1
            }
        case .shakeDialogBox(duration: let duration):
            talkShakeDuration = duration
            
            Task {
                try? await Task.sleep(for: .seconds(duration))
                Self.performingActionCount.count -= 1
            }
        case .changeBackground(path: let path):
            withAnimation {
                backgroundImageURL = resolveURL(
                    from: path,
                    assetFolder: assetFolder,
                    isNative: &isBackgroundImageNative
                )
            }
            
            Self.performingActionCount.count -= 1
        case .changeBGM(path: let path):
            bgmPlayer.pause()
            bgmPlayer.removeAllItems()
            let bgmItem = AVPlayerItem(url: resolveURL(from: path, assetFolder: assetFolder))
            bgmLooper = .init(player: bgmPlayer, templateItem: bgmItem)
            bgmPlayer.play()
            
            Self.performingActionCount.count -= 1
        case .changeSE(path: let path):
            sePlayer.replaceCurrentItem(with: .init(url: resolveURL(from: path, assetFolder: assetFolder)))
            sePlayer.play()
            
            Self.performingActionCount.count -= 1
        case .blocking(let actions):
            Self.performingActionCount.count -= 1
            await withCheckedContinuation { continuation in
                detachedReferenceCountedTask {
                    await withTaskGroup { group in
                        for action in actions {
                            group.addTask {
                                await perform(action: action)
                            }
                        }
                        group.addTask {
                            await perform(action: .waitForAll)
                        }
                    }
                    continuation.resume()
                }
            }
        case .delay(seconds: let seconds):
            try? await Task.sleep(for: .seconds(seconds))
            Self.performingActionCount.count -= 1
        case .forkTask(let actions):
            detachedReferenceCountedTask {
                for action in actions {
                    await perform(action: action)
                }
            }
            Self.performingActionCount.count -= 1
        case .waitForAll:
            Self.performingActionCount.count -= 1
            if Self.performingActionCount.count > 0 {
                let id = UUID()
                await withCheckedContinuation { continuation in
                    let observer = Self.performingActionCount.$_count.sink { newCount in
                        if newCount <= 0 {
                            continuation.resume()
                        }
                    }
                    Self.performingActionCount.observers.updateValue(observer, forKey: id)
                }
                Self.performingActionCount.observers.removeValue(forKey: id)
            }
        case .waitForTap:
            Self.performingActionCount.count -= 1
            if Self.performingActionCount.tappingActionCount > 0 {
                let id = UUID()
                await withCheckedContinuation { continuation in
                    let observer = Self.performingActionCount.$_tappingActionCount.sink { newCount in
                        if newCount <= 0 {
                            continuation.resume()
                        }
                    }
                    Self.performingActionCount.observers.updateValue(observer, forKey: id)
                }
                Self.performingActionCount.observers.removeValue(forKey: id)
            }
        @unknown default: break
        }
    }
    
    // MARK: - detachedReferenceCountedTask
    func detachedReferenceCountedTask(operation: sending @escaping @isolated(any) () async -> Void) {
        Task.detached {
            await Self.$performingActionCount.withValue(.init(parentID: viewID)) {
                await operation()
            }
        }
    }
    
    // MARK: - exitViewer
    func exitViewer(dismiss doDismiss: Bool = true) {
        // clean up
        autoPlayTimer?.invalidate()
        fastForwardTimer?.invalidate()
        bgmPlayer.pause()
        sePlayer.pause()
        voicePlayer?.stop()
        
        if doDismiss {
            dismiss()
        }
        
        #if os(iOS)
        setDeviceOrientation(to: .portrait, allowing: .portrait)
        #endif
        #if !os(macOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }
}

extension View {
    func isvIsMuted(_ muted: Binding<Bool>) -> some View {
        environment(\._isvIsMuted, muted)
    }
    func isvIsInFullScreen(_ fullScreen: Binding<Bool>) -> some View {
        environment(\._isvIsInFullScreen, fullScreen)
    }
    func isvCurrentBlockingActionIndex(_ index: Binding<Int?>) -> some View {
        environment(\._isvCurrentBlockingActionIndex, index)
    }
}
extension EnvironmentValues {
    @Entry fileprivate var _isvIsMuted: Binding<Bool> = .constant(false)
    @Entry fileprivate var _isvIsInFullScreen: Binding<Bool> = .constant(false)
    @Entry fileprivate var _isvCurrentBlockingActionIndex: Binding<Int?> = .constant(nil)
}
