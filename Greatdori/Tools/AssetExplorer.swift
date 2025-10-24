//===---*- Greatdori! -*---------------------------------------------------===//
//
// AssetExplorer.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.memz.top/LICENSE.txt for license information
// See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import AVKit
import DoriKit
import SwiftUI
import Alamofire
import UniformTypeIdentifiers
@_spi(Advanced) import SwiftUIIntrospect

struct AssetExplorerView: View {
    var body: some View {
        AssetListView(items: [
            .init(type: .folder, name: "jp") {
                LocaleAssetView(locale: .jp)
            },
            .init(type: .folder, name: "en") {
                LocaleAssetView(locale: .en)
            },
            .init(type: .folder, name: "tw") {
                LocaleAssetView(locale: .tw)
            },
            .init(type: .folder, name: "cn") {
                LocaleAssetView(locale: .cn)
            },
            .init(type: .folder, name: "kr") {
                LocaleAssetView(locale: .kr)
            }
        ])
    }
}

private struct LocaleAssetView: View {
    var locale: DoriLocale
    @State private var assetList: DoriAPI.Assets.AssetList?
    var body: some View {
        if let assetList {
            AssetListView(items: .init(assetList, path: .init(locale: locale)))
        } else {
            ProgressView()
                .controlSize(.large)
                .onAppear {
                    Task {
                        assetList = await DoriAPI.Assets.info(in: locale)
                    }
                }
        }
    }
}

private struct AssetItem: @unchecked Sendable, Hashable {
    var type: AssetType
    var name: String
    var view: AnyView
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.type == rhs.type && lhs.name == rhs.name
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(name)
    }
    
    enum AssetType {
        case file
        case folder
        case rip
    }
}
extension AssetItem {
    init(type: AssetType, name: String, @ViewBuilder content: () -> some View) {
        self.init(type: type, name: name, view: AnyView(content()))
    }
}
extension Array<AssetItem> {
    init(_ info: DoriAPI.Assets.AssetList, path: DoriAPI.Assets.PathDescriptor) {
        func resolveInfo(_ info: DoriAPI.Assets.AssetList, path: DoriAPI.Assets.PathDescriptor) -> [AssetItem] {
            var result = [AssetItem]()
            let keys = info.keys.sorted()
            for key in keys {
                var newPath = path
                let value = info.access(key, updatingPath: &newPath)!
                switch value {
                case .files:
                    result.append(.init(type: .rip, name: key) {
                        AssetListView(currentPath: newPath)
                    })
                case .list(let list):
                    result.append(.init(type: .folder, name: key) {
                        AssetListView(items: resolveInfo(list, path: newPath), currentPath: newPath)
                    })
                }
            }
            return result
        }
        
        self = resolveInfo(info, path: path)
    }
}

