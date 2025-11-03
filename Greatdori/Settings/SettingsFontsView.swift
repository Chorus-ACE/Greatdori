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
import DoriKit
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
                            fontInspectorTarget = item.fontName
                            fontInspectorSheetIsDisplaying = true
                        }, label: {
                            HStack {
                                Text(fontManager.getUserFriendlyFontDisplayName(forFontName: item.fontName) ?? item.fontName)
                                    .font(.custom(item.fontName, size: 18))
                                    .fontWeight(.regular)
                                Spacer()
                                Image(systemName: "info.circle")
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(Rectangle())
                        })
                        .buttonStyle(.plain)
                        .swipeActions {
                            Button(role: .destructive, action: {
                                fontManager.removeFont(fontName: item.fontName)
                            }, label: {
                                Label("Settings.fonts.installed.remove", systemImage: "trash")
                            })
                        }
                    }
                } else {
                    Text("Settings.fonts.installed.none")
                        .foregroundStyle(.secondary)
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
                                            try await fontManager.addFont(fromRemote: url)
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
            SettingsFontsDetail(fontName: $fontInspectorTarget, inspectorIsDisplaying: $fontInspectorSheetIsDisplaying)
        }
    }
}


struct SettingsFontsDetail: View {
    @StateObject private var fontManager = FontManager.shared
    @Binding var fontName: String
    @Binding var inspectorIsDisplaying: Bool
    @State var fontInfo: FontInfo? = nil
    @State var fontSupportingLanguagesText: String = ""
    @State var showCountsInsteadOfAllItemsForLanguages = true
    @State var sampleLanguageIsMissing = false
    @State var sampleTextFontWeight: Font.Weight = .regular
    
