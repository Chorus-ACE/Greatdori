//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsFontsView.swift
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
import CoreText
import SwiftUI
import UniformTypeIdentifiers

struct SettingsFontsView: View {
    var body: some View {
        if isMACOS {
            SettingsFontsViewMain()
        } else {
            Section("Settings.fonts") {
                NavigationLink(destination: {
                    SettingsFontsViewMain()
                }, label: {
                    Text("Settings.fonts")
                })
            }
        }
    }
}

struct SettingsFontsViewMain: View {
    @StateObject private var fontManager = FontManager.shared
    
    @State var newFontSheetIsDisplaying = false
    @State var newFontOnlineURL = ""
    @State var newFontLocalURL: URL?
    @State var newFontAddFailureAlertIsDisplaying = false
    @State var newFontAddFailureReason = ""
    @State var newFontIsAdding = false
    @State var newFontIsOnline = true
    @State var newFontFileImporterIsDisplaying = false
    
    @State var fontInspectorSheetIsDisplaying = false
    @State var fontInspectorTarget = ""
    
    var body: some View {
        Form {
//            Section("Settings.font.built-in") {
//                
//            }
            Section("Settings.fonts.installed") {
                if !fontManager.loadedFonts.isEmpty {
                    ForEach(fontManager.loadedFonts, id: \.self) { item in
                        Button(action: {
                            fontInspectorTarget = item
                            fontInspectorSheetIsDisplaying = true
                        }, label: {
                            HStack {
                                Text(item)
                                    .font(.custom(item, size: 18))
                                Spacer()
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                            }
                        })
                        .contentShape(Rectangle())
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(role: .destructive, action: {
                                fontManager.removeFont(named: item)
                            }, label: {
                                Label("Settings.fonts.installed.remove", systemImage: "trash")
                            })
                        }
                    }
                } else {
                    Text("Settings.fonts.installed.none").foregroundStyle(.secondary)
                }
                if !isMACOS {
                    Button(action: {
                        newFontOnlineURL = ""
                        newFontSheetIsDisplaying = true
                    }, label: {
                        Label("Settings.fonts.new", systemImage: "plus")
                    })
                }
            }
        }
        .navigationTitle("Settings.fonts")
        .formStyle(.grouped)
        .toolbar {
            if isMACOS {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {
                        newFontOnlineURL = ""
                        newFontSheetIsDisplaying = true
                    }, label: {
                        Label("Settings.fonts.new", systemImage: "plus")
                    })
                }
            }
        }
        .sheet(isPresented: $newFontSheetIsDisplaying) {
            NavigationStack {
                Form {
                    Section(content: {
                        HStack {
                            Text("Settings.fonts.new.type")
                                .bold()
                            Spacer()
                            Picker("", selection: $newFontIsOnline, content: {
                                Text("Settings.fonts.new.type.online")
                                    .tag(true)
                                Text("Settings.fonts.new.typye.local")
                                    .tag(false)
                            })
                            .labelsHidden()
                        }
                        if newFontIsOnline {
                            HStack {
                                Text("Settings.fonts.new.url")
                                    .bold()
                                Spacer()
                                TextField("", text: $newFontOnlineURL, prompt: Text(verbatim: "example.com/font.ttf"))
                                    .lineLimit(1)
                                    .multilineTextAlignment(.trailing)
                                    .labelsHidden()
                            }
                        } else {
                            HStack {
                                Text("Settings.fonts.new.file")
                                    .bold()
                                Spacer()
                                Button(action: {
                                    newFontFileImporterIsDisplaying = true
                                }, label: {
                                    if let lastPathComponent = newFontLocalURL?.lastPathComponent {
                                        Text(lastPathComponent)
                                    } else {
                                        Text("Settings.fonts.new.select-file")
                                    }
                                })
                            }
                        }
                    }, footer: {
                        Text("Settings.fonts.new.footer")
                    })
                }
                .wrapIf(!isMACOS, in: { content in
                    content.navigationTitle("Settings.fonts.new")
                })
                .formStyle(.grouped)
                .toolbar {
                    if isMACOS || !newFontIsAdding {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(action: {
                                newFontIsAdding = true
                                let url = newFontIsOnline ? URL(string: newFontOnlineURL)! : newFontLocalURL!
                                Task {
                                    do {
                                        if newFontIsOnline {
                                            try await fontManager.addFont(from: url)
                                        } else {
                                            try fontManager.addFont(fromLocal: url)
                                        }
                                        newFontIsAdding = false
                                        newFontSheetIsDisplaying = false
                                    } catch {
                                        newFontIsAdding = false
                                        newFontAddFailureReason = error.localizedDescription
                                        newFontAddFailureAlertIsDisplaying = true
                                    }
                                }
                            }, label: {
                                Label("Settings.fonts.new.install", systemImage: "checkmark")
                                    .wrapIf(isMACOS, in: {
                                        $0.labelStyle(.titleOnly)
                                    }, else: {
                                        $0.labelStyle(.iconOnly)
                                    })
                            })
                            .disabled(newFontIsOnline && URL(string: newFontOnlineURL) == nil)
                            .disabled(!newFontIsOnline && newFontLocalURL == nil)
                        }
                    }
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            newFontSheetIsDisplaying = false
                        }, label: {
                            Label("Settings.fonts.new.cancel", systemImage: "xmark")
                                .wrapIf(isMACOS, in: {
                                    $0.labelStyle(.titleOnly)
                                }, else: {
                                    $0.labelStyle(.iconOnly)
                                })
                        })
                    }
                    ToolbarItem(placement: .destructiveAction) {
                        if newFontIsAdding {
                            if isMACOS {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.5)
                                    Text("Settings.fonts.new.installing")
                                }
                            } else {
                                ProgressView()
                            }
                        }
                    }
                }
                .alert("Settings.fonts.new.error", isPresented: $newFontAddFailureAlertIsDisplaying, actions: {}, message: {
                    Text(newFontAddFailureReason)
                })
                .fileImporter(isPresented: $newFontFileImporterIsDisplaying, allowedContentTypes: [.font], allowsMultipleSelection: false) { result in
                    switch result {
                    case .success(let urls):
                        newFontLocalURL = urls.first!
                    case .failure( _):
                        doNothing()
                    }
                }
            }
        }
        .sheet(isPresented: $fontInspectorSheetIsDisplaying) {
            SettingsFontsDetail(fontName: fontInspectorTarget)
        }
    }
}