private struct AssetListView: View {
    @State var items: [AssetItem]?
    var currentPath: DoriAPI.Assets.PathDescriptor?
    @State private var tintingItem: AssetItem?
    @State private var navigatingItem: AssetItem?
    @State private var previousTapTime = 0.0
    @State private var itemLookViewContent: ItemPresenter?
    @State private var contentLoadingItem: AssetItem?
    @State private var fileExporterDocument: AssetFileDocument?
    @State private var fileExporterDefaultFileName: String?
    @State private var isFileExporterPresented = false
    var body: some View {
        Group {
            if let items {
                List {
                    ForEach(Array(items.enumerated()), id: \.element.self) { index, item in
                        HStack {
                            Label {
                                Text(item.name)
                            } icon: {
                                if contentLoadingItem != item {
                                    switch item.type {
                                    case .file:
                                        Image(systemName: "document")
                                            .foregroundStyle(.gray)
                                    case .folder:
                                        Image(systemName: "folder.fill")
                                            .foregroundStyle(Color(red: 121 / 255, green: 190 / 255, blue: 230 / 255).gradient)
                                            .background {
                                                Rectangle()
                                                    .fill(Color.white)
                                                    .padding(isMACOS ? 3 : 4)
                                                    .offset(y: 1)
                                            }
                                    case .rip:
                                        Image(systemName: "zipper.page")
                                            .foregroundStyle(.gray)
                                    }
                                } else {
                                    ProgressView()
                                        .wrapIf(isMACOS) { content in
                                            content
                                                .controlSize(.small)
                                        }
                                }
                            }
                            Spacer()
                        }
                        .contentShape(Rectangle())
                        .wrapIf(isMACOS) { content in
                            content
                                .onTapGesture {
                                    if (item == tintingItem && CFAbsoluteTimeGetCurrent() - previousTapTime < 0.5) {
                                        if item.type == .file {
                                            openItem(item)
                                        } else {
                                            navigatingItem = item
                                        }
                                    }
                                    tintingItem = item
                                    previousTapTime = CFAbsoluteTimeGetCurrent()
                                }
                                .listRowBackground(itemBackground(for: item, index: index))
                                .listRowSeparator(.hidden)
                                .listRowInsets(.init(top: 2, leading: 0, bottom: 2, trailing: 0))
                        } else: { content in
                            content
                                .onTapGesture {
                                    if item.type == .file {
                                        openItem(item)
                                    } else {
                                        navigatingItem = item
                                    }
                                }
                                .wrapIf(index == 0 || index == items.count - 1) { content in
                                    content
                                        .listRowSeparator(.hidden, edges: index == 0 ? .top : .bottom)
                                }
                        }
                        .contextMenu {
                            Section {
                                if item.type == .file, let path = currentPath {
                                    Button("下载", systemImage: "arrow.down.circle") {
                                        downloadItem(item, withPath: path)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .wrapIf(isMACOS) { content in
                    content
                        .environment(\.defaultMinListRowHeight, 5)
                        .padding(.horizontal, 10)
                }
                .navigationTitle(currentPath?.componments.last ?? String(localized: "数据包浏览器"))
                #if !os(macOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
                .navigationDestination(item: $navigatingItem) { item in
                    item.view
                }
                #if os(macOS)
                .window(item: $itemLookViewContent) { content in
                    content.view
                }
                #else
                .fullScreenCover(item: $itemLookViewContent) { content in
                    content.view
                }
                #endif
                .fileExporter(
                    isPresented: $isFileExporterPresented,
                    document: fileExporterDocument,
                    contentType: .content,
                    defaultFilename: fileExporterDefaultFileName
                ) { _ in
                    fileExporterDocument = nil
                    fileExporterDefaultFileName = nil
                }
            } else if let currentPath {
                ExtendedConstraints {
                    ProgressView()
                        .controlSize(.large)
                        .onAppear {
                            Task {
                                if let contents = await DoriAPI.Assets.contentsOf(currentPath) {
                                    items = contents.map {
                                        .init(type: .file, name: $0) {}
                                    }
                                }
                            }
                        }
                }
            } else {
                ExtendedConstraints {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.yellow)
                }
            }
        }
        .withSystemBackground()
    }
    
    @ViewBuilder
    private func itemBackground(for item: AssetItem, index: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
            #if os(macOS)
                .fill(Color(.selectedContentBackgroundColor))
            #endif
                .opacity(tintingItem == item ? 1 : 0)
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.11))
                .opacity(tintingItem != item && index % 2 != 0 ? 1 : 0)
        }
    }
    
    private func openItem(_ item: AssetItem) {
        if let path = currentPath {
            if item.name.hasSuffix(".png") || item.name.hasSuffix(".jpg") {
                contentLoadingItem = item
                AF.request(path.resourceURL(name: item.name)).response { response in
                    if let data = response.data {
                        #if os(macOS)
                        let image = NSImage(data: data)
                        #else
                        let image = UIImage(data: data)
                        #endif
                        if let image {
                            DispatchQueue.main.async {
                                #if os(macOS)
                                itemLookViewContent = .init {
                                    ImageLookView(image: image, title: item.name)
                                }
                                #else
                                itemLookViewContent = .init {
                                    ImageLookView(
                                        image: image,
                                        title: item.name,
                                        subtitle: path.locale.rawValue.uppercased(),
                                        imageFrame: .zero
                                    )
                                }
                                #endif
                            }
                        }
                    }
                    DispatchQueue.main.async {
                        contentLoadingItem = nil
                    }
                }
            } else if item.name.hasSuffix(".mp3") {
                itemLookViewContent = .init {
                    AssetAudioPlayer(url: path.resourceURL(name: item.name), name: item.name)
                }
            } else if item.name.hasSuffix(".mp4") {
                itemLookViewContent = .init {
                    AssetVideoPlayer(url: path.resourceURL(name: item.name))
                }
            } else if [".txt", ".json", ".asset", ".bundle", ".sprites"].contains(where: { item.name.hasSuffix($0) }) {
                itemLookViewContent = .init {
                    AssetTextViewer(url: path.resourceURL(name: item.name), name: item.name)
                }
            }
        }
    }
    private func downloadItem(_ item: AssetItem, withPath path: DoriAPI.Assets.PathDescriptor) {
        contentLoadingItem = item
        #if os(macOS)
        let downloadURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!.appending(path: item.name)
        AF.download(path.resourceURL(name: item.name), to: { _, _ in
            (downloadURL, [])
        }).response { response in
            if response.error == nil {
                DistributedNotificationCenter.default.post(
                    name: .init("com.apple.DownloadFileFinished"),
                    object: downloadURL.resolvingSymlinksInPath().path
                )
            }
            DispatchQueue.main.async {
                contentLoadingItem = nil
            }
        }
        #else // os(macOS)
        AF.request(path.resourceURL(name: item.name)).response { response in
            DispatchQueue.main.async {
                if let data = response.data {
                    fileExporterDocument = .init(data: data)
                    fileExporterDefaultFileName = item.name
                    isFileExporterPresented = true
                }
                contentLoadingItem = nil
            }
        }
        #endif // os(macOS)
    }
    
    private struct ItemPresenter: Identifiable {
        var id = UUID()
        var view: AnyView
        
        init(@ViewBuilder content: () -> some View) {
            self.view = AnyView(content())
        }
    }
}

private struct AssetFileDocument: FileDocument {
    static var readableContentTypes: [UTType] {
        [] // readnone
    }
    static var writableContentTypes: [UTType] {
        [.content]
    }
    
    private let data: Data
    
    init(data: Data) {
        self.data = data
    }
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            self.data = data
        } else {
            throw CocoaError(.fileReadCorruptFile)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        .init(regularFileWithContents: data)
    }
}

#if os(macOS)
private struct AssetAudioPlayer: View {
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
#else // os(macOS)
private struct AssetAudioPlayer: View {
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
#endif // os(macOS)

private struct AssetVideoPlayer: View {
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

private struct AssetTextViewer: View {
    var url: URL
    var name: String
    @Environment(\.dismiss) private var dismiss
    @State private var content: String?
    @State private var isFailedToLoad = false
    var body: some View {
        NavigationStack {
            Group {
                if let content {
                    #if os(iOS)
                    _SelectableTextView(content: content)
                        .ignoresSafeArea()
                    #else
                    ScrollView {
                        Text(content)
                            .textSelection(.enabled)
                    }
                    #endif
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
                            ContentUnavailableView("载入文本时出错", systemImage: "exclamationmark.triangle.fill", description: Text("轻触以重试"))
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
#if os(iOS)
private struct _SelectableTextView: UIViewRepresentable {
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
