//===---*- Greatdori! -*---------------------------------------------------===//
//
// ChartSimulator.swift
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

import Metal
import System
import DoriKit
import SwiftUI
import MetalKit
import SpriteKit
import Alamofire
import SwiftyJSON
import AppleArchive

struct ChartSimulatorView: View {
    @State private var selectedSong: PreviewSong?
    @State private var isSongSelectorPresented = false
    @State private var selectedDifficulty: _DoriAPI.Songs.DifficultyType = .easy
    @State private var chart: [_DoriAPI.Songs.Chart]?
    @State private var chartScenes: [ChartViewerScene] = []
    @State private var showChartPlayer = false
    @State private var isChartPlayerAssetAvailable = ChartPlayerAssetManager.isAvailable
    @State private var isDownloadingChartPlayerAsset = false
    @State private var availableWidth: CGFloat = 0
    var body: some View {
        ScrollView {
            HStack {
                Spacer(minLength: 0)
                VStack {
                    CustomGroupBox(cornerRadius: 20) {
                        VStack {
                            ListItemView {
                                Text("歌曲")
                                    .bold()
                            } value: {
                                Button(action: {
                                    isSongSelectorPresented = true
                                }, label: {
                                    if let selectedSong {
                                        Text(selectedSong.title.forPreferredLocale() ?? "")
                                    } else {
                                        Text("选择歌曲…")
                                    }
                                })
                                .window(isPresented: $isSongSelectorPresented) {
                                    SongSelector(selection: .init { [selectedSong].compactMap { $0 } } set: { selectedSong = $0.first })
                                        .selectorDisablesMultipleSelection()
                                }
                                .onChange(of: selectedSong) {
                                    loadChart()
                                }
                            }
                            if let selectedSong {
                                ListItemView {
                                    Text("难度")
                                        .bold()
                                } value: {
                                    Picker(selection: $selectedDifficulty) {
                                        ForEach(selectedSong.difficulty.keys.sorted { $0.rawValue < $1.rawValue }, id: \.rawValue) { key in
                                            Text(String(selectedSong.difficulty[key]!.playLevel)).tag(key)
                                        }
                                    } label: {
                                        EmptyView()
                                    }
                                    .onChange(of: selectedDifficulty) {
                                        loadChart()
                                    }
                                }
                            }
                            ListItemView {
                                Text("显示模拟器") // FIXME: Text style
                                    .bold()
                            } value: {
                                Toggle(isOn: $showChartPlayer) {
                                    EmptyView()
                                }
                                .toggleStyle(.switch)
                                .labelsHidden()
                            }
                        }
                    }
                    CustomGroupBox(cornerRadius: 20) {
                        if !showChartPlayer {
                            ScrollView(.horizontal) {
                                HStack(spacing: 0) {
                                    ForEach(chartScenes, id: \.self) { scene in
                                        SpriteView(scene: scene)
                                            .frame(width: 240, height: 500)
                                    }
                                }
                            }
                        } else {
                            if isChartPlayerAssetAvailable {
                                if let chart {
                                    ChartPlayerView(chart: chart)
                                        .frame(idealWidth: availableWidth, idealHeight: availableWidth / 16 * 9)
                                        
                                }
                            } else {
                                HStack {
                                    Spacer()
                                    VStack {
                                        Text("使用谱面模拟器前需要下载附加资源（约38MB）")
                                        Button("下载") {
                                            Task {
                                                isDownloadingChartPlayerAsset = true
                                                _ = await ChartPlayerAssetManager.download()
                                                isChartPlayerAssetAvailable = ChartPlayerAssetManager.isAvailable
                                                isDownloadingChartPlayerAsset = false
                                            }
                                        }
                                        .disabled(isDownloadingChartPlayerAsset)
                                    }
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding()
                Spacer(minLength: 0)
            }
        }
        .navigationTitle("谱面模拟器")
        .onFrameChange { geometry in
            availableWidth = geometry.size.width
        }
    }
    
    func loadChart() {
        guard let selectedSong else { return }
        Task {
            chart = await _DoriAPI.Songs.charts(of: selectedSong.id, in: selectedDifficulty)
            if let chart {
                let chartHeight = (chartLastBeat(chart) + 1) * 100
                let renderHeight: Double = 500
                let splitCount = Int(ceil(chartHeight / renderHeight))
                chartScenes.removeAll()
                for i in 0..<splitCount {
                    chartScenes.append(.init(size: .init(width: 240, height: renderHeight), chart: chart, splitIndex: i))
                }
            }
        }
    }
}

// MARK: - Chart Viewer
// For identifying, Chart Viewer is a plain chart view without any motion,
// whereas Chart Player is like the one in GBP with moving notes.

private class ChartViewerScene: SKScene {
    let chart: [_DoriAPI.Songs.Chart]
    let splitIndex: Int
    let configuration = ChartViewerConfiguration()
    
    init(size: CGSize, chart: [_DoriAPI.Songs.Chart], splitIndex: Int) {
        self.chart = chart
        self.splitIndex = splitIndex
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .black
        
        let combinedNode = SKNode()
        
        let chartHeight = (chartLastBeat(chart) + 1) * 100
        let backgroundNode = LineBackgroundNode(size: .init(width: 240, height: chartHeight))
        combinedNode.addChild(backgroundNode)
        
        let notesNode = NotesNode(width: 210, chart: chart, textures: configuration.textureGroup())
        notesNode.position.x += 15
        combinedNode.addChild(notesNode)
        
        let croppedNode = SKCropNode()
        let mask = SKShapeNode(
            rect: .init(
                x: 0,
                y: CGFloat(splitIndex) * size.height,
                width: 240,
                height: size.height
            )
        )
        mask.fillColor = .white
        croppedNode.maskNode = mask
        croppedNode.addChild(combinedNode)
        croppedNode.position = .init(x: 0, y: -size.height * CGFloat(splitIndex))
        addChild(croppedNode)
    }
    
    private class NotesNode: SKNode {
        static let _longNoteLineShader = {
            let shader = SKShader(fileNamed: "ShaderSource/ChartViewer_LongNoteLine.fsh")
            shader.attributes = [
                .init(name: "a_is_trailing_end", type: .float),
                .init(name: "a_lane_factor", type: .float),
                .init(name: "a_frame", type: .vectorFloat2)
            ]
            return shader
        }()
        
        init(
            width: CGFloat,
            chart: [_DoriAPI.Songs.Chart],
            textures: ChartViewerConfiguration._TextureGroup
        ) {
            super.init()
            
            let laneWidth = width / 7
            let beatHeight: CGFloat = 100
            
            func notePosition(lane: Double, beat: Double) -> CGPoint {
                .init(x: laneWidth * lane + laneWidth / 2, y: beat * beatHeight)
            }
            
            for note in chart {
                switch note {
                case .single(let singleData):
                    let texture = if singleData.flick {
                        textures.flick
                    } else if singleData.skill {
                        textures.skill
                    } else {
                        textures.normal
                    }
                    let noteNode = SKSpriteNode(texture: texture[3])
                    noteNode.position = notePosition(lane: singleData.lane, beat: singleData.beat)
                    let aspectRatio = noteNode.size.width / noteNode.size.height
                    noteNode.size = .init(width: laneWidth, height: laneWidth / aspectRatio)
                    addChild(noteNode)
                    
                    if singleData.flick {
                        // Add `flickTop`
                        let flickTopNode = SKSpriteNode(texture: textures.flickTop)
                        flickTopNode.position = notePosition(lane: singleData.lane, beat: singleData.beat)
                        flickTopNode.position.y += noteNode.size.height / 2
                        let aspectRatio = flickTopNode.size.width / flickTopNode.size.height
                        flickTopNode.size = .init(width: laneWidth / 3 * 2, height: laneWidth / 3 * 2 / aspectRatio)
                        addChild(flickTopNode)
                    }
                case .long(let longData):
                    // `long` is actually `slide` without lane changes,
                    // we use the same method but shader
                    
                    // Render long note line
                    for (index, connection) in longData.connections.enumerated() {
                        guard index + 1 < longData.connections.endIndex else { break }
                        let nextConnection = longData.connections[index + 1]
                        let node = SKSpriteNode(texture: textures.longNoteLine)
                        let connectionPosition = notePosition(lane: connection.lane, beat: connection.beat)
                        let nextConnectionPosition = notePosition(lane: nextConnection.lane, beat: nextConnection.beat)
                        node.size = .init(
                            width: abs(nextConnectionPosition.x - connectionPosition.x) + laneWidth,
                            height: nextConnectionPosition.y - connectionPosition.y
                        )
                        node.position = .init(
                            x: max(connectionPosition.x, nextConnectionPosition.x) - node.size.width / 2 + 15,
                            y: nextConnectionPosition.y - node.size.height / 2
                        )
                        addChild(node)
                    }
                    
                    // Render endpoint notes
                    for connection in longData.connections {
                        let texture = if connection.flick {
                            textures.flick
                        } else {
                            textures.long
                        }
                        let noteNode = SKSpriteNode(texture: texture[3])
                        noteNode.position = notePosition(lane: connection.lane, beat: connection.beat)
                        let aspectRatio = noteNode.size.width / noteNode.size.height
                        noteNode.size = .init(width: laneWidth, height: laneWidth / aspectRatio)
                        addChild(noteNode)
                        
                        if connection.flick {
                            // Add `flickTop`
                            let flickTopNode = SKSpriteNode(texture: textures.flickTop)
                            flickTopNode.position = notePosition(lane: connection.lane, beat: connection.beat)
                            flickTopNode.position.y += noteNode.size.height / 2
                            let aspectRatio = flickTopNode.size.width / flickTopNode.size.height
                            flickTopNode.size = .init(width: laneWidth / 3 * 2, height: laneWidth / 3 * 2 / aspectRatio)
                            addChild(flickTopNode)
                        }
                    }
                case .slide(let slideData):
                    // Render long note lines
                    for (index, connection) in slideData.connections.enumerated() {
                        guard index + 1 < slideData.connections.endIndex else { break }
                        let nextConnection = slideData.connections[index + 1]
                        let node = SKSpriteNode(texture: textures.longNoteLine)
                        let connectionPosition = notePosition(lane: connection.lane, beat: connection.beat)
                        let nextConnectionPosition = notePosition(lane: nextConnection.lane, beat: nextConnection.beat)
                        node.size = .init(
                            width: abs(nextConnectionPosition.x - connectionPosition.x) + laneWidth,
                            height: nextConnectionPosition.y - connectionPosition.y
                        )
                        node.position = .init(
                            x: max(connectionPosition.x, nextConnectionPosition.x) - node.size.width / 2 + 15,
                            y: nextConnectionPosition.y - node.size.height / 2
                        )
                        node.shader = ChartViewerScene.NotesNode._longNoteLineShader
                        node.setValue(.init(float: nextConnectionPosition.x > connectionPosition.x ? 1 : 0), forAttribute: "a_is_trailing_end")
                        node.setValue(.init(float: Float(laneWidth / node.size.width)), forAttribute: "a_lane_factor")
                        node.setValue(.init(vectorFloat2: .init(Float(node.size.width), Float(node.size.height))), forAttribute: "a_frame")
                        addChild(node)
                    }
                    
                    for (index, connection) in slideData.connections.enumerated() {
                        if index == 0 || index == slideData.connections.endIndex - 1 {
                            // Render endpoint notes
                            let texture = if connection.flick {
                                textures.flick
                            } else {
                                textures.long
                            }
                            let noteNode = SKSpriteNode(texture: texture[3])
                            noteNode.position = notePosition(lane: connection.lane, beat: connection.beat)
                            let aspectRatio = noteNode.size.width / noteNode.size.height
                            noteNode.size = .init(width: laneWidth, height: laneWidth / aspectRatio)
                            addChild(noteNode)
                            
                            if connection.flick {
                                // Add `flickTop`
                                let flickTopNode = SKSpriteNode(texture: textures.flickTop)
                                flickTopNode.position = notePosition(lane: connection.lane, beat: connection.beat)
                                flickTopNode.position.y += noteNode.size.height / 2
                                let aspectRatio = flickTopNode.size.width / flickTopNode.size.height
                                flickTopNode.size = .init(width: laneWidth / 3 * 2, height: laneWidth / 3 * 2 / aspectRatio)
                                addChild(flickTopNode)
                            }
                        } else if !connection.hidden {
                            // Add `slideAmong` point
                            let texture = textures.slideAmong
                            let node = SKSpriteNode(texture: texture)
                            node.position = notePosition(lane: connection.lane, beat: connection.beat)
                            let aspectRatio = node.size.width / node.size.height
                            node.size = .init(width: laneWidth, height: laneWidth / aspectRatio)
                            addChild(node)
                        }
                    }
                case .directional(let directionalData):
                    let baseTexture = switch directionalData.direction {
                    case .left: textures.flickLeft
                    case .right: textures.flickRight
                    }
                    let directionMultiplier: Double = directionalData.direction == .right ? 1 : -1
                    let combinedNode = SKNode()
                    for i in 1...directionalData.width {
                        let flickBaseNode = SKSpriteNode(texture: baseTexture[3])
                        flickBaseNode.position = notePosition(lane: directionalData.lane + Double(i - 1) * directionMultiplier, beat: directionalData.beat)
                        let aspectRatio = flickBaseNode.size.width / flickBaseNode.size.height
                        flickBaseNode.size = .init(width: laneWidth * 1.3, height: laneWidth * 1.3 / aspectRatio)
                        combinedNode.addChild(flickBaseNode)
                    }
                    let endpointLane = directionalData.lane + Double(directionalData.width) * directionMultiplier
                    let endpointTexture = switch directionalData.direction {
                    case .left: textures.flickLeftEndpoint
                    case .right: textures.flickRightEndpoint
                    }
                    let endpointNode = SKSpriteNode(texture: endpointTexture)
                    endpointNode.position = notePosition(lane: endpointLane, beat: directionalData.beat)
                    let aspectRatio = endpointNode.size.width / endpointNode.size.height
                    endpointNode.size = .init(width: laneWidth / 2, height: laneWidth / 2 / aspectRatio)
                    endpointNode.position.x -= (laneWidth / 2 - endpointNode.size.width / 3) * directionMultiplier
                    combinedNode.addChild(endpointNode)
                    addChild(combinedNode)
                default: break
                }
            }
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private class LineBackgroundNode: SKNode {
        init(size: CGSize) {
            super.init()
            
            let horizontalPadding: CGFloat = 15
            let fixedWidth = size.width - horizontalPadding * 2
            
            let borderPath = CGMutablePath()
            borderPath.move(to: .init(x: horizontalPadding, y: 0))
            borderPath.addLine(to: .init(x: horizontalPadding, y: size.height))
            borderPath.move(to: .init(x: size.width - horizontalPadding, y: 0))
            borderPath.addLine(to: .init(x: size.width - horizontalPadding, y: size.height))
            
            let borderLineNode = SKShapeNode(path: borderPath)
            borderLineNode.strokeColor = .init(red: 70 / 255, green: 157 / 255, blue: 159 / 255, alpha: 1)
            borderLineNode.lineWidth = 3
            self.addChild(borderLineNode)
            
            let heavyBorderPath = CGMutablePath()
            heavyBorderPath.move(to: .init(x: horizontalPadding - 3, y: 0))
            heavyBorderPath.addLine(to: .init(x: horizontalPadding - 3, y: size.height))
            heavyBorderPath.move(to: .init(x: size.width - horizontalPadding + 3, y: 0))
            heavyBorderPath.addLine(to: .init(x: size.width - horizontalPadding + 3, y: size.height))
            
            let heavyBorderLineNode = SKShapeNode(path: heavyBorderPath)
            heavyBorderLineNode.strokeColor = .init(red: 70 / 255, green: 157 / 255, blue: 159 / 255, alpha: 0.8)
            heavyBorderLineNode.lineWidth = 4
            self.addChild(heavyBorderLineNode)
            
            let sectionPath = CGMutablePath()
            let sectionWidth = fixedWidth / 7
            for i in 1..<7 {
                let x = horizontalPadding + sectionWidth * CGFloat(i)
                sectionPath.move(to: .init(x: x, y: 0))
                sectionPath.addLine(to: .init(x: x, y: size.height))
            }
            var verticalOffset: CGFloat = 0
            while verticalOffset < size.height {
                verticalOffset += 100
                sectionPath.move(to: .init(x: horizontalPadding, y: verticalOffset))
                sectionPath.addLine(to: .init(x: size.width - horizontalPadding, y: verticalOffset))
            }
            
            let sectionLineNode = SKShapeNode(path: sectionPath)
            sectionLineNode.strokeColor = .init(red: 70 / 255, green: 157 / 255, blue: 159 / 255, alpha: 0.6)
            sectionLineNode.lineWidth = 2
            self.addChild(sectionLineNode)
        }
        
        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}

private class ChartViewerConfiguration {
    init() {}
    
    var noteStyle = 0
    var flickStyle = 0
    
    func textureGroup() -> _TextureGroup {
        struct NoteSpriteMetadata: Codable {
            var name: String
            var rect: CGRect
            var offset: CGPoint
            var textureRect: CGRect
            var textureRectOffset: CGPoint
        }
        
        func fixedTextureRect(_ rect: CGRect, in texture: SKTexture) -> CGRect {
            let size = texture.size()
            return .init(x: rect.minX / size.width, y: rect.minY / size.height, width: rect.width / size.width, height: rect.height / size.height)
        }
        func directedTextures(baseName: String, metadata: [NoteSpriteMetadata], texture: SKTexture) -> [SKTexture] {
            var result: [SKTexture] = []
            for i in 0..<7 {
                let rect = metadata.first { $0.name == baseName + "_\(i)" }!.rect
                result.append(.init(rect: fixedTextureRect(rect, in: texture), in: texture))
            }
            return result
        }
        
        let rhythmSprites = SKTexture(imageNamed: "RhythmGameSprites\(noteStyle)")
        let directionalFlickSprites = SKTexture(imageNamed: "DirectionalFlickSprites\(flickStyle)")
        
        guard let rhythmSpriteMetadata = NSDataAsset(name: "RhythmSpritesMeta\(noteStyle)")?.data,
              let directionalFlickSpriteMetadata = NSDataAsset(name: "DirectionalFlickSpritesMeta\(flickStyle)")?.data else {
            fatalError("Failed to load sprite metadata, broken bundle?")
        }
        
        let decoder = PropertyListDecoder()
        guard let rhythmSpriteMeta = try? decoder.decode([NoteSpriteMetadata].self, from: rhythmSpriteMetadata),
              let directionalFlickSpriteMeta = try? decoder.decode([NoteSpriteMetadata].self, from: directionalFlickSpriteMetadata) else {
            fatalError("Failed to decode sprite metadata, broken bundle?")
        }
        
        return .init(
            normal: directedTextures(baseName: "note_normal", metadata: rhythmSpriteMeta, texture: rhythmSprites),
            long: directedTextures(baseName: "note_long", metadata: rhythmSpriteMeta, texture: rhythmSprites),
            flick: directedTextures(baseName: "note_flick", metadata: rhythmSpriteMeta, texture: rhythmSprites),
            flickTop: .init(rect: fixedTextureRect(rhythmSpriteMeta.first { $0.name == "note_flick_top" }!.rect, in: rhythmSprites), in: rhythmSprites),
            skill: directedTextures(baseName: "note_skill", metadata: rhythmSpriteMeta, texture: rhythmSprites),
            slideAmong: .init(rect: fixedTextureRect(rhythmSpriteMeta.first { $0.name == "note_slide_among" }!.rect, in: rhythmSprites), in: rhythmSprites),
            simultaneousLine: .init(rect: rhythmSpriteMeta.first { $0.name == "simultaneous_line" }!.rect, in: rhythmSprites),
            flickLeft: directedTextures(baseName: "note_flick_l", metadata: directionalFlickSpriteMeta, texture: directionalFlickSprites),
            flickRight: directedTextures(baseName: "note_flick_r", metadata: directionalFlickSpriteMeta, texture: directionalFlickSprites),
            flickLeftEndpoint: .init(rect: fixedTextureRect(directionalFlickSpriteMeta.first { $0.name == "note_flick_top_l" }!.rect, in: directionalFlickSprites), in: directionalFlickSprites),
            flickRightEndpoint: .init(rect: fixedTextureRect(directionalFlickSpriteMeta.first { $0.name == "note_flick_top_r" }!.rect, in: directionalFlickSprites), in: directionalFlickSprites),
            longNoteLine: .init(imageNamed: "longNoteLine\(noteStyle)")
        )
    }
    
    struct _TextureGroup {
        let normal: [SKTexture]
        let long: [SKTexture]
        let flick: [SKTexture]
        let flickTop: SKTexture
        let skill: [SKTexture]
        let slideAmong: SKTexture
        let simultaneousLine: SKTexture
        let flickLeft: [SKTexture]
        let flickRight: [SKTexture]
        let flickLeftEndpoint: SKTexture
        let flickRightEndpoint: SKTexture
        let longNoteLine: SKTexture
    }
}

private func chartLastBeat(_ chart: [_DoriAPI.Songs.Chart]) -> Double {
    var lastBeat: Double = 0
    beatFinder: for data in chart.reversed() {
        switch data {
        case .single(let singleData):
            lastBeat = singleData.beat
            break beatFinder
        case .long(let longData):
            for connection in longData.connections {
                if connection.beat > lastBeat {
                    lastBeat = connection.beat
                }
            }
            break beatFinder
        case .slide(let slideData):
            for connection in slideData.connections {
                if connection.beat > lastBeat {
                    lastBeat = connection.beat
                }
            }
            break beatFinder
        case .directional(let directionalData):
            lastBeat = directionalData.beat
            break beatFinder
        default: break
        }
    }
    return lastBeat
}

// MARK: - Chart Player

private final class ChartPlayerAssetManager {
    static var assetBaseURL: URL {
        .init(filePath: NSHomeDirectory() + "/Documents/Assets/ChartPlayer")
    }
    
    static var isAvailable: Bool {
        FileManager.default.fileExists(atPath: assetBaseURL.appending(path: "Info.plist").path(percentEncoded: false))
    }
    
    static func download() async -> Bool {
        if isAvailable {
            return true
        }
        
        let archiveURL = URL(filePath: NSHomeDirectory() + "/tmp/ChartPlayerAssets.aar")
        return await withCheckedContinuation { continuation in
            AF.download("https://asset.greatdori.com/ChartPlayerAssets100.aar", to: { _, _ in
                (archiveURL, [.createIntermediateDirectories, .removePreviousFile])
            }).response { response in
                if response.error != nil {
                    continuation.resume(returning: false)
                    return
                }
                guard let readFileStream = ArchiveByteStream.fileStream(
                    path: .init(archiveURL.path(percentEncoded: false)),
                    mode: .readOnly,
                    options: [],
                    permissions: .init(rawValue: 0o644)
                ) else {
                    continuation.resume(returning: false)
                    return
                }
                defer { try? readFileStream.close() }
                guard let decompressStream = ArchiveByteStream.decompressionStream(readingFrom: readFileStream) else {
                    continuation.resume(returning: false)
                    return
                }
                defer { try? decompressStream.close() }
                guard let decodeStream = ArchiveStream.decodeStream(readingFrom: decompressStream) else {
                    continuation.resume(returning: false)
                    return
                }
                defer { try? decodeStream.close() }
                try? FileManager.default.createDirectory(at: assetBaseURL, withIntermediateDirectories: true)
                let destination = FilePath(assetBaseURL.path(percentEncoded: false))
                guard let extractStream = ArchiveStream.extractStream(
                    extractingTo: destination,
                    flags: .ignoreOperationNotPermitted
                ) else {
                    continuation.resume(returning: false)
                    return
                }
                defer { try? extractStream.close() }
                if (try? ArchiveStream.process(readingFrom: decodeStream, writingTo: extractStream)) != nil {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(returning: false)
                }
            }
        }
    }
}

#if os(macOS)
private struct ChartPlayerView: NSViewRepresentable {
    var chart: [_DoriAPI.Songs.Chart]
    var configuration: ChartPlayerConfiguration
    private let device: MTLDevice
    
    init(chart: [_DoriAPI.Songs.Chart], configuration: ChartPlayerConfiguration = .init()) {
        self.chart = chart
        self.configuration = configuration
        self.device = MTLCreateSystemDefaultDevice()!
    }
    
    func makeNSView(context: Context) -> some NSView {
        let view = MTKView()
        view.device = device
        view.delegate = context.coordinator
        view.preferredFramesPerSecond = NSScreen.main?.maximumFramesPerSecond ?? 60
        return view
    }
    func updateNSView(_ nsView: NSViewType, context: Context) {}
    func makeCoordinator() -> ChartPlayerRenderer {
        .init(device: device, chart: chart, configuration: configuration)
    }
}
#else
private struct ChartPlayerView: UIViewRepresentable {
    var chart: [_DoriAPI.Songs.Chart]
    var configuration: ChartPlayerConfiguration
    private let device: MTLDevice
    
    init(chart: [_DoriAPI.Songs.Chart], configuration: ChartPlayerConfiguration = .init()) {
        self.chart = chart
        self.configuration = configuration
        self.device = MTLCreateSystemDefaultDevice()!
    }
    
    func makeUIView(context: Context) -> some UIView {
        let view = MTKView()
        view.device = device
        view.delegate = context.coordinator
        view.preferredFramesPerSecond = UIScreen.main.maximumFramesPerSecond
        return view
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    func makeCoordinator() -> ChartPlayerRenderer {
        .init(device: device, chart: chart, configuration: configuration)
    }
}
#endif

private class ChartPlayerRenderer: NSObject, MTKViewDelegate {
    private let renderer: SKRenderer
    private let commandQueue: MTLCommandQueue
    
    init(device: any MTLDevice, chart: [_DoriAPI.Songs.Chart], configuration: ChartPlayerConfiguration) {
        self.renderer = .init(device: device)
        self.renderer.scene = ChartPlayerScene(size: .zero, chart: chart, configuration: configuration)
        self.commandQueue = device.makeCommandQueue()!
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        renderer.scene?.size = size
    }
    
    func draw(in view: MTKView) {
        renderer.update(atTime: Date.now.timeIntervalSince1970)
        if let commandBuffer = commandQueue.makeCommandBuffer() {
            if let onscreenDescriptor = view.currentRenderPassDescriptor,
               let onscreenCommandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: onscreenDescriptor) {
                renderer.render(
                    withViewport: view.bounds,
                    renderCommandEncoder: onscreenCommandEncoder,
                    renderPassDescriptor: onscreenDescriptor,
                    commandQueue: commandQueue
                )
                onscreenCommandEncoder.endEncoding()
                if let drawable = view.currentDrawable {
                    commandBuffer.present(drawable)
                }
            }
            commandBuffer.commit()
        }
    }
}

private class ChartPlayerScene: SKScene {
    let chart: [_DoriAPI.Songs.Chart]
    let tex: ChartPlayerConfiguration._TextureGroup
    
    init(size: CGSize, chart: [_DoriAPI.Songs.Chart], configuration: ChartPlayerConfiguration) {
        self.chart = chart
        self.tex = configuration.textureGroup()
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(_ currentTime: TimeInterval) {
        self.removeAllChildren()
        
        renderBackground()
    }
    
    private func renderBackground() {
        // Background tex
        let backgroundNode = SKSpriteNode(texture: tex.background)
        backgroundNode.size = .init(width: size.width, height: size.width / 4 * 3)
        backgroundNode.position = .init(x: size.width / 2, y: size.height / 2)
        addChild(backgroundNode)
        
        // Rhythm line
        let rhythmLineNode = SKSpriteNode(texture: tex.backgroundRhythmLine)
        let rhythmLineAspectRatio = rhythmLineNode.size.width / rhythmLineNode.size.height
        rhythmLineNode.size.height = size.height - (150 + 40)
        rhythmLineNode.size.width = rhythmLineNode.size.height * rhythmLineAspectRatio
        rhythmLineNode.position = .init(x: size.width / 2, y: (size.height + 100) / 2)
        addChild(rhythmLineNode)
        
        // Judge line
        let judgeLineNode = SKSpriteNode(texture: tex.gamePlayLine)
        let judgeLineAspectRatio = judgeLineNode.size.width / judgeLineNode.size.height
        judgeLineNode.size.width = rhythmLineNode.size.width * 1.5
        judgeLineNode.size.height = judgeLineNode.size.width / judgeLineAspectRatio
        judgeLineNode.position = .init(x: size.width / 2, y: 150)
        addChild(judgeLineNode)
    }
    private func renderNotes(at time: TimeInterval) {
        
    }
}

private final class ChartPlayerConfiguration: @unchecked Sendable {
    init() {}
    
    var backgroundStyle: BackgroundStyle = .skin0
    var lineStyle: LineStyle = .skin0
    var noteStyle: NoteStyle = .skin0
    var flickStyle: FlickStyle = .skin0
    
    func textureGroup() -> _TextureGroup {
        struct NoteSpriteMetadata {
            var name: String
            var rect: CGRect
            var offset: CGPoint
            var textureRect: CGRect
            var textureRectOffset: CGPoint
            
            init(json: JSON) {
                let base = json["Base"]
                self.name = base["m_Name"].stringValue
                self.rect = .init(
                    x: base["m_Rect"]["x"].doubleValue,
                    y: base["m_Rect"]["y"].doubleValue,
                    width: base["m_Rect"]["width"].doubleValue,
                    height: base["m_Rect"]["height"].doubleValue
                )
                self.offset = .init(x: base["m_Offset"]["x"].doubleValue, y: base["m_Offset"]["y"].doubleValue)
                self.textureRect = .init(
                    x: base["m_RD"]["textureRect"]["x"].doubleValue,
                    y: base["m_RD"]["textureRect"]["y"].doubleValue,
                    width: base["m_RD"]["textureRect"]["width"].doubleValue,
                    height: base["m_RD"]["textureRect"]["height"].doubleValue
                )
                self.textureRectOffset = .init(x: base["m_RD"]["textureRectOffset"]["x"].doubleValue, y: base["m_RD"]["textureRectOffset"]["y"].doubleValue)
            }
        }
        
        func fixedTextureRect(_ rect: CGRect, in texture: SKTexture) -> CGRect {
            let size = texture.size()
            return .init(x: rect.minX / size.width, y: rect.minY / size.height, width: rect.width / size.width, height: rect.height / size.height)
        }
        func directedTextures(baseName: String, metadata: [NoteSpriteMetadata], texture: SKTexture) -> [SKTexture] {
            var result: [SKTexture] = []
            for i in 0..<7 {
                let rect = metadata.first { $0.name == baseName + "_\(i)" }!.rect
                result.append(.init(rect: fixedTextureRect(rect, in: texture), in: texture))
            }
            return result
        }
        
        let baseURL = ChartPlayerAssetManager.assetBaseURL
        
        let rhythmSprites = SKTexture(image: .init(data: try! .init(contentsOf: baseURL.appending(path: noteStyle.rawValue).appending(path: "RhythmGameSprites.png")))!)
        let directionalFlickSprites = SKTexture(image: .init(data: try! .init(contentsOf: baseURL.appending(path: flickStyle.rawValue).appending(path: "DirectionalFlickSprites.png")))!)
        
        // Parse metadata
        guard let rhythmSpriteMetadata = try? JSON(data: try! Data(contentsOf: baseURL.appending(path: noteStyle.rawValue).appending(path: ".sprites"))),
              let directionalFlickSpriteMetadata = try? JSON(data: try! Data(contentsOf: baseURL.appending(path: flickStyle.rawValue).appending(path: ".sprites"))) else {
            fatalError("Failed to load sprite metadata, broken bundle?")
        }
        
        let decoder = PropertyListDecoder()
        var rhythmSpriteMeta = [NoteSpriteMetadata]()
        var directionalFlickSpriteMeta = [NoteSpriteMetadata]()
        for (_, json) in rhythmSpriteMetadata {
            rhythmSpriteMeta.append(.init(json: json))
        }
        for (_, json) in directionalFlickSpriteMetadata {
            directionalFlickSpriteMeta.append(.init(json: json))
        }
        
        return .init(
            background: .init(image: .init(data: try! .init(contentsOf: baseURL.appending(path: backgroundStyle.rawValue)))!),
            backgroundRhythmLine: .init(image: .init(data: try! .init(contentsOf: baseURL.appending(path: lineStyle.rawValue).appending(path: "bg_line_rhythm.png")))!),
            gamePlayLine: .init(image: .init(data: try! .init(contentsOf: baseURL.appending(path: lineStyle.rawValue).appending(path: "game_play_line.png")))!),
            gamePlayLineSkillAdjust: .init(image: .init(data: try! .init(contentsOf: baseURL.appending(path: lineStyle.rawValue).appending(path: "game_play_line_skill_adjust_effect.png")))!),
            normal: directedTextures(baseName: "note_normal", metadata: rhythmSpriteMeta, texture: rhythmSprites),
            long: directedTextures(baseName: "note_long", metadata: rhythmSpriteMeta, texture: rhythmSprites),
            flick: directedTextures(baseName: "note_flick", metadata: rhythmSpriteMeta, texture: rhythmSprites),
            flickTop: .init(rect: fixedTextureRect(rhythmSpriteMeta.first { $0.name == "note_flick_top" }!.rect, in: rhythmSprites), in: rhythmSprites),
            skill: directedTextures(baseName: "note_skill", metadata: rhythmSpriteMeta, texture: rhythmSprites),
            slideAmong: .init(rect: fixedTextureRect(rhythmSpriteMeta.first { $0.name == "note_slide_among" }!.rect, in: rhythmSprites), in: rhythmSprites),
            simultaneousLine: .init(image: .init(data: try! .init(contentsOf: baseURL.appending(path: noteStyle.rawValue).appending(path: "simultaneous_line.png")))!),
            flickLeft: directedTextures(baseName: "note_flick_l", metadata: directionalFlickSpriteMeta, texture: directionalFlickSprites),
            flickRight: directedTextures(baseName: "note_flick_r", metadata: directionalFlickSpriteMeta, texture: directionalFlickSprites),
            flickLeftEndpoint: .init(rect: fixedTextureRect(directionalFlickSpriteMeta.first { $0.name == "note_flick_top_l" }!.rect, in: directionalFlickSprites), in: directionalFlickSprites),
            flickRightEndpoint: .init(rect: fixedTextureRect(directionalFlickSpriteMeta.first { $0.name == "note_flick_top_r" }!.rect, in: directionalFlickSprites), in: directionalFlickSprites),
            longNoteLine: .init(image: .init(data: try! .init(contentsOf: baseURL.appending(path: noteStyle.rawValue).appending(path: "longNoteLine.png")))!),
            longNoteLine2: .init(image: .init(data: try! .init(contentsOf: baseURL.appending(path: noteStyle.rawValue).appending(path: "longNoteLine2.png")))!)
        )
    }
    
    struct _TextureGroup {
        let background: SKTexture
        let backgroundRhythmLine: SKTexture
        let gamePlayLine: SKTexture
        let gamePlayLineSkillAdjust: SKTexture
        let normal: [SKTexture]
        let long: [SKTexture]
        let flick: [SKTexture]
        let flickTop: SKTexture
        let skill: [SKTexture]
        let slideAmong: SKTexture
        let simultaneousLine: SKTexture
        let flickLeft: [SKTexture]
        let flickRight: [SKTexture]
        let flickLeftEndpoint: SKTexture
        let flickRightEndpoint: SKTexture
        let longNoteLine: SKTexture
        let longNoteLine2: SKTexture
    }
    
    enum BackgroundStyle: String {
        case skin0 = "tex/bgskin/skin00_rip/liveBG_normal.png"
        case skin0Fever = "tex/bgskin/skin00_rip/liveBG_fever.png"
        case skin2 = "tex/bgskin/skin02_rip/liveBG_normal.png"
        case skin3 = "tex/bgskin/skin03_rip/liveBG_normal.png"
        case practice = "tex/bgskin/skinpractice_rip/liveBG_normal.png"
        case skin5th = "tex/bgskin/skin_5th_rip/liveBG.png"
        case skin5thFever = "tex/bgskin/skin_5th_rip/liveBG_fever.png"
        case april2019 = "tex/bgskin/skin_april2019_rip/liveBG.png"
        case april2019Fever = "tex/bgskin/skin_april2019_rip/liveBG_fever.png"
        case april2021 = "tex/bgskin/skin_april2021_rip/liveBG.png"
        case april2021Fever = "tex/bgskin/skin_april2021_rip/liveBG_fever.png"
        case april2024 = "tex/bgskin/skin_april_2024_rip/liveBG.png"
        case april2024Fever = "tex/bgskin/skin_april_2024_rip/liveBG_fever.png"
        case bike = "tex/bgskin/skin_bike_rip/liveBG.png"
        case bikeFever = "tex/bgskin/skin_bike_rip/liveBG_fever.png"
        case cafe = "tex/bgskin/skin_cafe_rip/liveBG.png"
        case cafeFever = "tex/bgskin/skin_cafe_rip/liveBG_fever.png"
        case coin = "tex/bgskin/skin_coin_rip/liveBG.png"
        case coinFever = "tex/bgskin/skin_coin_rip/liveBG_fever.png"
        case collabo23Summer = "tex/bgskin/skin_collabo23_summer_g_rip/liveBG.png"
        case collabo23SummerFever = "tex/bgskin/skin_collabo23_summer_g_rip/liveBG_fever.png"
        case collabo23Winter = "tex/bgskin/skin_collabo23_winter_d_rip/liveBG.png"
        case collabo23WinterFever = "tex/bgskin/skin_collabo23_winter_d_rip/liveBG_fever.png"
        case collabo24Autumn = "tex/bgskin/skin_collabo24_autumn_i_rip/liveBG.png"
        case collabo24AutumnFever = "tex/bgskin/skin_collabo24_autumn_i_rip/liveBG_fever.png"
        case delta = "tex/bgskin/skin_delta_rip/liveBG.png"
        case deltaFever = "tex/bgskin/skin_delta_rip/liveBG_fever.png"
        case gbp2020 = "tex/bgskin/skin_gbp2020_rip/liveBG.png"
        case gbp2020Fever = "tex/bgskin/skin_gbp2020_rip/liveBG_fever.png"
        case maid = "tex/bgskin/skin_maid_rip/liveBG.png"
        case maidFever = "tex/bgskin/skin_maid_rip/liveBG_fever.png"
        case miku = "tex/bgskin/skin_miku_rip/liveBG.png"
        case mikuFever = "tex/bgskin/skin_miku_rip/liveBG_fever.png"
        case persona = "tex/bgskin/skin_persona_rip/liveBG.png"
        case personaFever = "tex/bgskin/skin_persona_rip/liveBG_fever.png"
        case satan = "tex/bgskin/skin_satan_rip/liveBG.png"
        case satanFever = "tex/bgskin/skin_satan_rip/liveBG_fever.png"
        case stage = "tex/bgskin/skin_stage_rip/liveBG.png"
        case stageFever = "tex/bgskin/skin_stage_rip/liveBG_fever.png"
        case witch = "tex/bgskin/skin_witch_rip/liveBG.png"
        case witchFever = "tex/bgskin/skin_witch_rip/liveBG_fever.png"
        case teamLiveFestivalComboStage = "tex/bgskin/skin_teamlivefestival_rip/ComboStage.png"
        case teamLiveFestivalLifeStage = "tex/bgskin/skin_teamlivefestival_rip/LifeStage.png"
        case teamLiveFestivalPerfectStage = "tex/bgskin/skin_teamlivefestival_rip/PerfectStage.png"
        case teamLiveFestivalFever = "tex/bgskin/skin_teamlivefestival_rip/Fever.png"
    }
    enum LineStyle: String {
        case skin0 = "tex/fieldskin/skin00_rip"
        case skin1 = "tex/fieldskin/skin01_rip"
        case skin2 = "tex/fieldskin/skin02_rip"
        case skin3 = "tex/fieldskin/skin03_rip"
        case skin4 = "tex/fieldskin/skin04_rip"
        case skin5 = "tex/fieldskin/skin05_rip"
        case skin6 = "tex/fieldskin/skin06_rip"
        case skin7 = "tex/fieldskin/skin07_rip"
        case skin8 = "tex/fieldskin/skin08_rip"
        case skin9 = "tex/fieldskin/skin09_rip"
        case skin10 = "tex/fieldskin/skin10_rip"
        case skin11 = "tex/fieldskin/skin11_rip"
        case skin12 = "tex/fieldskin/skin12_rip"
        case skin13 = "tex/fieldskin/skin13_rip"
        case skin14 = "tex/fieldskin/skin14_rip"
        case april2019 = "tex/fieldskin/skin_april2019_rip"
        case april2021 = "tex/fieldskin/skin_april2021_rip"
        case april2024 = "tex/fieldskin/skin_april_2024_rip"
        case bike = "tex/fieldskin/skin_bike_rip"
        case cafe = "tex/fieldskin/skin_cafe_rip"
        case coin = "tex/fieldskin/skin_coin_rip"
        case collabo23Summer = "tex/fieldskin/collabo23_summer_g_rip"
        case collabo24Autumn = "tex/fieldskin/skin_collabo24_autumn_i_rip"
        case delta = "tex/fieldskin/skin_delta_rip"
        case gbp2020 = "tex/fieldskin/skin_gbp2020_rip"
        case maid = "tex/fieldskin/skin_maid_rip"
        case miku = "tex/fieldskin/skin_miku_rip"
        case persona = "tex/fieldskin/skin_persona_rip"
        case satan = "tex/fieldskin/skin_satan_rip"
        case stage = "tex/fieldskin/skin_stage_rip"
        case witch = "tex/fieldskin/skin_witch_rip"
    }
    enum NoteStyle: String {
        case skin0 = "tex/noteskin/skin00_rip"
        case skin1 = "tex/noteskin/skin01_rip"
        case skin2 = "tex/noteskin/skin02_rip"
        case skin3 = "tex/noteskin/skin03_rip"
        case skin4 = "tex/noteskin/skin04_rip"
        case skin5 = "tex/noteskin/skin05_rip"
        case skin6 = "tex/noteskin/skin06_rip"
        case april2018 = "tex/noteskin/skin_april_2018_rip"
        case april2019 = "tex/noteskin/skin_april_2019_rip"
        case april2021 = "tex/noteskin/skin_april_2021_rip"
        case april2024 = "tex/noteskin/skin_april_2024_rip"
        case collabo23Summer = "tex/noteskin/collabo23_summer_g_rip"
        case collabo24Autumn = "tex/noteskin/skin_collabo24_autumn_i_rip"
        case delta = "tex/noteskin/skin_delta_rip"
        case maid = "tex/noteskin/skin_maid_rip"
        case persona = "tex/noteskin/skin_persona_rip"
        case stage = "tex/noteskin/skin_stage_rip"
    }
    enum FlickStyle: String {
        case skin0 = "tex/noteskin/directionalflickskin00_rip"
        case skin1 = "tex/noteskin/directionalflickskin01_rip"
        case skin2 = "tex/noteskin/directionalflickskin02_rip"
        case skin3 = "tex/noteskin/directionalflickskin03_rip"
        case skin4 = "tex/noteskin/directionalflickskin04_rip"
        case persona = "tex/noteskin/directionalflickskin_persona_rip"
    }
}
