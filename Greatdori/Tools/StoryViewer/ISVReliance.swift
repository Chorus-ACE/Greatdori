//===---*- Greatdori! -*---------------------------------------------------===//
//
// ISVReliance.swift
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

import Combine
import DoriKit
import Foundation
import SwiftUI

// MARK: class ReferenceCountingContainer
final class ReferenceCountingContainer: @unchecked Sendable, ObservableObject {
    @safe nonisolated(unsafe) static var all: [UUID: [ReferenceCountingContainer]] = [:]
    
    @Published var _count: Int = 0
    @Published var _tappingActionCount: Int = 0
    var observers: [UUID: AnyCancellable] = [:]
    
    let parentID: UUID?
    
    init(parentID: UUID?) {
        self.parentID = parentID
        
        if let parentID {
            Self.all.updateValue(
                (Self.all[parentID] ?? []) + [self],
                forKey: parentID
            )
        }
    }
    
    deinit {
        if let parentID {
            Self.all.updateValue(
                (Self.all[parentID] ?? []).filter { $0 !== self },
                forKey: parentID
            )
        }
    }
    
    private let countLock = NSLock()
    var count: Int {
        get {
            assert(parentID != nil, "Attempting to access an invalid ReferenceCountingContainer")
            return countLock.withLock {
                _count
            }
        }
        set {
            assert(parentID != nil, "Attempting to access an invalid ReferenceCountingContainer")
            countLock.withLock {
                _count = max(newValue, 0)
            }
        }
    }
    private let tappingCountLock = NSLock()
    var tappingActionCount: Int {
        get {
            assert(parentID != nil, "Attempting to access an invalid ReferenceCountingContainer")
            return tappingCountLock.withLock {
                _tappingActionCount
            }
        }
        set {
            assert(parentID != nil, "Attempting to access an invalid ReferenceCountingContainer")
            tappingCountLock.withLock {
                _tappingActionCount = max(newValue, 0)
            }
        }
    }
}

// MARK: struct LayoutState
struct LayoutState: Equatable {
    var characterID: Int
    var position: StoryIR.StepAction.Position
    var motion: String = ""
    var expression: String = ""
}

// MARK: struct TalkData
struct TalkData: Hashable {
    var text: String
    var characterIDs: [Int]
    var characterNames: [String]
    var voicePath: String?
}

// MARK: struct ShakeScreenModifier: ViewModifier
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

// MARK: struct StrokeTextModifier: ViewModifier
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

// MARK: func fontName -> String
func fontName(in locale: DoriLocale) -> String {
    return UserDefaults.standard.string(forKey: "StoryViewerFont\(locale.rawValue.uppercased())") ?? storyViewerDefaultFont[locale] ?? ".AppleSystemUIFont"
}

// MARK: func resolveURL -> URL
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

// MARK: extension EnvironmentValues
extension EnvironmentValues {
    @Entry var _layoutViewVisible: Bool = false
}
