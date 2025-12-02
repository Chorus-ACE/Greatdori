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

private final class ReferenceCountingContainer: @unchecked Sendable, ObservableObject {
    @Published var _count: Int = 0
    @Published var _tappingActionCount: Int = 0
    var observers: [UUID: AnyCancellable] = [:]
    
    let isValidInstance: Bool
    
    init(valid: Bool = true) {
        self.isValidInstance = valid
    }
    
    private let countLock = NSLock()
    var count: Int {
        get {
            assert(isValidInstance, "Attempting to access an invalid ReferenceCountingContainer")
            return countLock.withLock {
                _count
            }
        }
        set {
            assert(isValidInstance, "Attempting to access an invalid ReferenceCountingContainer")
            countLock.withLock {
                _count = newValue
            }
        }
    }
    private let tappingCountLock = NSLock()
    var tappingActionCount: Int {
        get {
            assert(isValidInstance, "Attempting to access an invalid ReferenceCountingContainer")
            return tappingCountLock.withLock {
                _tappingActionCount
            }
        }
        set {
            assert(isValidInstance, "Attempting to access an invalid ReferenceCountingContainer")
            tappingCountLock.withLock {
                _tappingActionCount = newValue
            }
        }
    }
}

@safe
struct InteractiveStoryView: View {
    var ir: StoryIR
    var assetFolder: URL?
    
    @TaskLocal nonisolated private static var performingActionCount = ReferenceCountingContainer(valid: false)
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var backgroundImageURL: URL?
    @State private var isBackgroundImageNative = true
    
    @State private var bgmPlayer = AVQueuePlayer()
    @State private var bgmLooper: AVPlayerLooper!
    @State private var sePlayer = AVPlayer()
    private var voicePlayer: UnsafeMutablePointer<AVAudioPlayer>
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
    
    init(_ ir: StoryIR, assetFolder: URL? = nil) {
        self.ir = ir
        self.assetFolder = assetFolder
        
        unsafe voicePlayer = .allocate(capacity: 1)
        unsafe voicePlayer.initialize(to: .init())
    }
    init(asset: _DoriAPI.Misc.StoryAsset, voiceBundlePath: String, locale: DoriLocale) {
        let ir = DoriStoryBuilder.Conversion.zeileIR(
            fromBandori: asset,
            in: locale,
            voiceBundlePath: voiceBundlePath
        )
        self.init(ir)
    }
    
    var body: some View {
        ZStack {
            // Characters
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
                                unsafe InteractiveStoryLive2DView(modelPath: layout.modelPath, state: showingLayoutIndexs[index], voicePlayer: voicePlayer, currentSpeckerID: currentTalk?.characterIDs.first ?? -1)
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
            }
            #if os(iOS)
            .ignoresSafeArea()
            #endif
            
            // Dialog Box
            if let currentTalk, !uiIsHiding {
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        InteractiveStoryDialogBoxView(
                            data: currentTalk,
                            locale: ir.locale,
                            isDelaying: false,
                            isAutoPlaying: isAutoPlaying,
                            isAnimating: $lineIsAnimating,
                            shakeDuration: $talkShakeDuration
                        )
                        .padding(isMACOS ? .all : .horizontal)
                        Spacer()
                    }
                    .padding(.bottom)
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
                        .font(.custom(fontName(in: ir.locale), size: 18))
                        .foregroundStyle(Color(red: 80 / 255, green: 80 / 255, blue: 80 / 255))
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)).combined(with: .opacity))
            }
            
