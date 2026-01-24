//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsAdvanced.swift
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

import DoriKit
import SwiftUI
import SDWebImageSwiftUI

#if os(iOS)
import UIKit
#endif

struct SettingsAdvancedView: View {
    @State var isInLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    @State var thermalState = ProcessInfo.processInfo.thermalState
    var body: some View {
        Group {
//#if os(iOS)
//            List {
//                settingsAdvancedSections()
//            }
//#else
            Group {
                settingsAdvancedSections()
            }
//#endif
        }
        .navigationTitle("Settings.advanced")
        .onReceive(ProcessInfo.processInfo.publisher(for: \.isLowPowerModeEnabled)) { lowPowerMode in
            isInLowPowerMode = lowPowerMode
        }
        .onReceive(ProcessInfo.processInfo.publisher(for: \.thermalState)) { state in
            thermalState = state
        }
    }
    
    @ViewBuilder
    func settingsAdvancedSections() -> some View {
        SettingsAdvancedBannersSection(isInLowPowerMode: $isInLowPowerMode, thermalState: $thermalState)
        SettingsAdvancedImageSection(disablePowerConsumingFeatures: isInLowPowerMode || thermalState == .critical)
        SettingsAdvancedSearchSection()
        SettingsAdvancedUISection()
        SettingsAdvancedStorageSection()
    }
}

struct SettingsAdvancedBannersSection: View {
    @Binding var isInLowPowerMode: Bool
    @Binding var thermalState: ProcessInfo.ThermalState
    var body: some View {
        if isInLowPowerMode || thermalState == .critical {
            Section(content: {
                if isInLowPowerMode {
                    Label("Settings.advanced.banners.low-power", systemImage: "battery.25percent")
                        .bold()
                        .foregroundStyle(.yellow)
                }
                if thermalState == .critical {
                    Label("Settings.advanced.banners.power-saving.high-temperature", systemImage: "thermometer.sun")
                        .bold()
                        .foregroundStyle(.yellow)
                }
            }, footer: {
                Text("Settings.advanced.banners.disabling-features.description")
            })
        } else {
            EmptyView()
        }
    }
}

struct SettingsAdvancedImageSection: View {
    @AppStorage("Adv_UseImageUpscaler") var useImageUpscaler = false
    @AppStorage("Adv_PreferSystemVisionModel") var preferSystemVisionModel = false
    var disablePowerConsumingFeatures: Bool
    var body: some View {
        Section {
            Toggle(isOn: $preferSystemVisionModel) {
                VStack(alignment: .leading) {
                    Text("Settings.advanced.image.subject-prefer-system-model")
                    Text("Settings.advanced.image.subject-prefer-system-model.description")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            }
            if #available(iOS 26.0, macOS 26.0, *) {
                if !disablePowerConsumingFeatures {
                    Toggle(isOn: $useImageUpscaler) {
                        VStack(alignment: .leading) {
                            Text("Settings.advanced.image.use-super-resolution")
                            Text("Settings.advanced.image.use-super-resolution.description")
                                .foregroundStyle(.secondary)
                                .font(.footnote)
                        }
                    }
                } else {
                    Toggle(isOn: .constant(false)) {
                        VStack(alignment: .leading) {
                            Text("Settings.advanced.image.use-super-resolution")
                            Text("Settings.advanced.image.use-super-resolution.description")
                                .font(.footnote)
                        }.foregroundStyle(.secondary)
                    }
                    .disabled(true)
                }
            }
        } header: {
            Text("Settings.advanced.image")
        }
        
    }
}

struct SettingsAdvancedSearchSection: View {
    @AppStorage("Adv_InfoUseFuzzySearch") var infoUseFuzzySearch = false
    var body: some View {
        Section {
            Toggle(isOn: $infoUseFuzzySearch) {
                VStack(alignment: .leading) {
                    Text("Settings.advanced.search.info-fuzzy-search")
                    Text("Settings.advanced.search.info-fuzzy-search.description")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            }
        } header: {
            Text("Settings.advanced.search")
        }
    }
}

struct SettingsAdvancedUISection: View {
    var body: some View {
        Section {
            Toggle(isOn: .init(get: { AppFlag.CharacterRandomCardsContainAllCards }, set: { AppFlag.set($0, forKey: "CharacterRandomCardsContainAllCards") }), label: {
                VStack(alignment: .leading) {
                    Text("Settings.advanced.ui.random-card-contains-all-card")
                    Text("Settings.advanced.ui.random-card-contains-all-card.description")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
            })
        } header: {
            Text("Settings.advanced.ui")
        }
    }
}

struct SettingsAdvancedStorageSection: View {
    @State private var cacheSize = ""
    @State private var isClearCacheAlertPresented = false
    var body: some View {
        Section {
            HStack {
                VStack(alignment: .leading) {
                    Text("Settings.advanced.storage.clear-cache")
                    Text("Settings.advanced.storage.clear-cache.description")
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                }
                Spacer()
                Text(cacheSize)
                    .foregroundStyle(.secondary)
                Button(role: .destructive, action: {
                    isClearCacheAlertPresented = true
                }, label: {
                    Text("Settings.advanced.storage.clear-cache.clear")
                })
            }
            .alert("Settings.advanced.storage.clear-cache.alert.title", isPresented: $isClearCacheAlertPresented) {
                Button(role: .destructive, action: {
                    if let contents = try? FileManager.default.contentsOfDirectory(atPath: NSTemporaryDirectory()) {
                        for content in contents {
                            try? FileManager.default.removeItem(atPath: NSTemporaryDirectory() + "/\(content)")
                        }
                    }
                    if let contents = try? FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Library/Caches/com.hackemist.SDImageCache/default") {
                        for content in contents {
                            try? FileManager.default.removeItem(atPath: NSHomeDirectory() + "/Library/Caches/com.hackemist.SDImageCache/default/\(content)")
                        }
                    }
                    DoriCache.invalidateAll()
                    URLCache.shared.removeAllCachedResponses()
                    updateCacheSize()
                }, label: {
                    Text("Settings.advanced.storage.clear-cache.alert.action.confirm")
                })
            } message: {
                Text("Settings.advanced.storage.clear-cache.alert.message")
            }
            .onAppear {
                updateCacheSize()
            }
        } header: {
            Text("Settings.advanced.storage")
        }
    }
    
    func updateCacheSize() {
        let metaCacheSize = URL(
            filePath: NSHomeDirectory() + "/Library/Caches/"
        ).directorySize(including: /DoriKit_.+\.cache/)
        let otherCacheSize = URL(filePath: NSTemporaryDirectory()).directorySize()
        let totalCacheSize = metaCacheSize + otherCacheSize
        cacheSize = ByteCountFormatter().string(fromByteCount: totalCacheSize)
    }
}

func resetAllAdvancedSettings(showBannerAtHome: Bool = true) {
    if let _data = try? Data(contentsOf: URL(filePath: NSHomeDirectory() + "/Library/Preferences/com.memz233.Greatdori.plist")),
       let serialization = try? PropertyListSerialization.propertyList(from: _data, format: nil) as? [String: Any] {
        for key in serialization.keys where key.hasPrefix("Adv_") {
            UserDefaults.standard.removeObject(forKey: key)
        }
        if showBannerAtHome {
            UserDefaults.standard.set(true, forKey: "AdvancedSettingsHaveReset")
        }
    }
}
