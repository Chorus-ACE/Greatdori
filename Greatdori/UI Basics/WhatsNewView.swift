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
                            Image(systemName: item.icon)
                                .foregroundStyle(.accent)
                                .font(.title)
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .bold()
                                    .font(.title3)
                                Text(item.description)
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
    var title: LocalizedStringResource
    var icon: String
    var description: LocalizedStringResource
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title.key)
        hasher.combine(icon)
        hasher.combine(description.key)
    }
}

let whatsNew: [AppUpdateItem] = [
    AppUpdateItem(title: "Whats-new.item.rewards", icon: "gift", description: "Whats-new.item.rewards.desc"),
    AppUpdateItem(title: "Whats-new.item.localization", icon: "globe", description: "Whats-new.item.localization.desc"),
    AppUpdateItem(title: "Whats-new.item.asset-explorer", icon: "folder", description: "Whats-new.item.asset-explorer.desc"),
    AppUpdateItem(title: "Whats-new.item.shazam", icon: "shazam.logo", description: "Whats-new.item.shazam.desc"),
]

//let whatsNewItemVersion: AppVersion? = AppVersion(major: 1, minor: 1, patch: 0, build: nil)
let showWhatsNewVersionAsRecentUpdate = true

func stableHashOfWhatsNew() -> Int {
    // [251222] I really appologize for having a more prior task than Greatdori.
    return 0
}
