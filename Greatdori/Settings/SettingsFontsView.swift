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
import MarkdownUI
import SwiftUI
import UniformTypeIdentifiers

let fontManagerSampleText: [DoriLocale: String] = [.jp: "あなたの輝きが道を照らす", .en: "Your Spark Will Light the Way", .tw: "你的光芒照耀漫漫長路", .cn: "你的光芒会照亮前行之路", .kr: "당신의 반짝임이 길을 밝힌다"]
let storyViewerDefaultFont: [DoriLocale: String] = [.jp: ".AppleSystemUIFont", .en: ".AppleSystemUIFont", .tw: ".AppleSystemUIFont", .cn: ".AppleSystemUIFont", .kr: ".AppleSystemUIFont"]

//struct SettingsFontsView: View {
//    var body: some View {
//        if isMACOS {
//            SettingsFontsMain()
//        } else {
//            Section("Settings.fonts") {
//                NavigationLink(destination: {
//                    SettingsFontsMain()
//                }, label: {
//                    Text("Settings.fonts")
//                })
//            }
//        }
//    }
//}

struct SettingsFontsView: View {
    @StateObject private var fontManager = FontManager.shared
    @State var newFontSheetIsDisplaying = false
    @State var fontInspectorSheetIsDisplaying = false
    @State var fontInspectorTarget = ""
    @State var addedSystemFonts: [String] = []
    @State var storyViewerFonts: [DoriLocale: String] = [:]
    @State var storyViewerUpdateIndex: Int = 0
    @State var showAboutSheet = false
    @State var aboutContent = ""
    var body: some View {
        Form {
            Group {
                Section("Settings.fonts.system") {
                    ForEach(FontManager.builtInFonts, id: \.self) { item in
                        SettingsFontsPreview(fontInspectorTarget: $fontInspectorTarget, fontInspectorSheetIsDisplaying: $fontInspectorSheetIsDisplaying, fontName: item)
                    }
                    ForEach(addedSystemFonts, id: \.self) { item in
                        SettingsFontsPreview(fontInspectorTarget: $fontInspectorTarget, fontInspectorSheetIsDisplaying: $fontInspectorSheetIsDisplaying, fontName: item)
                            .swipeActions {
                                Button(role: .destructive, action: {
                                    addedSystemFonts.removeAll(where: { $0 == item })
                                    fontManager.removeFontFromPreferences(item)
                                }, label: {
                                    Label("Settings.fonts.remove", systemImage: "trash")
                                })
                            }
                    }
                }
                
                Section("Settings.fonts.installed") {
                    if !fontManager.loadedFonts.isEmpty {
                        ForEach(fontManager.loadedFonts, id: \.self) { item in
                            SettingsFontsPreview(fontInspectorTarget: $fontInspectorTarget, fontInspectorSheetIsDisplaying: $fontInspectorSheetIsDisplaying, fontName: item.fontName)
                                .swipeActions {
                                    Button(role: .destructive, action: {
                                        fontManager.removeFont(fontName: item.fontName)
                                    }, label: {
                                        Label("Settings.fonts.remove", systemImage: "trash")
                                    })
                                }
                        }
                    } else {
                        Text("Settings.fonts.installed.none")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(content: {
                    ForEach(DoriLocale.allCases, id: \.self) { locale in
                        NavigationLink(destination: {
                            SettingsFontsPicker(externalUpdateIndex: $storyViewerUpdateIndex, locale: locale)
                        }, label: {
                            HStack {
                                Text("\(locale.rawValue.uppercased())")
                                Spacer()
                                Text(fontManager.getUserFriendlyFontDisplayName(forFontName: storyViewerFonts[locale] ?? "") ?? (storyViewerFonts[locale] ?? ""))
                                    .foregroundStyle(.secondary)
                            }
                        })
                    }
                    
                }, header: {
                    Text("Settings.fonts.story-viewer")
                }, footer: {
                    if isMACOS {
                        SettingsDocumentButton(document: "FontSuggestions") {
                            Text("Settings.fonts.learn-more")
                        }
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button(action: {
                                    newFontSheetIsDisplaying = true
                                }, label: {
                                    Label("Settings.fonts.new", systemImage: "plus")
                                })
                            }
                        }
                    }
                })
                .onChange(of: storyViewerUpdateIndex, initial: true) {
                    for locale in DoriLocale.allCases {
                        storyViewerFonts.updateValue(UserDefaults.standard.string(forKey: "StoryViewerFont\(locale.rawValue.uppercased())") ?? storyViewerDefaultFont[locale] ?? ".AppleSystemUIFont", forKey: locale)
                    }
                }
                
                if !isMACOS {
                    Section {
                        SettingsDocumentButton(document: "FontSuggestions") {
                            Text("Settings.fonts.learn-more")
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button(action: {
                                newFontSheetIsDisplaying = true
                            }, label: {
                                Label("Settings.fonts.new", systemImage: "plus")
                            })
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings.fonts")
        .sheet(isPresented: $newFontSheetIsDisplaying) {
            SettingsFontsAdd()
        }
        .sheet(isPresented: $fontInspectorSheetIsDisplaying) {
            SettingsFontsDetail(fontName: $fontInspectorTarget, inspectorIsDisplaying: $fontInspectorSheetIsDisplaying)
        }
        .onChange(of: fontInspectorSheetIsDisplaying, newFontSheetIsDisplaying, initial: true) {
            addedSystemFonts = UserDefaults.standard.stringArray(forKey: "addedSystemFonts") ?? []
        }
        .onChange(of: addedSystemFonts) {
            UserDefaults.standard.set(addedSystemFonts, forKey: "addedSystemFonts")
        }
    }
    
    struct SettingsFontsPreview: View {
        var fontManager = FontManager.shared
        @Binding var fontInspectorTarget: String
        @Binding var fontInspectorSheetIsDisplaying: Bool
        var fontName: String
        var body: some View {
            Button(action: {
                fontInspectorTarget = fontName
                fontInspectorSheetIsDisplaying = true
            }, label: {
                HStack {
                    Text(fontManager.getUserFriendlyFontDisplayName(forFontName: fontName) ?? fontName)
                        .font(.custom(fontName, size: 18))
                        .fontWeight(.regular)
                    Spacer()
                    Image(systemName: "info.circle")
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            })
            .buttonStyle(.plain)
        }
    }
}

struct SettingsFontsAdd: View {
    @StateObject private var fontManager = FontManager.shared
    @Environment(\.dismiss) var dismiss
    @State var newFontOnlineURL = ""
    @State var newFontLocalURL: URL?
    @State var newFontSystemName = ""
    @State var newFontAddFailureAlertIsDisplaying = false
    @State var newFontAddFailureReason = ""
    @State var newFontIsAdding = false
    @State var newFontSourceType = 0
    @State var newFontFileImporterIsDisplaying = false
    @State var addedSystemFonts: [String] = []
    var body: some View {
        NavigationStack {
            Form {
                Section(content: {
                    HStack {
                        Text("Settings.fonts.new.type")
                            .bold()
                        Spacer()
                        Picker("", selection: $newFontSourceType, content: {
                            Text("Settings.fonts.new.type.online")
                                .tag(0)
                            Text("Settings.fonts.new.type.local")
                                .tag(1)
                            Text("Settings.fonts.new.type.system")
                                .tag(2)
                        })
                        .labelsHidden()
                    }
                    if newFontSourceType == 0 {
                        HStack {
                            Text("Settings.fonts.new.url")
                                .bold()
                            Spacer()
                            TextField("", text: $newFontOnlineURL, prompt: Text(verbatim: "example.com/font.ttf"))
                                .lineLimit(1)
                                .multilineTextAlignment(.trailing)
                                .labelsHidden()
                                .wrapIf(!isMACOS, in: { content in
                                    #if os(iOS)
                                        content.textInputAutocapitalization(.never)
                                    #endif
                                })
                        }
                    } else if newFontSourceType == 1 {
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
                    } else if newFontSourceType == 2 {
                        HStack {
                            Text("Settings.fonts.new.name")
                                .bold()
                            Spacer()
                            TextField("", text: $newFontSystemName, prompt: Text(verbatim: "SF Pro"))
                                .lineLimit(1)
                                .multilineTextAlignment(.trailing)
                                .labelsHidden()
                                .autocorrectionDisabled()
                                .wrapIf(!isMACOS, in: { content in
#if os(iOS)
                                    content.textInputAutocapitalization(.never)
#endif
                                })
                        }
                    }
                }, footer: {
                    Text("Settings.fonts.new.footer")
                })
                
                if newFontSourceType == 2 && fontManager.allAvailableFontNames().contains(newFontSystemName) {
                    Section(content: {
                        Text(newFontSystemName)
                            .font(.custom(newFontSystemName, size: 18))
                    }, footer: {
                        if !newSystemFontCanBeAdded(newFontSystemName) {
                            Text("Settings.fonts.new.preview.footer.added")
                        }
                    })
                }
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
                            if newFontSourceType != 2 {
                                let url = newFontSourceType == 0 ? URL(string: newFontOnlineURL)! : newFontLocalURL!
                                Task {
                                    do {
                                        if newFontSourceType == 0 {
                                            try await fontManager.addFont(fromRemote: url)
                                        } else {
                                            try fontManager.addFont(fromLocal: url)
                                        }
                                        newFontIsAdding = false
                                        dismiss()
                                    } catch {
                                        newFontIsAdding = false
                                        newFontAddFailureReason = error.localizedDescription
                                        newFontAddFailureAlertIsDisplaying = true
                                    }
                                }
                            } else {
                                addedSystemFonts.append(newFontSystemName)
                                dismiss()
                            }
                        }, label: {
                            Label(newFontSourceType == 2 ? "Settings.fonts.new.add" : "Settings.fonts.new.install", systemImage: "checkmark")
                                .wrapIf(isMACOS, in: {
                                    $0.labelStyle(.titleOnly)
                                }, else: {
                                    $0.labelStyle(.iconOnly)
                                })
                        })
                        .disabled(newFontSourceType == 0 && URL(string: newFontOnlineURL) == nil)
                        .disabled(newFontSourceType == 1 && newFontLocalURL == nil)
                        .disabled(newFontSourceType == 2 && !(newSystemFontCanBeAdded(newFontSystemName)))
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        dismiss()
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
                                    .controlSize(.small)
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
            .onAppear {
                addedSystemFonts = UserDefaults.standard.stringArray(forKey: "addedSystemFonts") ?? []
            }
            .onChange(of: addedSystemFonts) {
                UserDefaults.standard.set(addedSystemFonts, forKey: "addedSystemFonts")
            }
        }
    }
    
    func newSystemFontCanBeAdded(_ newFontSystemName: String) -> Bool {
        return fontManager.allAvailableFontNames().contains(newFontSystemName) && !addedSystemFonts.contains(newFontSystemName) && !newFontSystemName.isEmpty && !fontManager.loadedFonts.contains(where: { $0.fontName == newFontSystemName }) && !FontManager.builtInFonts.contains(newFontSystemName)
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
    @State var fontManagerSampleTextFontWeight: Font.Weight = .regular
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
                                    if let fileName = fontManager.getFontCahce(forFontName: fontName)?.fileName {
                                        Text(fileName)
                                            .font(.custom(fontName, size: 10))
                                    } else {
                                        Text("Settings.fonts.info.title.system-font")
                                            .font(.custom(fontName, size: 10))
                                    }
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
                            ListItem(title: {
                                Text("Settings.fonts.info.full-name")
                            }, value: {
                                Text(fullName)
                            })
                        }
                        
                        if let glythCount = fontInfo?.glyphCount {
                            ListItem(title: {
                                Text("Settings.fonts.info.glyphs")
                            }, value: {
                                Text("Settings.fonts.info.glyphs.\(glythCount)")
                            })
                        }
                        if !fontSupportingLanguagesText.isEmpty {
                            ListItem(title: {
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
                            .listItemLayout((showCountsInsteadOfAllItemsForLanguages || (fontInfo?.supportedLanguages?.count ?? 0) < 5) ? .automatic : .expandedOnly)
                            .onTapGesture {
                                showCountsInsteadOfAllItemsForLanguages.toggle()
                            }
                        }
                        if fontManager.fontIsVariable(fontName: fontName) {
                            ListItem(title: {
                                Text("Settings.fonts.info.variable-font")
                            }, value: {
                                Text("Settings.fonts.info.true")
                            })
                        }
                        
                        if fontManager.isSystemFont(CTFontCreateWithName(fontName as CFString, 14, nil)) {
                            ListItem(title: {
                                Text("Settings.fonts.info.system-font")
                            }, value: {
                                Text("Settings.fonts.info.true")
                            })
                        }
                        
                        if let designer = fontInfo?.designer {
                            ListItem(title: {
                                Text("Settings.fonts.info.designer")
                            }, value: {
                                Text(designer)
                            })
                        }
                        if let manufacturer = fontInfo?.manufacturer {
                            ListItem(title: {
                                Text("Settings.fonts.info.manufacturer")
                            }, value: {
                                Text(manufacturer)
                            })
                        }
                        if let copyright = fontInfo?.copyright {
                            ListItem(title: {
                                Text("Settings.fonts.info.copyright")
                            }, value: {
                                Text(copyright)
                            })
                        }
                    }
                    .listItemValueAlignment(.leading)
                    
                    Section(content: {
                        Group {
                            if fontManager.fontIsVariable(fontName: fontName) {
                                ListItem(title: {
                                    Text("Settings.fonts.info.preview.weight")
                                        .bold(false)
                                }, value: {
                                    Picker(selection: $fontManagerSampleTextFontWeight, content: {
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
                                .listItemValueAlignment(.leading)
                            }
                            
                            ForEach(DoriLocale.allCases, id: \.self) { locale in
                                if fontManager.fontSupportsLocale(fontName, locale: locale) {
                                    Text(fontManagerSampleText[locale]!)
                                        .font(.custom(fontName, size: 18))
                                        .fontWeight(fontManagerSampleTextFontWeight)
                                        .typesettingLanguage(locale.nsLocale().language)
                                }
                            }
                        }
                        .emptyReplacement {
                            Text(fontManagerSampleText[.en]!)
                                .font(.custom(fontName, size: 18))
                                .fontWeight(fontManagerSampleTextFontWeight)
                                .typesettingLanguage(DoriLocale.en.nsLocale().language)
                            Text("Settings.fonts.info.preview.unavailable")
                                .foregroundStyle(.secondary)
                        }
                        
//                        if !fontManager.fontSupportsLocale(fontName, locale: .jp) && !fontManager.fontSupportsLocale(fontName, locale: .en) && !fontManager.fontSupportsLocale(fontName, locale: .cn) && !fontManager.fontSupportsLocale(fontName, locale: .tw) && !fontManager.fontSupportsLocale(fontName, locale: .kr) {
//                            Text(fontManagerSampleText[.en]!)
//                                .font(.custom(fontName, size: 18))
//                                .fontWeight(fontManagerSampleTextFontWeight)
//                                .typesettingLanguage(DoriLocale.en.nsLocale().language)
//                            Text("Settings.fonts.info.preview.unavailable")
//                                .foregroundStyle(.secondary)
//                        }
                    }, header: {
                        Text("Settings.fonts.info.preview")
                    }, footer: {
                        if fontManager.fontInfo(fontName: fontName)?.supportedLanguages?.isEmpty ?? true {
                            Text("Settings.fonts.info.preview.no-supported-language")
                        } else if sampleLanguageIsMissing {
                            Text("Settings.fonts.info.preview.missing-language")
                        }
                    })
                    
                    Section {
                        if !isMACOS && !FontManager.builtInFonts.contains(fontName) {
                            Button(role: .destructive, action: {
                                if fontManager.getFontCahce(forFontName: fontName)?.fileName != nil { // Is not system font
                                    fontManager.removeFont(fontName: fontName)
                                } else {
                                    var addedSystemFonts = UserDefaults.standard.stringArray(forKey: "addedSystemFonts") ?? []
                                    addedSystemFonts.removeAll(where: { $0 == fontName })
                                    UserDefaults.standard.set(addedSystemFonts, forKey: "addedSystemFonts")
                                    fontManager.removeFontFromPreferences(fontName)
                                }
                                inspectorIsDisplaying = false
                            }, label: {
                                Label("Settings.fonts.info.remove", systemImage: "trash")
                                    .foregroundStyle(.red)
                            })
                        }
                    }
                    
                    /*
                    if fontName.hasPrefix("Noto Sans") || fontName.hasPrefix("NotoSans") {
                        Section {
                            ListItem(title: {
                                Text("Settings.fonts.info.license")
                            }, value: {
                                Text(oflLicense)
                                    .multilineTextAlignment(.leading)
                                    .fontDesign(.monospaced)
                                    .font(.caption)
                            })
                        }
                    }
                     */
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
                    if isMACOS && !FontManager.builtInFonts.contains(fontName) {
                        ToolbarItem(placement: .destructiveAction) {
                            Button(role: .destructive, action: {
                                if fontManager.getFontCahce(forFontName: fontName)?.fileName != nil { // Is not system font
                                    fontManager.removeFont(fontName: fontName)
                                } else {
                                    var addedSystemFonts = UserDefaults.standard.stringArray(forKey: "addedSystemFonts") ?? []
                                    addedSystemFonts.removeAll(where: { $0 == fontName })
                                    fontManager.removeFontFromPreferences(fontName)
                                    UserDefaults.standard.set(addedSystemFonts, forKey: "addedSystemFonts")
                                }
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

struct SettingsFontsPicker: View {
    @StateObject private var fontManager = FontManager.shared
    @Binding var externalUpdateIndex: Int
    @State var addedSystemFonts: [String] = []
    @State var updateIndex = 0
    @State var selectedFont = ""
    var locale: DoriLocale
    var body: some View {
        ScrollView {
            VStack {
                Section {
                    HStack {
                        Text("Settings.fonts.system")
                            .bold()
                        Spacer()
                    }
                    ForEach(FontManager.builtInFonts + addedSystemFonts, id: \.self) { item in
                        SettingsFontsPickerItem(selectedFont: $selectedFont, updateIndex: $updateIndex, locale: locale, fontName: item)
                    }
                }
                
                DetailSectionsSpacer()
                
                if !fontManager.loadedFonts.filter({ fontManager.fontSupportsLocale($0.fontName, locale: locale) }).isEmpty {
                    Section {
                        HStack {
                            Text("Settings.fonts.installed")
                                .bold()
                            Spacer()
                        }
                        ForEach(fontManager.loadedFonts, id: \.self) { item in
                            SettingsFontsPickerItem(selectedFont: $selectedFont, updateIndex: $updateIndex, locale: locale, fontName: item.fontName)
                        }
                    }
                }
            }
            .padding()
        }
        .withSystemBackground()
        .navigationTitle("\(locale.rawValue.uppercased())")
        .formStyle(.grouped)
        .onAppear {
            addedSystemFonts = UserDefaults.standard.stringArray(forKey: "addedSystemFonts") ?? []
        }
        .onChange(of: updateIndex, initial: true) {
            selectedFont = UserDefaults.standard.string(forKey: "StoryViewerFont\(locale.rawValue.uppercased())") ?? storyViewerDefaultFont[locale] ?? ".AppleSystemUIFont"
        }
        .onDisappear {
            externalUpdateIndex += 1
        }
    }
    
    struct SettingsFontsPickerItem: View {
        @StateObject var fontManager = FontManager.shared
        @Binding var selectedFont: String
        @Binding var updateIndex: Int
        var locale: DoriLocale
        var fontName: String
        var body: some View {
            if fontManager.fontSupportsLocale(fontName, locale: locale) {
                Button(action: {
                    UserDefaults.standard.set(fontName, forKey: "StoryViewerFont\(locale.rawValue.uppercased())")
                    updateIndex += 1
                }, label: {
                    CustomGroupBox(customGroupBoxVersion: 1) {
                        VStack(alignment: .leading) {
                            HStack {
                                Text(fontManager.getUserFriendlyFontDisplayName(forFontName: fontName) ?? fontName)
                                Spacer()
                                CompactToggle(isLit: selectedFont == fontName)
                            }
                            ScrollView(.horizontal) {
                                Text(fontManagerSampleText[locale]!)
                                    .font(.custom(fontName, size: 30))
                                    .typesettingLanguage(locale.nsLocale().language)
                                    .fontWeight(.regular)
                            }
                        }
                    }
                    .contentShape(Rectangle())
                })
                .buttonStyle(.plain)
            }
        }
    }
}

@MainActor
final class FontManager: ObservableObject {
    static let shared = FontManager()
    static let allAcceptableSuffix: Set<String> = ["ttf", "otf", "ttc", "otc"]
    static let builtInFonts = [".AppleSystemUIFont"]
    
    
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
        
        for fileURL in fileURLs where FontManager.allAcceptableSuffix.contains(fileURL.pathExtension.lowercased()) {
            if let name = detectFontName(from: fileURL),
               name == fontName {
                CTFontManagerUnregisterFontsForURL(fileURL as CFURL, .process, nil)
                try? FileManager.default.removeItem(at: fileURL)
            }
        }
        loadedFonts.removeAll { $0.fontName == fontName }
        
        removeFontFromPreferences(fontName)
    }
    
    func removeFontFromPreferences(_ fontName: String) {
        for locale in DoriLocale.allCases {
            if (UserDefaults.standard.string(forKey: "StoryViewerFont\(locale.rawValue.uppercased())") ?? "") == fontName {
                UserDefaults.standard.set(storyViewerDefaultFont[locale] ?? ".AppleSystemUIFont", forKey: "StoryViewerFont\(locale.rawValue.uppercased())")
            }
        }
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
        for url in fontFiles where FontManager.allAcceptableSuffix.contains(url.pathExtension.lowercased()) {
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
                url.lastPathComponent == fontName
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
    
    func isSystemFont(_ font: CTFont) -> Bool {
        guard let url = CTFontCopyAttribute(font, kCTFontURLAttribute) as? URL else {
            return false
        }
        let path = url.path
        return path.hasPrefix("/System/Library/Fonts/") || path.hasPrefix("/Library/Fonts/") || path.hasPrefix("/System/Library/PrivateFrameworks/FontServices.framework/Resources/Reserved/") || path.hasPrefix("/System/Library/AssetsV2/com_apple_MobileAsset_Font8/")
    }
    
    func allAvailableFontNames() -> [String] {
        guard let descriptors = CTFontManagerCopyAvailableFontFamilyNames() as? [String] else {
            return []
        }
        return descriptors.sorted()
    }
    
    func fontSupportsLocale(_ fontName: String, locale: DoriLocale) -> Bool {
        let ctFont = CTFontCreateWithName(fontName as CFString, 12, nil)
        let supportedLanguages = CTFontCopySupportedLanguages(ctFont) as? [String]
        return (supportedLanguages?.contains(locale.nsLocale().identifier) ?? true) || (supportedLanguages?.isEmpty ?? true) || fontName == ".AppleSystemUIFont"
    }
}

struct FontInfo: Identifiable {
    let id = UUID()
    let name: String
    let family: String?
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
    let locale = Locale(identifier: identifier)
    let languageCode = locale.languageCode
    let scriptCode = locale.scriptCode
    let regionCode = locale.regionCode
    
    let languageName = languageCode.flatMap {
        displayLocale.localizedString(forLanguageCode: $0)
    }
    let scriptName = scriptCode.flatMap {
        displayLocale.localizedString(forScriptCode: $0)
    }
    let regionName = regionCode.flatMap {
        displayLocale.localizedString(forRegionCode: $0)
    }
    
    switch (languageName, scriptName, regionName) {
    case let (lang?, script?, region?):
        return "\(lang) (\(script), \(region))"
    case let (lang?, script?, nil):
        return "\(lang) (\(script))"
    case let (lang?, nil, region?):
        return "\(lang) (\(region))"
    case let (lang?, nil, nil):
        return lang
    default:
        return identifier
    }
}


extension Font.Weight {
    static var allCases: [Font.Weight] { [.thin, .ultraLight, .light, .regular, .medium, .semibold, .bold, .heavy, .black] }
}


let oflLicense = """
Copyright 2014-2021 Adobe (http://www.adobe.com/), with Reserved Font Name 'Source'

This Font Software is licensed under the SIL Open Font License, Version 1.1.
This license is copied below, and is also available with a FAQ at:
https://openfontlicense.org


-----------------------------------------------------------
SIL OPEN FONT LICENSE Version 1.1 - 26 February 2007
-----------------------------------------------------------

PREAMBLE
The goals of the Open Font License (OFL) are to stimulate worldwide
development of collaborative font projects, to support the font creation
efforts of academic and linguistic communities, and to provide a free and
open framework in which fonts may be shared and improved in partnership
with others.

The OFL allows the licensed fonts to be used, studied, modified and
redistributed freely as long as they are not sold by themselves. The
fonts, including any derivative works, can be bundled, embedded, 
redistributed and/or sold with any software provided that any reserved
names are not used by derivative works. The fonts and derivatives,
however, cannot be released under any other type of license. The
requirement for fonts to remain under this license does not apply
to any document created using the fonts or their derivatives.

DEFINITIONS
"Font Software" refers to the set of files released by the Copyright
Holder(s) under this license and clearly marked as such. This may
include source files, build scripts and documentation.

"Reserved Font Name" refers to any names specified as such after the
copyright statement(s).

"Original Version" refers to the collection of Font Software components as
distributed by the Copyright Holder(s).

"Modified Version" refers to any derivative made by adding to, deleting,
or substituting -- in part or in whole -- any of the components of the
Original Version, by changing formats or by porting the Font Software to a
new environment.

"Author" refers to any designer, engineer, programmer, technical
writer or other person who contributed to the Font Software.

PERMISSION & CONDITIONS
Permission is hereby granted, free of charge, to any person obtaining
a copy of the Font Software, to use, study, copy, merge, embed, modify,
redistribute, and sell modified and unmodified copies of the Font
Software, subject to the following conditions:

1) Neither the Font Software nor any of its individual components,
in Original or Modified Versions, may be sold by itself.

2) Original or Modified Versions of the Font Software may be bundled,
redistributed and/or sold with any software, provided that each copy
contains the above copyright notice and this license. These can be
included either as stand-alone text files, human-readable headers or
in the appropriate machine-readable metadata fields within text or
binary files as long as those fields can be easily viewed by the user.

3) No Modified Version of the Font Software may use the Reserved Font
Name(s) unless explicit written permission is granted by the corresponding
Copyright Holder. This restriction only applies to the primary font name as
presented to the users.

4) The name(s) of the Copyright Holder(s) or the Author(s) of the Font
Software shall not be used to promote, endorse or advertise any
Modified Version, except to acknowledge the contribution(s) of the
Copyright Holder(s) and the Author(s) or with their explicit written
permission.

5) The Font Software, modified or unmodified, in part or in whole,
must be distributed entirely under this license, and must not be
distributed under any other license. The requirement for fonts to
remain under this license does not apply to any document created
using the Font Software.

TERMINATION
This license becomes null and void if any of the above conditions are
not met.

DISCLAIMER
THE FONT SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT
OF COPYRIGHT, PATENT, TRADEMARK, OR OTHER RIGHT. IN NO EVENT SHALL THE
COPYRIGHT HOLDER BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
INCLUDING ANY GENERAL, SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL
DAMAGES, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF THE USE OR INABILITY TO USE THE FONT SOFTWARE OR FROM
OTHER DEALINGS IN THE FONT SOFTWARE.
"""