struct SettingsFontsDetail: View {
    @StateObject private var fontManager = FontManager.shared
    var fontName: String
    @State var fontInfo: FontInfo? = nil
    @State var fontSupportingLanguagesText: String = ""
    @State var showCountsInsteadOfAllItemsForLanguages = false
    var body: some View {
        Form {
            Text(fontName)
                .font(.title)
                .font(.custom(fontName, size: 18))
            Text("\(fontInfo)")
            if let copyright = fontInfo?.copyright {
                ListItemView(title: {
                    Text("Settings.fonts.copyright")
                }, value: {
                    Text(copyright)
                })
            }
            if let designer = fontInfo?.designer {
                ListItemView(title: {
                    Text("Settings.fonts.designer")
                }, value: {
                    Text(designer)
                })
            }
            if !fontSupportingLanguagesText.isEmpty {
                ListItemView(title: {
                    Text("Settings.fonts.languages")
                }, value: {
                    Text(fontSupportingLanguagesText)
                })
            }
        }
        .formStyle(.grouped)
        .navigationTitle(fontName)
        .onAppear {
            fontInfo = fontManager.fontInfo(for: fontName)
            var fontSupportingLanguages = fontInfo?.supportedLanguages ?? []
            fontSupportingLanguages = fontSupportingLanguages.map { Locale.current.localizedString(forLanguageCode: $0) ?? "" }
            let formatter = ListFormatter()
            formatter.locale = Locale.current
            fontSupportingLanguagesText = formatter.string(from: fontSupportingLanguages) ?? ""
        }
    }
}

@MainActor
final class FontManager: ObservableObject {
    static let shared = FontManager()
    
