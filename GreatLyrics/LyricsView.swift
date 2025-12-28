//===---*- Greatdori! -*---------------------------------------------------===//
//
// LyricsView.swift
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
@_spi(Advanced) import SwiftUIIntrospect
@_private(sourceFile: "FrontendSong.swift") import DoriKit

struct LyricsView: View {
    @Binding var lyrics: Lyrics
    @Environment(\.appearsActive) var appearsActive
    @Environment(\.openWindow) var openWindow
    @Environment(\.colorScheme) var colorScheme
    @State var editorTextView: NSTextView?
    @State var lyricsForPreview: Lyrics?
    @State var isPreviewUpdating = false
    @State var previewUpdateTimer: Timer?
    @State var editingField = LyricField.original
    @State var temporaryCombinedText = ""
    @State var currentTextSelection: TextSelection?
    @State var previewSecondaryField = LyricField.original
    var body: some View {
        VSplitView {
            HSplitView {
                TextEditor(text: $temporaryCombinedText, selection: $currentTextSelection)
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .introspect(.textEditor, on: .macOS(.v15...)) { textView in
                        textView.backgroundColor = .init(colorScheme == .dark ? Color(red: 41 / 255, green: 42 / 255, blue: 47 / 255) : .white)
                        editorTextView = textView
                    }
                    .onChange(of: currentTextSelection, colorScheme) {
                        unsafe editorTextView?.textStorage?.removeAttribute(.backgroundColor, range: .init(temporaryCombinedText.startIndex..<temporaryCombinedText.endIndex, in: temporaryCombinedText))
                        if let currentTextSelection,
                           currentTextSelection.isInsertion,
                           case let .selection(_range) = currentTextSelection.indices {
                            let lineRange = temporaryCombinedText.lineRange(for: _range)
                            unsafe editorTextView?.textStorage?.addAttribute(
                                .backgroundColor,
                                value: colorScheme == .dark ? NSColor(
                                    red: 48 / 255,
                                    green: 48 / 255,
                                    blue: 56 / 255,
                                    alpha: 1
                                ) : .init(
                                    red: 238 / 255,
                                    green: 245 / 255,
                                    blue: 254 / 255,
                                    alpha: 1
                                ),
                                range: .init(lineRange, in: temporaryCombinedText)
                            )
                        }
                    }
                inspector
            }
            preview
        }
        .navigationSubtitle("Lyrics")
        .task {
            temporaryCombinedText = combinedText(for: lyrics.lyrics, in: editingField)
            lyricsForPreview = lyrics
        }
        .onDisappear {
            writeBackLyrics(from: temporaryCombinedText, in: editingField, to: &lyrics)
        }
        .onChange(of: editingField) { oldValue, newValue in
            writeBackLyrics(from: temporaryCombinedText, in: oldValue, to: &lyrics)
            temporaryCombinedText = combinedText(for: lyrics.lyrics, in: newValue)
        }
        .onChange(of: appearsActive) {
            if !appearsActive {
                writeBackLyrics(from: temporaryCombinedText, in: editingField, to: &lyrics)
            }
        }
    }
    
