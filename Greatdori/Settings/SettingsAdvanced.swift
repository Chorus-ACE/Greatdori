//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsAdvanced.swift
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

import SwiftUI
import SDWebImageSwiftUI

#if os(iOS)
import UIKit
#endif

struct SettingsAdvancedView: View {
    @State var isInLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
    @State var thermalState = ProcessInfo.processInfo.thermalState
    var body: some View {
#if os(iOS)
            List {
                SettingsAdvancedBannersSection(isInLowPowerMode: $isInLowPowerMode, thermalState: $thermalState)
                SettingsAdvancedImageSection(energyCosumptionReductionIsRequired: isInLowPowerMode || thermalState == .critical)
            }
            .navigationTitle("Settings.advanced")
            .onReceive(ProcessInfo.processInfo.publisher(for: \.isLowPowerModeEnabled)) { lowPowerMode in
                isInLowPowerMode = lowPowerMode
            }
            .onReceive(ProcessInfo.processInfo.publisher(for: \.thermalState)) { state in
                thermalState = state
            }
#else
            Group {
                SettingsAdvancedBannersSection(isInLowPowerMode: $isInLowPowerMode, thermalState: $thermalState)
                SettingsAdvancedImageSection(energyCosumptionReductionIsRequired: isInLowPowerMode || thermalState == .critical)
            }
            .navigationTitle("Settings.advanced")
            .onReceive(ProcessInfo.processInfo.publisher(for: \.isLowPowerModeEnabled)) { lowPowerMode in
                isInLowPowerMode = lowPowerMode
            }
            .onReceive(ProcessInfo.processInfo.publisher(for: \.thermalState)) { state in
                thermalState = state
            }
#endif
    }
    struct SettingsAdvancedBannersSection: View {
        @Binding var isInLowPowerMode: Bool
        @Binding var thermalState: ProcessInfo.ThermalState
        var body: some View {
            if isInLowPowerMode || thermalState == .critical {
                Section {
                    Banner(isPresented: $isInLowPowerMode) {
                        Image(systemName: "battery.25percent")
                        VStack(alignment: .leading) {
                            Text("Settings.advanced.banners.low-power")
                        }
                    }
                    .listRowBackground(Color.clear)
                    if thermalState == .critical {
                        Banner {
                            Image(systemName: "thermometer.sun")
                            VStack(alignment: .leading) {
                                Text("Settings.advanced.banners.high-temperature")
                            }
                        }
                        .listRowBackground(Color.clear)
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                EmptyView()
            }
        }
    }
    
    struct SettingsAdvancedImageSection: View {
        @AppStorage("Adv_UseImageUpscaler") var useImageUpscaler = false
        @AppStorage("Adv_PreferSystemVisionModel") var preferSystemVisionModel = false
        var energyCosumptionReductionIsRequired: Bool
        var body: some View {
            Section {
                if #available(iOS 26.0, macOS 26.0, *) {
                    if !energyCosumptionReductionIsRequired {
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
                                    .foregroundStyle(.secondary)
                                    .font(.footnote)
                            }
                        }
                        .disabled(true)
                    }
                }
                Toggle(isOn: $preferSystemVisionModel) {
                    VStack(alignment: .leading) {
                        Text("Settings.advanced.image.subject-prefer-system-model")
                        Text("Settings.advanced.image.subject-prefer-system-model.description")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    }
                }
            } header: {
                Text("Settings.advanced.image")
            }
            
        }
    }
}

func resetAllAdvancedSettings() {
    if let _data = try? Data(contentsOf: URL(filePath: NSHomeDirectory() + "/Library/Preferences/com.memz233.Greatdori.plist")),
       let serialization = try? PropertyListSerialization.propertyList(from: _data, format: nil) as? [String: Any] {
        for key in serialization.keys where key.hasPrefix("Adv_") {
            UserDefaults.standard.removeObject(forKey: key)
        }
        UserDefaults.standard.set(true, forKey: "AdvancedSettingsHaveReset")
    }
}
