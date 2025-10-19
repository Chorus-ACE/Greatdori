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
    var body: some View {
        #if os(iOS)
        List {
            SettingsAdvancedImageSection()
        }
        .navigationTitle("Settings.advanced")
        #else
        Group {
            SettingsAdvancedImageSection()
        }
        .navigationTitle("Settings.advanced")
        #endif
    }
    
    struct SettingsAdvancedImageSection: View {
        @AppStorage("Adv_UseImageUpscaler") var useImageUpscaler = false
        @AppStorage("Adv_PreferSystemVisionModel") var preferSystemVisionModel = false
        @State var isInLowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled
        @State var thermalState = ProcessInfo.processInfo.thermalState
        var body: some View {
            Section {
                if #available(iOS 26.0, macOS 26.0, *) {
                    Toggle(isOn: $useImageUpscaler) { // TODO: Show a turned off toggle when the toggle is disabled.
                                                      // TODO: (no need to actually change the `AppStorage` value)
                        VStack(alignment: .leading) {
                            Text("提高图像分辨率")
                            Group {
                                Text("对于一些分辨率过低的图像，使用神经网络提高分辨率。")
                                if isInLowPowerMode {
                                    Text("提高图像分辨率在低电量模式启用时不可用。")
                                }
                                if thermalState == .critical {
                                    Text("需要降温以使用提高图像分辨率")
                                }
                            }
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                        }
                    }
                    .disabled(isInLowPowerMode || thermalState == .critical)
                    .onReceive(ProcessInfo.processInfo.publisher(for: \.isLowPowerModeEnabled)) { lowPowerMode in
                        isInLowPowerMode = lowPowerMode
                    }
                    .onReceive(ProcessInfo.processInfo.publisher(for: \.thermalState)) { state in
                        thermalState = state
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