    let sampleText: [DoriLocale: String] = [.jp: "あなたの輝きが道を照らす", .en: "Your Spark Will Light the Way", .tw: "你的光芒照耀漫漫長路", .cn: "你的光芒会照亮前行之路", .kr: "당신의 반짝임이 길을 밝힌다"]
    var body: some View {
        NavigationStack {
            if !fontName.isEmpty {
                Form {
                    Section {
                        HStack {
                            VStack(alignment: .leading) {
                                if let fontFamily = fontInfo?.family {
                                    Text(fontFamily)
                                        .font(.custom(fontName, size: 18))
                                    Text(fontManager.getFontCahce(forFontName: fontName)?.fileName ?? "")
                                        .font(.custom(fontName, size: 10))
                                } else {
                                    Text(fontName)
                                        .font(.custom(fontName, size: 18))
                                }
                            }
                            .fontWeight(.regular)
                            Spacer()
                            if let intFontSize = fontManager.fontFileSize(fontName: fontManager.getFontCahce(forFontName: fontName)?.fileName ?? "") {
                                let fontSize = Double(intFontSize)
                                Text("\(fontSize/1000/1000 < 1 ? "\(String(format: "%.1f", fontSize/1000)) KB" : "\(String(format: "%.1f", fontSize/1000/1000)) MB")")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .textSelection(.enabled)
                    }
                    
                    Section {
                        if let fullName = fontInfo?.fullName {
                            ListItem(allowValueLeading: true, title: {
                                Text("Settings.fonts.info.full-name")
                            }, value: {
                                Text(fullName)
                            })
                        }
                        
                        if let glythCount = fontInfo?.glyphCount {
                            ListItem(allowValueLeading: true, title: {
                                Text("Settings.fonts.info.glyphs")
                            }, value: {
                                Text("Settings.fonts.info.glyphs.\(glythCount)")
                            })
                        }
                        if !fontSupportingLanguagesText.isEmpty {
                            ListItem(allowValueLeading: true, displayMode: (showCountsInsteadOfAllItemsForLanguages && (fontInfo?.supportedLanguages?.count ?? 0) > 5) ? .automatic : .expandedOnly, title: {
                                Text("Settings.fonts.info.languages")
                            }, value: {
                                Group {
                                    if showCountsInsteadOfAllItemsForLanguages && (fontInfo?.supportedLanguages?.count ?? 0) > 5 {
                                        Text("Settings.fonts.info.languages.\(fontInfo?.supportedLanguages?.count ?? -1)")
                                    } else {
                                        Text(fontSupportingLanguagesText)
                                    }
                                }
                            })
                            .onTapGesture {
                                showCountsInsteadOfAllItemsForLanguages.toggle()
                            }
                        }
                        if fontManager.fontIsVariable(fontName: fontName) {
                            ListItem(allowValueLeading: true, title: {
                                Text("Settings.fonts.info.variable-font")
                            }, value: {
                                Text("Settings.fonts.info.variable-font.true")
                            })
                        }
                        
                        if let designer = fontInfo?.designer {
                            ListItem(allowValueLeading: true, title: {
                                Text("Settings.fonts.info.designer")
                            }, value: {
                                Text(designer)
                            })
                        }
                        if let manufacturer = fontInfo?.manufacturer {
                            ListItem(allowValueLeading: true, title: {
                                Text("Settings.fonts.info.manufacturer")
                            }, value: {
                                Text(manufacturer)
                            })
                        }
                        if let copyright = fontInfo?.copyright {
                            ListItem(allowValueLeading: true, title: {
                                Text("Settings.fonts.info.copyright")
                            }, value: {
                                Text(copyright)
                            })
                        }
                    }
                    
                    Section(content: {
                        if fontManager.fontIsVariable(fontName: fontName) {
                            ListItem(allowValueLeading: true, boldTitle: false, title: {
                                Text("Settings.fonts.info.preview.weight")
                            }, value: {
                                Picker(selection: $sampleTextFontWeight, content: {
                                    Text("Settings.fonts.info.preview.weight.light")
                                        .tag(Font.Weight.light)
                                    Text("Settings.fonts.info.preview.weight.regular")
                                        .tag(Font.Weight.regular)
                                    Text("Settings.fonts.info.preview.weight.bold")
                                        .tag(Font.Weight.bold)
                                }, label: {
                                    EmptyView()
                                })
                                .labelsHidden()
                            })
                        }
                        
                        ForEach(DoriLocale.allCases, id: \.self) { locale in
                            if fontManager.fontInfo(fontName: fontName)?.supportedLanguages?.contains(locale.nsLocale().identifier) ?? true {
                                Text(sampleText[locale]!)
                                    .font(.custom(fontName, size: 18))
                                    .fontWeight(sampleTextFontWeight)
                                    .typesettingLanguage(locale.nsLocale().language)
                            }
                        }
                    }, header: {
                        Text("Settings.fonts.info.preview")
                        if sampleLanguageIsMissing {
                            Text("Settings.fonts.info.preview.missing-language")
                        }
                    })
                    
                    Section {
                        if !isMACOS {
                            Button(role: .destructive, action: {
                                fontManager.removeFont(fontName: fontName)
                                inspectorIsDisplaying = false
                            }, label: {
                                Label("Settings.fonts.info.remove", systemImage: "trash")
                            })
                        }
                    }
                }
                .formStyle(.grouped)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(action: {
                            inspectorIsDisplaying = false
                        }, label: {
                            Label("Settings.fonts.info.done", systemImage: "xmark")
                                .wrapIf(isMACOS, in: {
                                    $0.labelStyle(.titleOnly)
                                }, else: {
                                    $0.labelStyle(.iconOnly)
                                })
                        })
                    }
                    if isMACOS {
                        ToolbarItem(placement: .destructiveAction) {
                            Button(role: .destructive, action: {
                                fontManager.removeFont(fontName: fontName)
                                inspectorIsDisplaying = false
                            }, label: {
                                Label("Settings.fonts.info.remove", systemImage: "trash")
                                    .wrapIf(isMACOS, in: {
                                        $0.labelStyle(.titleOnly)
                                    }, else: {
                                        $0.labelStyle(.iconOnly)
                                    })
                            })
                        }
                    }
                }
            } else {
                ProgressView()
            }
        }
        .navigationTitle(fontName)
        .onAppear {
            fontInfo = fontManager.fontInfo(fontName: fontName)
            var fontSupportingLanguages = fontInfo?.supportedLanguages ?? []
            fontSupportingLanguages = fontSupportingLanguages.map { localizedLanguageName(for: $0) }.sorted()
            let formatter = ListFormatter()
            formatter.locale = Locale.current
            fontSupportingLanguagesText = formatter.string(from: fontSupportingLanguages) ?? ""
            
            for locale in DoriLocale.allCases {
                if fontSupportingLanguages.contains(locale.nsLocale().identifier).reversed() {
                    sampleLanguageIsMissing = true
                }
            }
        }
    }
}

@MainActor
final class FontManager: ObservableObject {
    static let shared = FontManager()
    let allAcceptableSuffix: Set<String> = ["ttf", "otf", "ttc", "otc"]
    
    @Published var loadedFonts: [CachedFont] = []
    private let cacheDirectory: URL
    
    private init() {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        cacheDirectory = caches.appendingPathComponent("DownloadedFonts", isDirectory: true)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        preloadCachedFonts()
    }
    
    struct CachedFont: Identifiable, Hashable {
        var id = UUID()
        var fontName: String
        var fileName: String
    }
    
