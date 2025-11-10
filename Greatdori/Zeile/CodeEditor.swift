//===---*- Greatdori! -*---------------------------------------------------===//
//
// CodeEditor.swift
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
import SwiftUI
import DoriKit
import Carbon.HIToolbox.Events

#if os(macOS)
struct CodeEditor: NSViewRepresentable {
    @Binding var text: String
    let textView = CodeTextView()
    func makeNSView(context: Context) -> NSScrollView {
        textView.string = text
        updateAttributes()
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.delegate = context.coordinator
        
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView
        
        let lineNumberView = LineNumberView(textView: textView)
        scrollView.verticalRulerView = lineNumberView
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        
        textView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(
            forName: NSView.frameDidChangeNotification,
            object: textView,
            queue: .main
        ) { _ in
            lineNumberView.needsDisplay = true
        }
        NotificationCenter.default.addObserver(
            forName: NSView.boundsDidChangeNotification,
            object: scrollView.contentView,
            queue: .main
        ) { _ in
            lineNumberView.needsDisplay = true
        }
        NotificationCenter.default.addObserver(
            forName: NSText.didChangeNotification,
            object: textView,
            queue: .main
        ) { _ in
            lineNumberView.needsDisplay = true
        }
        
        return scrollView
    }
    func updateNSView(_ nsView: NSViewType, context: Context) {
        updateAttributes()
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func updateAttributes() {
        if let storage = unsafe textView.textStorage {
            DoriStoryBuilder().syntaxHighlight(for: storage)
        }
        unsafe textView.textStorage?.addAttribute(
            .font,
            value: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            range: .init(location: 0, length: textView.textStorage!.length)
        )
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: CodeEditor
        
        init(parent: CodeEditor) {
            self.parent = parent
        }
        
        // Prevent cycle selection change
        private var isSettingSelectionRange = false
        
        func textDidChange(_ notification: Notification) {
            parent.text = parent.textView.string
            parent.updateAttributes()
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard !isSettingSelectionRange else { return }
            
            let selectedLocation = parent.textView.selectedRange().location
            let currentString = parent.textView.string
            let selectedIndex = currentString.index(
                currentString.startIndex,
                offsetBy: selectedLocation
            )
            var placeholderStartIndex: String.Index?
            var placeholderEndIndex: String.Index?
            var checkingIndex = selectedIndex
            while checkingIndex > currentString.startIndex && checkingIndex < currentString.endIndex {
                let char = currentString[checkingIndex]
                if char == "<" {
                    guard checkingIndex < currentString.endIndex else { break }
                    let nextIndex = currentString.index(after: checkingIndex)
                    guard nextIndex < currentString.endIndex else { break }
                    let nextChar = currentString[nextIndex]
                    if nextChar == "#" {
                        placeholderStartIndex = checkingIndex
                        break
                    }
                } else if char == "\n" || char == ">" {
                    break
                }
                currentString.formIndex(before: &checkingIndex)
            }
            checkingIndex = selectedIndex
            while checkingIndex < currentString.endIndex {
                let char = currentString[checkingIndex]
                if char == ">" {
                    guard checkingIndex > currentString.startIndex else { break }
                    let previousIndex = currentString.index(before: checkingIndex)
                    let previousChar = currentString[previousIndex]
                    if previousChar == "#" {
                        placeholderEndIndex = checkingIndex
                        break
                    }
                } else if char == "\n" || char == "<" {
                    break
                }
                currentString.formIndex(after: &checkingIndex)
            }
            if let startIndex = placeholderStartIndex,
               let endIndex = placeholderEndIndex {
                isSettingSelectionRange = true
                parent.textView.setSelectedRange(
                    .init(startIndex...endIndex, in: parent.textView.string)
                )
                isSettingSelectionRange = false
            }
            
            if (abs(parent.textView.selectedRange.location - parent.textView.lastPos) > 1) {
                parent.textView.showingAutoCompletionPanel?.close()
                parent.textView.showingAutoCompletionPanel = nil
            }
            parent.textView.lastPos = parent.textView.selectedRange.location
        }
    }
    
    class CodeTextView: NSTextView {
        var showingAutoCompletionPanel: NSPanel?
        var lastPos: Int = -1
        
        override func keyDown(with event: NSEvent) {
            switch event.keyCode {
            case UInt16(kVK_ANSI_Period):
                super.keyDown(with: event)
                showAutoCompletion()
//            case UInt16(kVK_Delete):
//                super.keyDown(with: event)
//                showingAutoCompletionPanel?.close()
//                showingAutoCompletionPanel = nil
            case UInt16(kVK_Escape):
                if showingAutoCompletionPanel == nil {
                    showAutoCompletion()
                } else {
                    showingAutoCompletionPanel?.close()
                    showingAutoCompletionPanel = nil
                }
            case UInt16(kVK_UpArrow):
                if showingAutoCompletionPanel != nil {
                    CodeCompletionView.previousItemSubject.send()
                } else {
                    super.keyDown(with: event)
                }
            case UInt16(kVK_DownArrow):
                if showingAutoCompletionPanel != nil {
                    CodeCompletionView.nextItemSubject.send()
                } else {
                    super.keyDown(with: event)
                }
            case UInt16(kVK_Return), UInt16(kVK_Tab):
                if showingAutoCompletionPanel != nil {
                    CodeCompletionView.getCurrentSubject.send({ item in
                        let currentLoc = self.selectedRange().location
                        let newLoc = currentLoc + item.replacingLength
                        self.string = item.replacedCode
                        self.setSelectedRange(.init(location: newLoc, length: 0))
                        self.delegate?.textDidChange?(.init(name: NSTextView.didChangeNotification))
                    })
                } else {
                    let selectedRange = self.selectedRange()
                    let selectedText = self.string[Range(selectedRange, in: self.string)!]
                    if selectedText.hasPrefix("<#")
                        && selectedText.hasSuffix("#>") {
                        let newText = selectedText.dropFirst(2).dropLast(2)
                        self.replaceCharacters(
                            in: selectedRange,
                            with: String(newText)
                        )
                        self.delegate?.textDidChange?(.init(name: NSTextView.didChangeNotification))
                    } else {
                        super.keyDown(with: event)
                    }
                }
            case let c where [
                kVK_ANSI_A,
                kVK_ANSI_B,
                kVK_ANSI_C,
                kVK_ANSI_D,
                kVK_ANSI_E,
                kVK_ANSI_F,
                kVK_ANSI_G,
                kVK_ANSI_H,
                kVK_ANSI_I,
                kVK_ANSI_J,
                kVK_ANSI_K,
                kVK_ANSI_L,
                kVK_ANSI_M,
                kVK_ANSI_N,
                kVK_ANSI_O,
                kVK_ANSI_P,
                kVK_ANSI_Q,
                kVK_ANSI_R,
                kVK_ANSI_S,
                kVK_ANSI_T,
                kVK_ANSI_U,
                kVK_ANSI_V,
                kVK_ANSI_W,
                kVK_ANSI_X,
                kVK_ANSI_Y,
                kVK_ANSI_Z,
            ].map { UInt16($0) }.contains(c):
                super.keyDown(with: event)
                showAutoCompletion()
            default:
                super.keyDown(with: event)
                // Update auto completion content
                if showingAutoCompletionPanel != nil {
                    showAutoCompletion()
                }
            }
        }
        
        func caretRectInWindow() -> NSRect? {
            guard let textContainer = unsafe self.textContainer,
                  let layoutManager = unsafe self.layoutManager else { return nil }
            
            let selectedRange = self.selectedRange()
            let location = min(selectedRange.location, self.string.count)
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: location)
            
            var rect = layoutManager.boundingRect(
                forGlyphRange: NSRange(location: glyphIndex, length: 0),
                in: textContainer
            )
            
            let origin = self.textContainerOrigin
            rect.origin.x += origin.x
            rect.origin.y += origin.y
            
            return self.convert(rect, to: nil)
        }
        
        func showAutoCompletion() {
            Task {
                let code = self.string
                guard var index = Range(self.selectedRange(), in: code)?.lowerBound,
                      index > code.startIndex else {
                    return
                }
                code.formIndex(before: &index)
                let items = await asyncCompleteCode(code, at: index)
                
                showingAutoCompletionPanel?.close()
                showingAutoCompletionPanel = nil
                
                guard !items.isEmpty else { return }
                
                guard let rect = caretRectInWindow() else { return }
                
                let autocompletePanel: NSPanel = {
                    let panel = NSPanel(
                        contentRect: .zero,
                        styleMask: [.borderless],
                        backing: .buffered,
                        defer: false
                    )
                    panel.level = .floating
                    panel.isOpaque = false
                    panel.backgroundColor = .clear
                    panel.hasShadow = true
                    panel.ignoresMouseEvents = false
                    panel.hidesOnDeactivate = true
                    panel.collectionBehavior = [.canJoinAllSpaces, .transient]
                    return panel
                }()
                
                var size = CGSize(width: 300, height: 150)
                for item in items {
                    var newSize = item.displayName.size()
                    newSize.width += 60
                    if newSize.width > size.width {
                        size.width = newSize.width
                    }
                }
                
                let contentView = NSHostingView(
                    rootView: CodeCompletionView(items: items, size: size)
                )
                
                autocompletePanel.contentView = contentView
                
                if let window = unsafe self.window {
                    var panelFrame = contentView.frame
                    panelFrame.size = size
                    panelFrame.origin = rect.origin
                    panelFrame.origin.y -= panelFrame.height
                    panelFrame.origin = window.convertToScreen(panelFrame).origin
                    
                    autocompletePanel.setFrame(panelFrame, display: true)
                    autocompletePanel.orderFront(nil)
                    showingAutoCompletionPanel = autocompletePanel
                }
            }
        }
    }
    
