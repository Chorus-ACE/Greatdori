//===---*- Greatdori! -*---------------------------------------------------===//
//
// GreatdoriApp.swift
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

import SwiftUI
import DoriKit
import SDWebImage
import SDWebImageSVGCoder

@main
struct GreatdoriWatchApp: App {
    @WKApplicationDelegateAdaptor var appDelegate: AppDelegate
    @Environment(\.locale) var defaultLocale
    @AppStorage("AppLanguage") var appLanguage = ""
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, appLanguage.isEmpty ? defaultLocale : Locale(identifier: appLanguage))
                .typesettingLanguage(.init(identifier: appLanguage), isEnabled: !appLanguage.isEmpty)
        }
    }
}

class AppDelegate: NSObject, WKApplicationDelegate {
    @Environment(\.locale) var locale
    @AppStorage("IsFirstLaunch") var isFirstLaunch = true
    
    func applicationDidFinishLaunching() {
        SDImageCodersManager.shared.addCoder(SDImageSVGCoder.shared)
        
        if isFirstLaunch {
            DoriLocale.primaryLocale = switch locale.language {
            case let x where x.hasCommonParent(with: .init(identifier: "ja-JP")): .jp
            case let x where x.hasCommonParent(with: .init(identifier: "en-US")): .en
            case let x where x.isEquivalent(to: .init(identifier: "zh-TW")): .tw
            case let x where x.hasCommonParent(with: .init(identifier: "zh-CN")): .cn
            case let x where x.hasCommonParent(with: .init(identifier: "ko-KO")): .kr
            default: .jp
            }
            isFirstLaunch = false
        }
        
        // Don't say lazy
        _ = NetworkMonitor.shared
    }
}
