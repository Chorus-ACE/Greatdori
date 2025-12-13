//===---*- Greatdori! -*---------------------------------------------------===//
//
// AssetExplorerFileViewer.swift
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

import Alamofire
import AVKit
import DoriKit
import SwiftUI
import UniformTypeIdentifiers

@_spi(Advanced) import SwiftUIIntrospect

struct AssetTextViewer: View {
    var url: URL
    var name: String
    @Environment(\.dismiss) private var dismiss
    @State private var content: String?
    @State private var isFailedToLoad = false
    var body: some View {
        NavigationStack {
            Group {
                if let content {
                    Group {
#if os(iOS)
                        _SelectableTextView(content: content)
                            .ignoresSafeArea()
#else
                        ScrollView {
                            HStack {
                                Text(content)
                                    .textSelection(.enabled)
                                Spacer()
                            }
                        }
#endif
                    }
                    .fontDesign(.monospaced)
                } else {
                    if !isFailedToLoad {
                        ProgressView()
                            .controlSize(.large)
                            .onAppear {
                                AF.request(url).response { response in
                                    if let data = response.data,
                                       let content = String(data: data, encoding: .utf8) {
                                        DispatchQueue.main.async {
                                            self.content = content
                                        }
                                    } else {
                                        DispatchQueue.main.async {
                                            isFailedToLoad = true
                                        }
                                    }
                                }
                            }
                    } else {
                        ExtendedConstraints {
                            ContentUnavailableView("Asset-explorer.text.failure", systemImage: "exclamationmark.triangle.fill", description: Text("Asset-explorer.text.failure.description"))
                        }
                        .onTapGesture {
                            isFailedToLoad = false
                        }
                    }
                }
            }
            .navigationTitle(name)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
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
}


#if os(macOS)
struct AssetAudioPlayer: View {
    var url: URL
    var name: String
    private var player: AVPlayer
    
    init(url: URL, name: String) {
        self.url = url
        self.name = name
        self.player = .init(url: url)
    }
    
    @State private var isPlaying = false
    @State private var currentTime = 0.0
    @State private var duration = 0.0
    @State private var timeUpdateTimer: Timer?
    @State private var isTimeEditing = false
    @State private var volume = 1.0
    @State private var volumeSymbol = "speaker.wave.3.fill"
    
    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                Text(formatTime(currentTime))
                Slider(value: $currentTime, in: 0...duration) { isEditing in
                    if !isEditing {
                        player.seek(to: .init(seconds: currentTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                    }
                    isTimeEditing = isEditing
                }
                Text(formatTime(duration))
            }
            Spacer(minLength: 0)
            HStack(spacing: 40) {
                Button(action: {
                    player.seek(to: .init(seconds: currentTime - 15, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                }, label: {
                    Image(systemName: "15.arrow.trianglehead.counterclockwise")
                })
                .font(.system(size: 20))
                Button(action: {
                    if isPlaying {
                        player.pause()
                    } else {
                        player.play()
                    }
                }, label: {
                    if isPlaying {
                        Image(systemName: "pause.fill")
                    } else {
                        Image(systemName: "play.fill")
                    }
                })
                .font(.system(size: 40))
                Button(action: {
                    player.seek(to: .init(seconds: currentTime + 15, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                }, label: {
                    Image(systemName: "15.arrow.trianglehead.clockwise")
                })
                .font(.system(size: 20))
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
            HStack(spacing: 20) {
                Image(systemName: volumeSymbol)
                Slider(value: $volume)
                    .onChange(of: volume) {
                        player.volume = Float(volume)
                        withAnimation {
                            if volume >= 0.7 {
                                volumeSymbol = "speaker.wave.3.fill"
                            } else if volume > 0.3 {
                                volumeSymbol = "speaker.wave.2.fill"
                            } else if volume > 0 {
                                volumeSymbol = "speaker.wave.1.fill"
                            } else {
                                volumeSymbol = "speaker.slash.fill"
                            }
                        }
                    }
            }
            .buttonStyle(.plain)
        }
        .padding()
        .tint(.white)
        .foregroundStyle(.white)
        .frame(minWidth: 350, minHeight: 150)
        .navigationTitle(name)
        .preferredColorScheme(.dark)
        .onAppear {
            player.play()
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
            player.pause()
        }
        .onReceive(player.publisher(for: \.currentItem?.duration)) { duration in
            if let duration, duration.seconds.isFinite {
                self.duration = duration.seconds
            }
        }
        .onReceive(player.publisher(for: \.timeControlStatus)) { status in
            isPlaying = status == .playing
        }
        .introspect(.window, on: .macOS(.v14...)) { window in
            window.styleMask.insert(.fullSizeContentView)
            window.backgroundColor = .init(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
            window.titlebarAppearsTransparent = true
            window.standardWindowButton(.miniaturizeButton)?.isEnabled = false
            window.standardWindowButton(.zoomButton)?.isEnabled = false
            window.isRestorable = false
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
#else
struct AssetAudioPlayer: View {
    var url: URL
    var name: String
    private var player: AVPlayer
    
    init(url: URL, name: String) {
        self.url = url
        self.name = name
        self.player = .init(url: url)
    }
    
    @Environment(\.dismiss) private var dismiss
    @State private var isPlaying = false
    @State private var currentTime = 0.0
    @State private var duration = 0.0
    @State private var timeUpdateTimer: Timer?
    @State private var isTimeEditing = false
    @State private var volume = 1.0
    @State private var dismissingOffset: CGFloat = 0
    
    var body: some View {
        ZStack {
            Color.gray.ignoresSafeArea()
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            withAnimation {
                                dismissingOffset = max(value.translation.height, 0)
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                withAnimation {
                                    dismissingOffset = 1000
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    var transaction = Transaction()
                                    transaction.disablesAnimations = true
                                    withTransaction(transaction) {
                                        dismiss()
                                    }
                                }
                            } else {
                                withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                                    dismissingOffset = 0
                                }
                            }
                        }
                )
            VStack(spacing: 20) {
                Capsule()
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 50, height: 5)
                Spacer()
                Image(_internalSystemName: "music")
                    .font(.system(size: 140))
                    .foregroundStyle(.gray)
                    .padding(60)
                    .background {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.black.opacity(0.7))
                    }
                    .scaleEffect(isPlaying ? 1 : 0.9)
                    .animation(.spring(duration: 0.3, bounce: 0.2), value: isPlaying)
                    .allowsHitTesting(false)
                Spacer()
                VStack(spacing: 0) {
                    HStack {
                        Text(name)
                            .font(.system(size: 17, weight: .semibold))
                        Spacer()
                    }
                    .padding(.bottom)
                    Slider(value: $currentTime, in: 0...duration) { isEditing in
                        if !isEditing {
                            player.seek(to: .init(seconds: currentTime, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                        }
                        isTimeEditing = isEditing
                    }
                    HStack {
                        Text(formatTime(currentTime))
                        Spacer()
                        Text(formatTime(duration))
                    }
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .padding(.horizontal)
                Spacer()
                    .frame(height: 20)
                HStack(spacing: 60) {
                    Button(action: {
                        player.seek(to: .init(seconds: currentTime - 15, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                    }, label: {
                        Image(systemName: "15.arrow.trianglehead.counterclockwise")
                    })
                    .font(.system(size: 30))
                    Button(action: {
                        if isPlaying {
                            player.pause()
                        } else {
                            player.play()
                        }
                    }, label: {
                        if isPlaying {
                            Image(systemName: "pause.fill")
                        } else {
                            Image(systemName: "play.fill")
                        }
                    })
                    .font(.system(size: 60))
                    Button(action: {
                        player.seek(to: .init(seconds: currentTime + 15, preferredTimescale: CMTimeScale(NSEC_PER_SEC)))
                    }, label: {
                        Image(systemName: "15.arrow.trianglehead.clockwise")
                    })
                    .font(.system(size: 30))
                }
                .buttonStyle(.plain)
                Spacer()
                    .frame(height: 20)
                HStack(spacing: 20) {
                    Image(systemName: "speaker.fill")
                    Slider(value: $volume)
                        .onChange(of: volume) {
                            player.volume = Float(volume)
                        }
                    Image(systemName: "speaker.wave.3.fill")
                }
                .buttonStyle(.plain)
                .padding(.horizontal)
            }
            .padding()
        }
        .tint(.white)
        .foregroundStyle(.white)
        .frame(minWidth: 350, minHeight: 150)
        .offset(y: dismissingOffset)
        .navigationTitle(name)
        .preferredColorScheme(.dark)
        .presentationBackground(Color.clear)
        .onAppear {
            player.play()
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
            player.pause()
        }
        .onReceive(player.publisher(for: \.currentItem?.duration)) { duration in
            if let duration, duration.seconds.isFinite {
                self.duration = duration.seconds
            }
        }
        .onReceive(player.publisher(for: \.timeControlStatus)) { status in
            isPlaying = status == .playing
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
#endif


struct AssetVideoPlayer: View {
    private var player: AVPlayer
    
    init(url: URL) {
        self.player = .init(url: url)
#if os(iOS)
        setDeviceOrientation(allowing: .landscape)
#endif
    }
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VideoPlayer(player: player)
                .ignoresSafeArea()
                .wrapIf(!isMACOS) { content in
                    content
                        .toolbar {
                            ToolbarItem {
                                Button(action: {
#if os(iOS)
                                    setDeviceOrientation(to: .portrait, allowing: .portrait)
#endif
                                    dismiss()
                                }, label: {
                                    Image(systemName: "xmark")
                                })
                            }
                        }
                }
        }
        .onAppear {
            player.play()
        }
        .onDisappear {
            player.pause()
        }
    }
}


#if os(iOS)
struct _SelectableTextView: UIViewRepresentable {
    var content: String
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isEditable = false
        view.isSelectable = true
        view.backgroundColor = .clear
        view.text = content
        view.font = .preferredFont(forTextStyle: .body)
        view.textColor = .label
        return view
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {
        uiView.text = content
    }
}
#endif