    @ViewBuilder
    var inspector: some View {
        VStack {
            Spacer()
            Form {
                Section {
                    Picker("Field", selection: $editingField) {
                        Text("Original").tag(LyricField.original)
                        Text("Translation (JP)").tag(LyricField.translation(.jp))
                        Text("Translation (EN)").tag(LyricField.translation(.en))
                        Text("Translation (TW)").tag(LyricField.translation(.tw))
                        Text("Translation (CN)").tag(LyricField.translation(.cn))
                        Text("Translation (KR)").tag(LyricField.translation(.kr))
                        Text("Ruby (Romaji)").tag(LyricField.rubyRomaji)
                        Text("Ruby (Kana)").tag(LyricField.rubyKana)
                    }
                } header: {
                    Text("Editing")
                }
                if editingField == .original,
                   let currentTextSelection,
                   !currentTextSelection.isInsertion,
                   case let .selection(range) = currentTextSelection.indices,
                   !temporaryCombinedText[range].contains("\n") {
                    Section {
                        Text(temporaryCombinedText[range])
                            .lineLimit(1)
                        if let (lineIndex, lineRange) = lyricsLineRange(from: range) {
                            let lyricLine = lyrics.lyrics[lineIndex]
                            let partialStyle = partialStyle(of: lyricLine, in: lineRange)
                            HStack {
                                if let partialStyle {
                                    TextStyleRender(text: String(temporaryCombinedText[range]), style: partialStyle)
                                        .lineLimit(1)
                                } else {
                                    Text("No Partial Style")
                                }
                                Spacer()
                                if let sourceKey = lyricLine.partialStyle.keys.first(where: { $0.overlaps(lineRange) }) {
                                    Button("Remove", role: .destructive) {
                                        if lyrics.lyrics[lineIndex].partialStyle.removeValue(forKey: lineRange) != nil {
                                            return
                                        }
                                        let sourceKeySet = Set(sourceKey)
                                        let selectedKeySet = Set(lineRange)
                                        lyrics.lyrics[lineIndex].partialStyle.removeValue(forKey: sourceKey)
                                        let sourceDiff = sourceKeySet.subtracting(selectedKeySet).sorted()
                                        if !sourceDiff.isEmpty {
                                            let sourceDiffKey = sourceDiff.first!...sourceDiff.last!
                                            lyrics.lyrics[lineIndex].partialStyle.updateValue(lyricLine.partialStyle[sourceKey]!, forKey: sourceDiffKey)
                                        }
                                    }
                                    .tint(.red)
                                }
                                Button("Edit...") {
                                    let pUpdate = malloc(16)!
                                    let update: (Lyrics.Style) -> Void = { newStyle in
                                        if let sourceKey = lyricLine.partialStyle.keys.first(where: { $0.overlaps(lineRange) }) {
                                            let sourceKeySet = Set(sourceKey)
                                            let selectedKeySet = Set(lineRange)
                                            lyrics.lyrics[lineIndex].partialStyle.removeValue(forKey: sourceKey)
                                            lyrics.lyrics[lineIndex].partialStyle.updateValue(newStyle, forKey: lineRange)
                                            let sourceDiff = sourceKeySet.subtracting(selectedKeySet).sorted()
                                            if !sourceDiff.isEmpty {
                                                let sourceDiffKey = sourceDiff.first!...sourceDiff.last!
                                                lyrics.lyrics[lineIndex].partialStyle.updateValue(lyricLine.partialStyle[sourceKey]!, forKey: sourceDiffKey)
                                            }
                                        } else {
                                            lyrics.lyrics[lineIndex].partialStyle.updateValue(newStyle, forKey: lineRange)
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                                            unsafe pUpdate.deallocate()
                                        }
                                    }
                                    unsafe pUpdate.initializeMemory(as: ((Lyrics.Style) -> Void).self, to: update)
                                    openWindow(
                                        id: "StyleEditor",
                                        value: StyleEditorWindowData(
                                            style: partialStyle ?? lyrics.mainStyle ?? .init(),
                                            update: Int(bitPattern: pUpdate)
                                        )
                                    )
                                }
                            }
                        }
                    } header: {
                        Text("Selected Text")
                    }
                }
            }
            .formStyle(.grouped)
            Spacer()
        }
        .frame(minWidth: 200, idealWidth: 300, maxWidth: 350)
    }
    @ViewBuilder
    var preview: some View {
        VStack {
            HStack {
                Text("Preview")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                ProgressView()
                    .controlSize(.small)
                    .opacity(isPreviewUpdating ? 1 : 0)
                Picker("Secondary Text", selection: $previewSecondaryField) {
                    Text("None").tag(LyricField.original)
                    Text("Translation (JP)").tag(LyricField.translation(.jp))
                    Text("Translation (EN)").tag(LyricField.translation(.en))
                    Text("Translation (TW)").tag(LyricField.translation(.tw))
                    Text("Translation (CN)").tag(LyricField.translation(.cn))
                    Text("Translation (KR)").tag(LyricField.translation(.kr))
                    Text("Ruby (Romaji)").tag(LyricField.rubyRomaji)
                    Text("Ruby (Kana)").tag(LyricField.rubyKana)
                }
            }
            .padding([.horizontal, .top])
            ScrollView {
                HStack {
                    VStack(alignment: .leading, spacing: previewSecondaryField == .original ? 5 : 10) {
                        if let lyrics = lyricsForPreview {
                            ForEach(lyrics.lyrics) { lyricLine in
                                VStack(alignment: .leading, spacing: 0) {
                                    Group {
                                        if let mainStyle = lyrics.mainStyle {
                                            TextStyleRender(text: lyricLine.original, partialStyle: mergingMainStyle(mainStyle, with: lyricLine.partialStyle, for: lyricLine))
                                        } else {
                                            TextStyleRender(text: lyricLine.original, partialStyle: lyricLine.partialStyle)
                                        }
                                    }
                                    .font(.system(size: 20))
                                    if previewSecondaryField != .original {
                                        let secondaryText = switch previewSecondaryField {
                                        case .original:
                                            lyricLine.original
                                        case .translation(let locale):
                                            lyricLine.translations.forLocale(locale) ?? ""
                                        case .rubyRomaji:
                                            lyricLine.ruby?.romaji ?? ""
                                        case .rubyKana:
                                            lyricLine.ruby?.kana ?? ""
                                        }
                                        if !secondaryText.isEmpty {
                                            if let mainStyle = lyrics.mainStyle {
                                                TextStyleRender(text: secondaryText, style: mainStyle)
                                            } else {
                                                TextStyleRender(text: secondaryText, style: .init())
                                            }
                                        }
                                    }
                                }
                            }
                        } else {
                            HStack {
                                Spacer()
                                Text("Preview Unavailable")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.gray)
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    Spacer()
                }
            }
            .mask {
                LinearGradient(colors: [
                    .black.opacity(0),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1),
                    .black.opacity(1)
                ], startPoint: .top, endPoint: .bottom)
            }
        }
        .onChange(of: temporaryCombinedText) {
            isPreviewUpdating = true
            previewUpdateTimer?.invalidate()
            previewUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                DispatchQueue.main.async {
                    var result = lyricsForPreview ?? lyrics
                    writeBackLyrics(from: temporaryCombinedText, in: editingField, to: &result)
                    lyricsForPreview = result
                    isPreviewUpdating = false
                }
            }
        }
        .onChange(of: lyrics) {
            lyricsForPreview = lyrics
        }
    }
    