    class LineNumberView: NSRulerView {
        var font: NSFont! {
            didSet {
                self.needsDisplay = true
            }
        }
        
        init(textView: NSTextView) {
            super.init(scrollView: textView.enclosingScrollView!, orientation: .verticalRuler)
            self.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
            self.clientView = textView
            
            self.ruleThickness = 40
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func drawHashMarksAndLabels(in rect: NSRect) {
            if let textView = self.clientView as? NSTextView {
                if let layoutManager = unsafe textView.layoutManager {
                    let relativePoint = self.convert(NSZeroPoint, from: textView)
                    let lineNumberAttributes: [NSAttributedString.Key: Any] = [.font: textView.font!, .foregroundColor: NSColor.gray]
                    
                    let drawLineNumber = { (lineNumberString:String, y:CGFloat) -> Void in
                        let attString = NSAttributedString(string: lineNumberString, attributes: lineNumberAttributes)
                        let x = 35 - attString.size().width
                        attString.draw(at: NSPoint(x: x, y: relativePoint.y + y))
                    }
                    
                    let visibleGlyphRange = unsafe layoutManager.glyphRange(
                        forBoundingRect: textView.visibleRect,
                        in: textView.textContainer!
                    )
                    let firstVisibleGlyphCharacterIndex = layoutManager.characterIndexForGlyph(at: visibleGlyphRange.location)
                    
                    let newLineRegex = try! NSRegularExpression(pattern: "\n", options: [])
                    // The line number for the first visible line
                    var lineNumber = newLineRegex.numberOfMatches(in: textView.string, options: [], range: NSMakeRange(0, firstVisibleGlyphCharacterIndex)) + 1
                    
                    var glyphIndexForStringLine = visibleGlyphRange.location
                    
                    // Go through each line in the string.
                    while glyphIndexForStringLine < NSMaxRange(visibleGlyphRange) {
                        
                        // Range of current line in the string.
                        let characterRangeForStringLine = (textView.string as NSString).lineRange(
                            for: NSMakeRange( layoutManager.characterIndexForGlyph(at: glyphIndexForStringLine), 0 )
                        )
                        let glyphRangeForStringLine = layoutManager.glyphRange(forCharacterRange: characterRangeForStringLine, actualCharacterRange: nil)
                        
                        var glyphIndexForGlyphLine = glyphIndexForStringLine
                        var glyphLineCount = 0
                        
                        while ( glyphIndexForGlyphLine < NSMaxRange(glyphRangeForStringLine) ) {
                            
                            // See if the current line in the string spread across
                            // several lines of glyphs
                            var effectiveRange = NSMakeRange(0, 0)
                            
                            // Range of current "line of glyphs". If a line is wrapped,
                            // then it will have more than one "line of glyphs"
                            let lineRect = unsafe layoutManager.lineFragmentRect(
                                forGlyphAt: glyphIndexForGlyphLine,
                                effectiveRange: &effectiveRange,
                                withoutAdditionalLayout: true
                            )
                            
                            if glyphLineCount > 0 {
                                drawLineNumber("-", lineRect.minY)
                            } else {
                                drawLineNumber("\(lineNumber)", lineRect.minY)
                            }
                            
                            // Move to next glyph line
                            glyphLineCount += 1
                            glyphIndexForGlyphLine = NSMaxRange(effectiveRange)
                        }
                        
                        glyphIndexForStringLine = NSMaxRange(glyphRangeForStringLine)
                        lineNumber += 1
                    }
                    
                    // Draw line number for the extra line at the end of the text
                    if layoutManager.extraLineFragmentTextContainer != nil {
                        drawLineNumber("\(lineNumber)", layoutManager.extraLineFragmentRect.minY)
                    }
                }
            }
        }
    }
}
#endif

private struct CodeCompletionView: View {
    static let nextItemSubject = PassthroughSubject<Void, Never>()
    static let previousItemSubject = PassthroughSubject<Void, Never>()
    static let getCurrentSubject = PassthroughSubject<(CodeCompletionItem) -> Void, Never>()
    
