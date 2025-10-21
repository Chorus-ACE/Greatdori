//===---*- Greatdori! -*---------------------------------------------------===//
//
// ChartSimulator.swift
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

import Metal
import System
import DoriKit
import SwiftUI
import MetalKit
import SpriteKit
import Alamofire
import AppleArchive

struct ChartSimulatorView: View {
    @State private var selectedSong: PreviewSong?
    @State private var isSongSelectorPresented = false
    @State private var selectedDifficulty: DoriAPI.Song.DifficultyType = .easy
    @State private var chart: [DoriAPI.Song.Chart]?
    @State private var chartScenes: [ChartViewerScene] = []
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
                        }
                    }
                    CustomGroupBox(cornerRadius: 20) {
                        ScrollView(.horizontal) {
                            HStack(spacing: 0) {
                                ForEach(chartScenes, id: \.self) { scene in
                                    SpriteView(scene: scene)
                                        .frame(width: 240, height: 500)
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
    }
    
    func loadChart() {
        guard let selectedSong else { return }
        Task {
            chart = await DoriAPI.Song.charts(of: selectedSong.id, in: selectedDifficulty)
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
    let chart: [DoriAPI.Song.Chart]
    let splitIndex: Int
    let configuration = ChartViewerConfiguration()
    
    init(size: CGSize, chart: [DoriAPI.Song.Chart], splitIndex: Int) {
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
            chart: [DoriAPI.Song.Chart],
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

private func chartLastBeat(_ chart: [DoriAPI.Song.Chart]) -> Double {
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

private class ChartPlayerRenderer: NSObject, MTKViewDelegate {
    
    private var drawableSize = CGSize.zero
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        drawableSize = size
    }
    
    func draw(in view: MTKView) {
        
    }
}

private class ChartPlayerScene: SKScene {
    init(size: CGSize, chart: [DoriAPI.Song.Chart]) {
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func update(_ currentTime: TimeInterval) {
        self.removeAllChildren()
        
        
    }
}