    func addFont(fromRemote remoteURL: URL) async throws {
        let localURL = cacheDirectory.appendingPathComponent(remoteURL.lastPathComponent)
        if !FileManager.default.fileExists(atPath: localURL.path) {
            let (data, _) = try await URLSession.shared.data(from: remoteURL)
            try data.write(to: localURL)
        }
        try registerFont(at: localURL)
        if let name = detectFontName(from: localURL),
           !loadedFonts.contains(where: { $0.fontName == name }) {
            let cached = CachedFont(fontName: name,
                                    fileName: localURL.lastPathComponent)
            loadedFonts.append(cached)
        }
    }
    
    func addFont(fromLocal localURL: URL) throws {
        let destURL = cacheDirectory.appendingPathComponent(localURL.lastPathComponent)
        if !FileManager.default.fileExists(atPath: destURL.path) {
            try FileManager.default.copyItem(at: localURL, to: destURL)
        }
        try registerFont(at: destURL)
        if let name = detectFontName(from: destURL),
           !loadedFonts.contains(where: { $0.fontName == name }) {
            let cached = CachedFont(fontName: name,
                                    fileName: destURL.lastPathComponent)
            loadedFonts.append(cached)
        }
    }
    
    func removeFont(fontName: String) {
        let fileURLs = (try? FileManager.default.contentsOfDirectory(
            at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
        
        for fileURL in fileURLs where allAcceptableSuffix.contains(fileURL.pathExtension.lowercased()) {
            if let name = detectFontName(from: fileURL),
               name == fontName {
                CTFontManagerUnregisterFontsForURL(fileURL as CFURL, .process, nil)
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        loadedFonts.removeAll { $0.fontName == fontName }
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
              var name = CTFontDescriptorCopyAttribute(desc, kCTFontNameAttribute) as? String
        else { return nil }
        if name.hasPrefix("-Thin") {
            name = name.dropLast(5) + "-Regular"
        }
        return name
    }
    
    private func preloadCachedFonts() {
        let fontFiles = (try? FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)) ?? []
        for url in fontFiles where allAcceptableSuffix.contains(url.pathExtension.lowercased()) {
            try? registerFont(at: url)
            if let name = detectFontName(from: url),
               !loadedFonts.contains(where: { $0.fontName == name }) {
                let cached = CachedFont(fontName: name,
                                        fileName: url.lastPathComponent)
                loadedFonts.append(cached)
            }
        }
    }
    
    func fontInfo(fontName: String) -> FontInfo? {
        let ctFont = CTFontCreateWithName(fontName as CFString, 12, nil)/* else { return nil }*/
        
        let desc = CTFontCopyFontDescriptor(ctFont)
        let traits = (CTFontDescriptorCopyAttribute(desc, kCTFontTraitsAttribute) as? [CFString: Any]) ?? [:]
        
        func name(_ key: CFString) -> String? {
            CTFontCopyName(ctFont, key) as String?
        }
        
        return FontInfo(
            name: fontName,
            family: CTFontCopyFamilyName(ctFont) as String?,
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
    
    func getUserFriendlyFontDisplayName(forFontName fontName: String) -> String? {
        CTFontCopyFamilyName(CTFontCreateWithName(fontName as CFString, 12, nil)) as String?
    }
    
    func fontIsVariable(fontName: String) -> Bool {
        let desc = CTFontDescriptorCreateWithNameAndSize(fontName as CFString, 12)
        if let axes = CTFontDescriptorCopyAttribute(desc, kCTFontVariationAxesAttribute) as? [[CFString: Any]],
           !axes.isEmpty {
            return true
        } else {
            return false
        }
    }
    
    func fontFileSize(fontName: String) -> Int64? {
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            if let fontFile = files.first(where: { url in
                url.deletingPathExtension().lastPathComponent == fontName
            }) {
                let attributes = try fileManager.attributesOfItem(atPath: fontFile.path)
                return attributes[.size] as? Int64
            }
        } catch {
            print("\(error.localizedDescription)")
        }
        return nil
    }
    
    func getFontCahce(forFontName fontName: String) -> CachedFont? {
        return loadedFonts.first { $0.fontName == fontName }
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

func localizedLanguageName(for identifier: String, displayLocale: Locale = .current) -> String {
    // 拆分语言和地区
    let locale = Locale(identifier: identifier)
    let languageCode = locale.languageCode
    let regionCode = locale.regionCode
    
    // 获取语言名
    let languageName = languageCode.flatMap {
        displayLocale.localizedString(forLanguageCode: $0)
    }
    
    // 获取地区名
    let regionName = regionCode.flatMap {
        displayLocale.localizedString(forRegionCode: $0)
    }
    
    // 拼接输出
    switch (languageName, regionName) {
    case let (lang?, region?):
        return "\(lang) (\(region))"
    case let (lang?, nil):
        return lang
    default:
        return identifier
    }
}

extension Font.Weight {
    static var allCases: [Font.Weight] { [.thin, .ultraLight, .light, .regular, .medium, .semibold, .bold, .heavy, .black] }
}