    var items: [CodeCompletionItem]
    var size: CGSize
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedItemIndex = 0
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    if !items.isEmpty {
                        ForEach(Array(items.enumerated()), id: \.element.self) { index, result in
                            HStack(spacing: 5) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill({
                                            switch result.itemType {
                                            case .variable:
                                                Color.orange
                                            case .function:
                                                Color.green
                                            case .staticMethod:
                                                Color.cyan
                                            case .instanceMethod:
                                                Color.blue
                                            case .structure:
                                                Color.purple
                                            case .enumeration:
                                                Color.orange
                                            case .keyword:
                                                Color.gray
                                            @unknown default: Color.red
                                            }
                                        }())
                                        .frame(width: 15, height: 15)
                                    Group {
                                        switch result.itemType {
                                        case .function:
                                            Image(systemName: "f.cursive")
                                        case .staticMethod:
                                            Text(verbatim: "M")
                                        case .instanceMethod:
                                            Text(verbatim: "I")
                                        case .keyword:
                                            Image(systemName: "circle")
                                        default:
                                            Text(result.itemType.rawValue.first!.uppercased())
                                        }
                                    }
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(.white)
                                }
                                Text(AttributedString(result.displayName))
                                Spacer()
                            }
                            .padding(3)
                            .padding(.horizontal, 2)
                            .background {
                                if index == selectedItemIndex {
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(
                                            colorScheme == .light
                                            ? Color.white.opacity(0.6)
                                            : .gray.opacity(0.4)
                                        )
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedItemIndex = index
                            }
                        }
                    }
                }
                .padding(5)
            }
            if !items.isEmpty {
                let item = items[selectedItemIndex]
                Divider()
                VStack {
                    HStack {
                        Text(AttributedString(item.declaration))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                        Spacer(minLength: 0)
                    }
                }
                .padding(5)
            }
        }
        .frame(width: size.width, height: size.height)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(Material.regular)
        }
        .onReceive(Self.nextItemSubject) { _ in
            let newIndex = selectedItemIndex + 1
            if items.startIndex..<items.endIndex ~= newIndex {
                selectedItemIndex = newIndex
            }
        }
        .onReceive(Self.previousItemSubject) { _ in
            let newIndex = selectedItemIndex - 1
            if items.startIndex..<items.endIndex ~= newIndex {
                selectedItemIndex = newIndex
            }
        }
        .onReceive(Self.getCurrentSubject) { action in
            action(items[selectedItemIndex])
        }
    }
}

private func asyncCompleteCode(
    _ code: String,
    at index: String.Index
) async -> [CodeCompletionItem] {
    await withCheckedContinuation { continuation in
        DispatchQueue(label: "com.memz233.Greatdori.Zeile.Code-Completion", qos: .userInitiated).async {
            continuation.resume(returning: DoriStoryBuilder().completeCode(code, at: index))
        }
    }
}
