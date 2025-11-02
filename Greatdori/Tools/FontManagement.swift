//===---*- Greatdori! -*---------------------------------------------------===//
//
// FontManagement.swift
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

/*
import Combine
import CoreText
import Foundation
import SwiftUI
#if os(iOS)
import UIKit
#endif


@MainActor
final class FontManager: ObservableObject {
    static let shared = FontManager()
    
    @Published private(set) var loadedFonts: Set<String> = []
    private let cacheDirectory: URL
    
    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = caches.appendingPathComponent("DownloadedFonts", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func loadFont(named fontName: String, from remoteURL: URL) async throws {
        if loadedFonts.contains(fontName) { return }
        
        let localURL = cacheDirectory.appendingPathComponent(remoteURL.lastPathComponent)
        if !FileManager.default.fileExists(atPath: localURL.path) {
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            try data.write(to: localURL)
        }
        
        try registerFont(at: localURL)
        loadedFonts.insert(fontName)
    }
    
    /// 使用新的 CoreText API 注册字体
    private func registerFont(at url: URL) throws {
        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        if !success {
            throw error?.takeUnretainedValue() ?? NSError(domain: "FontError", code: -1)
        }
    }
    
    /// 启动时自动重新注册缓存字体
    func preloadCachedFonts() {
        let fontFiles = (try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
        for url in fontFiles where ["ttf", "otf"].contains(url.pathExtension.lowercased()) {
            try? registerFont(at: url)
        }
    }
    
    func detectFontName(from url: URL) -> String? {
        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let descriptor = descriptors.first
        else { return nil }
        let name = CTFontDescriptorCopyAttribute(descriptor, kCTFontNameAttribute) as? String
        return name
    }
}

*/

/*
 @MainActor
final class FontManager: ObservableObject {
    static let shared = FontManager()
    
    @Published private(set) var loadedFonts: Set<String> = []
    private let cacheDirectory: URL
    
    private init() {
        // macOS 与 iOS 都通用的缓存路径
#if os(macOS)
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
#else
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
#endif
        
        cacheDirectory = caches.appendingPathComponent("DownloadedFonts", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func loadFont(named fontName: String, from remoteURL: URL) async throws {
        if loadedFonts.contains(fontName) { return }
        
        let localURL = cacheDirectory.appendingPathComponent(remoteURL.lastPathComponent)
        let fontData: Data
        
        if FileManager.default.fileExists(atPath: localURL.path) {
            fontData = try Data(contentsOf: localURL)
        } else {
            let (downloadedData, _) = try await URLSession.shared.data(from: remoteURL)
            try downloadedData.write(to: localURL)
            fontData = downloadedData
        }
        
        try registerFont(data: fontData)
        loadedFonts.insert(fontName)
    }
    
    private func registerFont(data: Data) throws {
        guard let provider = CGDataProvider(data: data as CFData),
              let cgFont = CGFont(provider)
        else {
            throw NSError(domain: "FontError", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid font data"])
        }
        
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterGraphicsFont(cgFont, &error) {
            throw error?.takeUnretainedValue() ?? NSError(domain: "FontError", code: -2)
        }
    }
}

struct DynamicFont: ViewModifier {
    @ObservedObject private var fontManager = FontManager.shared
    
    let fontName: String
    let url: URL
    let size: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.custom(fontName, size: size))
            .task {
                try? await fontManager.loadFont(named: fontName, from: url)
            }
    }
}

extension View {
    func dynamicFont(_ name: String, url: URL, size: CGFloat) -> some View {
        modifier(DynamicFont(fontName: name, url: url, size: size))
    }
}

*/
