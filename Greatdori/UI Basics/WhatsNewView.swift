//===---*- Greatdori! -*---------------------------------------------------===//
//
// WhatsNewView.swift
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


struct WhatsNewView: View {
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    Group {
                        if showWhatsNewVersionAsRecentUpdate {
                            Text("Whats-new.title.recent")
                        } else if AppVersion.readLastVersion()?.differenceLevel(between: AppVersion.currentVersion()) == .build {
                            Text("Whats-new.title.build.\(AppVersion.currentVersion().build ?? -1)")
                        } else {
                            Text("Whats-new.title.version.\(AppVersion.currentVersion().getReadableVersionNumber(shortened: true))")
                        }
                    }
                    .font(.largeTitle)
                    .bold()
                    
                    Rectangle()
                        .opacity(0)
                        .frame(width: 0, height: 5)
                    
                    ForEach(whatsNew, id: \.self) { item in
                        HStack {
                            Image(_internalSystemName: item.icon)
                                .foregroundStyle(.accent)
                                .font(.title)
                                .frame(width: 40)
                            VStack(alignment: .leading) {
                                Text(item.localizedTitle() ?? "\(item.item)")
                                    .bold()
                                    .font(.title3)
                                Text(item.localizedDescription() ?? "\(item.icon)")
                                    .foregroundStyle(.secondary)
                                    .font(.title3)
                            }
                        }
                        Rectangle()
                            .opacity(0)
                            .frame(width: 0, height: 5)
                    }
                    
                    Text("Whats-new.testflight-note")
                    
                    Spacer()
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction, content: {
                    Button(action: {
                        dismiss()
                    }, label: {
                        Label("Whats-new.done", systemImage: "checkmark")
                    })
                    .wrapIf(isMACOS, in: {
                        $0.labelStyle(.titleOnly)
                    }, else: {
                        $0.labelStyle(.iconOnly)
                    })
                })
            }
        }
        .onDisappear {
            AppVersion.updateLastVersion()
            UserDefaults.standard.set(stableHashOfWhatsNew(), forKey: "LastSeenWhatsNewHash")
        }
    }
}

struct AppVersion: Hashable, Comparable, Equatable {
    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        if lhs.major < rhs.major {
            return true
        } else if lhs.minor < rhs.minor {
            return true
        } else if lhs.patch < rhs.patch {
            return true
        } else if lhs.build ?? 1 < rhs.build ?? 1 {
            return true
        } else {
            return false
        }
    }
    
    var major: Int
    var minor: Int
    var patch: Int
    var build: Int?
    
    init(major: Int, minor: Int, patch: Int, build: Int?) {
        self.major = major
        self.minor = minor
        self.patch = patch
        self.build = build
    }
    
    init(versionNumber: String) {
        let sections: [Int?] = versionNumber.components(separatedBy: ".").map { Int($0) }
        self.major = sections.access(0)?.flatMap({ $0 }) ?? 0
        self.minor = sections.access(1)?.flatMap({ $0 }) ?? 0
        self.patch = sections.access(2)?.flatMap({ $0 }) ?? 0
        self.build = extractTrailingNumber(in: versionNumber) ?? sections.access(3)?.flatMap({ $0 }) ?? 0
        
        
        func extractTrailingNumber(in string: String) -> Int? {
            let pattern = #"\((\d+)\)$"#
            let regex = try! NSRegularExpression(pattern: pattern)
            
            guard let match = regex.firstMatch(
                in: string,
                range: NSRange(string.startIndex..., in: string)
            ) else {
                return nil
            }
            
            let range = match.range(at: 1)
            guard let swiftRange = Range(range, in: string) else {
                return nil
            }
            
            return Int(string[swiftRange])
        }
    }
    
    func getReadableVersionNumber(shortened: Bool = false) -> String {
        if !shortened, let build {
            return "\(major).\(minor).\(patch) (\(build))"
        } else {
            return "\(major).\(minor)"
        }
    }
    
    static func currentVersion() -> AppVersion {
        let versionNumber = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        var version = AppVersion(versionNumber: versionNumber ?? "0.0.0")
        version.build = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")
        return version
    }
    
    static func readLastVersion() -> AppVersion? {
        AppVersion(versionNumber: UserDefaults.standard.string(forKey: "LastAppVersion") ?? "")
         
    }
    
    static func updateLastVersion(as version: AppVersion = currentVersion()) {
        UserDefaults.standard.set(version.getReadableVersionNumber(), forKey: "LastAppVersion")
    }
    
    static func blank() -> AppVersion {
        AppVersion(major: 0, minor: 0, patch: 0, build: nil)
    }
    
    static func appHadUpdated(ignoreBuildNumber: Bool = true) -> Bool? {
        if let lastVersion = AppVersion.readLastVersion() {
            return AppVersion.currentVersion().dropBuildNumber(active: ignoreBuildNumber) > lastVersion.dropBuildNumber(active: ignoreBuildNumber)
        } else {
            return nil
        }
    }
    
    func dropBuildNumber(active: Bool = true) -> AppVersion {
        return AppVersion(major: self.major, minor: self.minor, patch: self.patch, build: active ? nil : self.build)
    }
    
    func differenceLevel(between candidate: AppVersion) -> AppUpdateDifferenceLevel {
        if self.major != candidate.major {
            return .major
        } else if self.minor != candidate.minor {
            return .minor
        } else if self.patch != candidate.patch {
            return .patch
        } else if self.build != candidate.build {
            return .build
        } else {
            return .nashi
        }
    }
    
    enum AppUpdateDifferenceLevel {
        case major
        case minor
        case patch
        case build
        case nashi // Avoid using `.none` just becuz I'm lazy
    }
}