    @Published var loadedFonts: [String] = []
    private let cacheDirectory: URL
    
    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = caches.appendingPathComponent("DownloadedFonts", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        preloadCachedFonts()
    }
    
    
    func addFont(from remoteURL: URL) async throws {
        let localURL = cacheDirectory.appendingPathComponent(remoteURL.lastPathComponent)
        if !FileManager.default.fileExists(atPath: localURL.path) {
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            try data.write(to: localURL)
        }
        try registerFont(at: localURL)
        if let name = detectFontName(from: localURL) {
            if !loadedFonts.contains(name) { loadedFonts.append(name) }
        }
    }
    
    func addFont(fromLocal url: URL) throws {
        let destURL = cacheDirectory.appendingPathComponent(url.lastPathComponent)
        if !FileManager.default.fileExists(atPath: destURL.path) {
            try FileManager.default.copyItem(at: url, to: destURL)
        }
        try registerFont(at: destURL)
        if let name = detectFontName(from: destURL) {
            if !loadedFonts.contains(name) { loadedFonts.append(name) }
        }
    }
    
    func removeFont(named fontName: String) {
        CTFontManagerUnregisterFontsForURL(
            cacheDirectory.appendingPathComponent("\(fontName).ttf") as CFURL,
            .process,
            nil
        )
        loadedFonts.removeAll { $0 == fontName }
    }
    
    private func registerFont(at url: URL) throws {
        var error: Unmanaged<CFError>?
        let success = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        if !success {
            throw error?.takeUnretainedValue() ?? NSError(domain: "FontError", code: -1)
        }
    }
    
    private func detectFontName(from url: URL) -> String? {
        guard let descs = CTFontManagerCreateFontDescriptorsFromURL(url as CFURL) as? [CTFontDescriptor],
              let desc = descs.first,
              let name = CTFontDescriptorCopyAttribute(desc, kCTFontNameAttribute) as? String
        else { return nil }
        return name
    }
    
    private func preloadCachedFonts() {
        let fontFiles = (try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
        for url in fontFiles where ["ttf", "otf"].contains(url.pathExtension.lowercased()) {
            try? registerFont(at: url)
            if let name = detectFontName(from: url) {
                if !loadedFonts.contains(name) { loadedFonts.append(name) }
            }
        }
    }
    
    func fontInfo(for fontName: String) -> FontInfo? {
        /*guard*/ let ctFont = CTFontCreateWithName(fontName as CFString, 12, nil)/* else { return nil }*/
        
        let desc = CTFontCopyFontDescriptor(ctFont)
        let traits = (CTFontDescriptorCopyAttribute(desc, kCTFontTraitsAttribute) as? [CFString: Any]) ?? [:]
        
        func name(_ key: CFString) -> String? {
            CTFontCopyName(ctFont, key)/*?.takeRetainedValue()*/ as String?
        }
        
        return FontInfo(
            name: fontName,
            family: CTFontCopyFamilyName(ctFont) as String?,
            //            style: CTFontCopyStyleName(ctFont) as String?,
            fullName: CTFontCopyFullName(ctFont) as String?,
            displayName: CTFontCopyDisplayName(ctFont) as String?,
            weight: traits[kCTFontWeightTrait] as? Double,
            width: traits[kCTFontWidthTrait] as? Double,
            slant: traits[kCTFontSlantTrait] as? Double,
            glyphCount: CTFontGetGlyphCount(ctFont),
            supportedLanguages: CTFontCopySupportedLanguages(ctFont) as? [String],
            copyright: name(kCTFontCopyrightNameKey),
            designer: name(kCTFontDesignerNameKey),
            manufacturer: name(kCTFontManufacturerNameKey)
        )
    }
}


struct FontInfo: Identifiable {
    let id = UUID()
    let name: String
    let family: String?
//    let style: String?
    let fullName: String?
    let displayName: String?
    let weight: Double?
    let width: Double?
    let slant: Double?
    let glyphCount: Int?
    let supportedLanguages: [String]?
    let copyright: String?
    let designer: String?
    let manufacturer: String?
}