    func writeBackLyrics(from temporaryText: String, in field: LyricField, to lyrics: inout Lyrics) {
        func setField(_ field: LyricField, of line: inout Lyrics.LyricLine, to text: String?) {
            switch field {
            case .original:
                line.original = text ?? ""
            case .translation(let locale):
                switch locale {
                case .jp:
                    line.translations.jp = text
                case .en:
                    line.translations.en = text
                case .tw:
                    line.translations.tw = text
                case .cn:
                    line.translations.cn = text
                case .kr:
                    line.translations.kr = text
                }
            case .rubyRomaji:
                if line.ruby != nil {
                    line.ruby!.romaji = text ?? ""
                } else {
                    line.ruby = .init(romaji: text ?? "", kana: "")
                }
                if line.ruby == .init(romaji: "", kana: "") {
                    line.ruby = nil
                }
            case .rubyKana:
                if line.ruby != nil {
                    line.ruby!.kana = text ?? ""
                } else {
                    line.ruby = .init(romaji: "", kana: text ?? "")
                }
                if line.ruby == .init(romaji: "", kana: "") {
                    line.ruby = nil
                }
            }
        }
        
        let lineText = temporaryText.components(separatedBy: "\n")
        var lineIterator = lineText.makeIterator()
        var removalLines = IndexSet()
        for case (let index, var lyricLine) in lyrics.lyrics.enumerated() {
            if let text = lineIterator.next() {
                setField(field, of: &lyricLine, to: text)
            } else {
                setField(field, of: &lyricLine, to: nil)
                if lyricLine.original.isEmpty
                    && lyricLine.translations == .init(jp: nil, en: nil, tw: nil, cn: nil, kr: nil)
                    && lyricLine.ruby == nil {
                    removalLines.insert(index)
                    continue
                }
            }
            lyrics.lyrics[index] = lyricLine
        }
        if !removalLines.isEmpty {
            lyrics.lyrics.remove(atOffsets: removalLines)
            return
        }
        while let text = lineIterator.next() {
            var newLine = Lyrics.LyricLine(original: "", translations: .init(jp: nil, en: nil, tw: nil, cn: nil, kr: nil), partialStyle: [:])
            setField(field, of: &newLine, to: text)
            lyrics.lyrics.append(newLine)
        }
    }
    func combinedText(for lyric: [Lyrics.LyricLine], in field: LyricField) -> String {
        lyric.compactMap {
            switch field {
            case .original:
                $0.original
            case .translation(let locale):
                $0.translations.forLocale(locale)
            case .rubyRomaji:
                $0.ruby?.romaji
            case .rubyKana:
                $0.ruby?.kana
            }
        }.joined(separator: "\n")
    }
    func lyricsLineRange(from range: Range<String.Index>) -> (lineIndex: Int, range: ClosedRange<Int>)? {
        let lineIndex = temporaryCombinedText[temporaryCombinedText.startIndex...range.lowerBound].count { $0 == "\n" }
        guard lineIndex < lyrics.lyrics.count else { return nil }
        var resultLower = 0
        while true {
            if let index = temporaryCombinedText.index(range.lowerBound, offsetBy: -resultLower - 1, limitedBy: temporaryCombinedText.startIndex) {
                if temporaryCombinedText[index] == "\n" {
                    break
                }
            } else {
                break
            }
            resultLower += 1
        }
        let resultUpper = resultLower + temporaryCombinedText[range].count - 1
        return (lineIndex, resultLower...resultUpper)
    }
    func partialStyle(of line: Lyrics.LyricLine, in range: ClosedRange<Int>) -> Lyrics.Style? {
        // Find exact match first
        if let style = line.partialStyle[range] {
            return style
        }
        // Find contained
        if let containedStyle = line.partialStyle.first(where: { pair in range.allSatisfy { pair.key.contains($0) } }) {
            return containedStyle.value
        }
        return nil
    }
    func mergingMainStyle(
        _ mainStyle: Lyrics.Style,
        with partialStyle: [ClosedRange<Int>: Lyrics.Style],
        for line: Lyrics.LyricLine
    ) -> [ClosedRange<Int>: Lyrics.Style] {
        var mainRangeSet = Set(0..<line.original.count)
        var result = [ClosedRange<Int>: Lyrics.Style]()
        for (range, style) in partialStyle {
            result.updateValue(style, forKey: range)
            mainRangeSet.subtract(Set(range))
        }
        let mainRanges = mainRangeSet.sorted().reduce(into: [ClosedRange<Int>]()) { ranges, index in
            if let last = ranges.last, index == last.upperBound + 1 {
                ranges[ranges.count - 1] = last.lowerBound...index
            } else {
                ranges.append(index...index)
            }
        }
        for range in mainRanges {
            result.updateValue(mainStyle, forKey: range)
        }
        return result
    }
    
    enum LyricField: Hashable {
        case original
        case translation(DoriAPI.Locale)
        case rubyRomaji
        case rubyKana
    }
}