struct AppUpdateItem: Hashable {
    var item: String
    var icon: String
    
    func getLocalizedText(_ lang: Locale.Language = Locale.current.language) -> (String, String)? {
        if lang.languageCode == .chinese {
            if lang.script == .hanTraditional, let matchedItem = whatsNew_ZH_HANT[self.item] {
                return matchedItem
            }
            
            if let matchedItem = whatsNew_ZH_HANS[self.item] {
                return matchedItem
            }
        } else {
            return whatsNew_EN[self.item]
        }
        return nil
    }
    
    func localizedTitle(_ lang: Locale.Language = Locale.current.language) -> String? {
        return self.getLocalizedText(lang)?.0
    }
    
    func localizedDescription(_ lang: Locale.Language = Locale.current.language) -> String? {
        return self.getLocalizedText(lang)?.1
    }
}


let whatsNew: [AppUpdateItem] = [
    AppUpdateItem(item: "account", icon: "person.crop.circle"),
    AppUpdateItem(item: "calculator", icon: "calculator"),
    AppUpdateItem(item: "station", icon: "flag.2.crossed")
]

let whatsNew_EN: [String: (String, String)] = [
    "account": ("Account System", "Login to your Bestdori and BandoriStation accounts to get the best from these platforms."),
    "calculator": ("Event Calculator", "Calculate gameplay time, used flames, event points and more with Event Calculator."),
    "station": ("Multi-Live Finder", "Find multiplayer gameplays and joined with others on BandoriStation."),
]
let whatsNew_ZH_HANS: [String: (String, String)] = [
    "account": ("账户系统", "登录至你的Bestdori和BandoriStation账户以获得最佳体验。"),
    "calculator": ("活动PT计算器", "用活动PT计算器计算游戏时间、火、活动点数和更多信息。"),
    "station": ("车站", "在Bandori车站中寻找协力并与他人拼车。"),
]

let whatsNew_ZH_HANT: [String: (String, String)] = [:]

let showWhatsNewVersionAsRecentUpdate = true

func stableHashOfWhatsNew() -> Int {
    var hasher = StableHasher(seed: 0x3344aa)
    // See the conformance to Hashable in Array.swift in stdlib
    hasher.combine(whatsNew.count) // discriminator
    for element in whatsNew {
//        hasher.combine(element.title.key)
        hasher.combine(element.item)
        hasher.combine(element.icon)
//        hasher.combine(element.description.key)
    }
    return hasher.finalize()
}