//            #if os(iOS)
            // FIXME: Consider removal.
            /*
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
            */
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
                .aspectRatio(isBackgroundImageNative ? 4 / 3 : nil, contentMode: .fill)
                .clipped()
                .ignoresSafeArea(edges: isMACOS ? .vertical : .all)
        }
        .modifier(ShakeScreenModifier(shakeDuration: $screenShakeDuration)) //FIXME: Consider Edits
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
                    BacklogView(ir: ir, currentTalk: talk, locale: ir.locale, audios: talkAudios)
                    #if os(macOS)
                        .frame(width: 500, height: 350)
                    #endif
                }
            }
        }
        #if os(macOS)
        .toolbar {
            ToolbarItem {
                actionMenu
            }
        }
        #endif
        .onAppear {
            if backgroundImageURL != nil {
                return
            }
            
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
        .frame(minWidth: 300, minHeight: 75)
    }
    
    @ViewBuilder
    var actionMenu: some View {
        Menu {
            Section {
                Button(isAutoPlaying ? "Story-viewer.menu.auto.cancel" : "Story-viewer.menu.auto", systemImage: isAutoPlaying ? "play.slash" : "play") {
                    isAutoPlaying.toggle()
                    if isAutoPlaying {
                        next()
                    } else {
                        autoPlayTimer?.invalidate()
                    }
                }
                Button("Story-viewer.menu.full-screen", systemImage: "pano.badge.play") {
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
//                    fastForwardTimer = .scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
//                        DispatchQueue.main.async {
//                            next(ignoresDelay: true)
//                        }
//                    }
                }, label: {
                    if fastForwardTimer == nil {
                        Label("Story-viewer.menu.fast-forward", systemImage: "forward")
                    } else {
                        Label("Story-viewer.menu.fast-forward.cancel", image: "custom.forward.slash")
                    }
                })
                Button("Story-viewer.menu.backlog", systemImage: "text.document") {
                    backlogIsPresenting = true
                }
                .disabled(currentTalk == nil)
                Button("Story-viewer.menu.hide", systemImage: "xmark") {
                    uiIsHiding = true
                }
                Button("Story-viewer.menu.quit", systemImage: "escape", role: .destructive) {
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
    
    func start() {
        @safe nonisolated(unsafe) let ir = ir
        detachedReferenceCountedTask { @Sendable in
            for action in ir.actions {
                await perform(action: action)
            }
        }
    }
    func next() {
        currentInteractBlockingContinuation?.resume()
        currentInteractBlockingContinuation = nil
    }
    func perform(action: StoryIR.StepAction) async {
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
                    characterNames: characterNames
                )
                
                if let voicePath,
                   let voice = talkAudios[voicePath],
                   let newPlayer = try? AVAudioPlayer(data: voice) {
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
                
                await withCheckedContinuation { continuation in
                    currentInteractBlockingContinuation = continuation
                }
                
                Self.performingActionCount.count -= 1
                Self.performingActionCount.tappingActionCount -= 1
            }
        case .telop(let text):
            Task {
                Self.performingActionCount.tappingActionCount += 1
                
                withAnimation {
                    currentTalk = nil
                    currentTelop = text
                }
                
                if isAutoPlaying {
                    autoPlayTimer = .scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                        DispatchQueue.main.async {
                            next()
                        }
                    }
                }
                
                await withCheckedContinuation { continuation in
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
            break // FIXME
        case .verticalShake(characterID: let characterID):
            Self.performingActionCount.count -= 1
            break // FIXME
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
    
    func detachedReferenceCountedTask(operation: sending @escaping @isolated(any) () async -> Void) {
        Task.detached {
            await Self.$performingActionCount.withValue(.init()) {
                await operation()
            }
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
    #endif // os(macOS)
}

private struct LayoutState: Equatable {
    var characterID: Int
    var position: StoryIR.StepAction.Position
    var motion: String = ""
    var expression: String = ""
}
struct TalkData: Hashable {
    var text: String
    var characterIDs: [Int]
    var characterNames: [String]
    var voicePath: String?
}

@safe
private struct InteractiveStoryLive2DView: View {
    var modelPath: String
    var state: LayoutState?
    var voicePlayer: UnsafeMutablePointer<AVAudioPlayer>
    var currentSpeckerID: Int
    @Environment(\._layoutViewVisible) private var isVisible
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
                            unsafe voicePlayer.pointee.updateMeters()
                            
                            // -160.0...0.0
                            let power = Double(unsafe voicePlayer.pointee.peakPower(forChannel: 0))
                            lipSyncValue = pow(10, power / 20) - 0.3
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

private struct BacklogView: View {
    var ir: StoryIR
    var currentTalk: TalkData
    var locale: DoriLocale
    var audios: [String: Data]
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
                contentView
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
    
    @ViewBuilder
    var contentView: some View {
        HStack {
            VStack(alignment: .leading) {
                let talks = ir.actions.compactMap {
                    if case let .talk(text, characterIDs: ids, characterNames: names, voicePath: vp) = $0 {
                        return TalkData(text: text, characterIDs: ids, characterNames: names, voicePath: vp)
                    }
                    return nil
                }
                ForEach(talks[talks.startIndex...talks.firstIndex(of: currentTalk)!], id: \.self) { talk in
                    HStack(alignment: .top) {
                        ZStack(alignment: .bottomTrailing) {
                            WebImage(url: URL(string: "https://bestdori.com/res/icon/chara_icon_\(talk.characterIDs.first ?? -1).png"))
                                .resizable()
                                .frame(width: 40, height: 40)
                            if let voice = talk.voicePath, let audioData = audios[voice] {
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
                                Text(talk.characterNames.joined(separator: " & "))
                                    .font(.custom(fontName(in: locale), size: 15))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                            }
                            Text(talk.text)
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

struct ShakeScreenModifier: ViewModifier {
    @Binding var shakeDuration: Double
    @State private var shakeTimer: Timer?
    @State private var shakingOffset = CGSize(width: 0, height: 0)
//    #if os(macOS)
//    @State private var currentWindow: NSWindow?
//    #endif
    func body(content: Content) -> some View {
        content
//        #if os(macOS)
//            .introspect(.window, on: .macOS(.v14...)) { window in
//                DispatchQueue.main.async {
//                    currentWindow = window
//                }
//            }
//        #else
            .offset(shakingOffset)
//        #endif
            .onChange(of: shakeDuration) {
                if shakeDuration > 0 {
                    let startTime = CFAbsoluteTimeGetCurrent()
//                    #if os(macOS)
//                    let startFrame = currentWindow?.frame
//                    #endif
                    shakeTimer = .scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                        DispatchQueue.main.async {
                            if _fastPath(CFAbsoluteTimeGetCurrent() - startTime < shakeDuration) {
//                                #if os(macOS)
//                                if let startFrame {
//                                    currentWindow?.setFrameOrigin(.init(x: startFrame.origin.x + .random(in: -5...5), y: startFrame.origin.y + .random(in: -5...5)))
//                                }
//                                #else
                                shakingOffset = .init(width: .random(in: -5...5), height: .random(in: -5...5))
//                                #endif
                            } else {
                                shakeTimer?.invalidate()
//                                #if os(macOS)
//                                if let startFrame {
//                                    currentWindow?.setFrameOrigin(startFrame.origin)
//                                }
//                                #else
                                shakingOffset = .init(width: 0, height: 0)
//                                #endif
                                shakeDuration = 0
                            }
                        }
                    }
                }
            }
    }
}

struct StrokeTextModifier: ViewModifier {
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
    return UserDefaults.standard.string(forKey: "StoryViewerFont\(locale.rawValue.uppercased())") ?? storyViewerDefaultFont[locale] ?? ".AppleSystemUIFont"
}

@safe
func resolveURL(from path: String, assetFolder: URL?, isNative: UnsafeMutablePointer<Bool>? = nil) -> URL {
    // We can't use `inout` for isNative because
    // it prevents us to provide a default value (nil) for it
    
    if path.hasPrefix("http://") || path.hasPrefix("https://") {
        unsafe isNative?.pointee = path.hasPrefix("https://bestdori.com/assets")
        return URL(string: path)!
    } else if path.hasPrefix("/"), let assetFolder {
        unsafe isNative?.pointee = false
        return assetFolder.appending(path: path.dropFirst())
    } else {
        var componments = path.components(separatedBy: "/")
        if componments.count >= 2 {
            let bundle = componments[componments.count - 2]
            componments[componments.count - 2] = "\(bundle)_rip"
        }
        unsafe isNative?.pointee = true
        return URL(string: "https://bestdori.com/assets/\(componments.joined(separator: "/"))")!
    }
}

extension EnvironmentValues {
    @Entry fileprivate var _layoutViewVisible: Bool = false
}
