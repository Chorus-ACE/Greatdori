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
import SDWebImageSwiftUI

#if os(macOS)
import Carbon.HIToolbox.Events

struct CodeEditor: NSViewRepresentable {
    static let textFinderSubject: PassthroughSubject<(NSTextFinder) -> Void, Never> = .init()
    
    @Binding var text: String
    var locale: DoriLocale
    var assetFolder: FileWrapper?
    let textView = CodeTextView(usingTextLayoutManager: true)
    let textFinder: NSTextFinder
    
    private let textFinderSubscription: AnyCancellable
    
    init(text: Binding<String>, locale: DoriLocale, assetFolder: FileWrapper? = nil) {
        self._text = text
        self.locale = locale
        self.assetFolder = assetFolder
        let textFinder = NSTextFinder()
        self.textFinder = textFinder
        self.textFinderSubscription = Self.textFinderSubject.sink { action in
            action(textFinder)
        }
    }
    
    func makeNSView(context: Context) -> NSScrollView {
        textView.string = text
        updateAttributes()
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.delegate = context.coordinator
        textView.backgroundColor = .init(.zeileEditorBackground)
        
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.documentView = textView
        
        let lineNumberView = LineNumberView(textView: textView)
        scrollView.verticalRulerView = lineNumberView
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        
        unsafe self.textFinder.client = textView
        unsafe self.textFinder.findBarContainer = scrollView
        
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
        
        context.coordinator.environment = context.environment
        
        return scrollView
    }
    func updateNSView(_ nsView: NSViewType, context: Context) {
        updateAttributes()
        context.coordinator.environment = context.environment
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func updateAttributes() {
        if let storage = unsafe textView.textStorage {
            DoriStoryBuilder(for: locale).syntaxHighlight(for: storage)
        }
        unsafe textView.textStorage?.addAttribute(
            .font,
            value: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            range: .init(location: 0, length: textView.textStorage!.length)
        )
    }
    func updateDiags(_ sender: Coordinator) {
        let code = textView.string
        sender.diagUpdateTask?.cancel()
        sender.diagUpdateTask = Task.detached {
            let diags = DoriStoryBuilder(for: locale).generateDiagnostics(for: code)
            await MainActor.run {
                textView.diagnostics = diags
                textView.needsDisplay = true
                sender.environment?.onDiagnosticsUpdate(diags)
            }
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate, @unchecked Sendable {
        var parent: CodeEditor
        
        init(parent: CodeEditor) {
            self.parent = parent
        }
        
        var environment: EnvironmentValues?
        var diagUpdateTask: Task<Void, Never>?
        
        // Prevent cycle selection change
        private var isSettingSelectionRange = false
        
        var locale: DoriLocale {
            parent.locale
        }
        var assetFolder: FileWrapper? {
            parent.assetFolder
        }
        
        func textDidChange(_ notification: Notification) {
            parent.text = parent.textView.string
            parent.updateAttributes()
            parent.updateDiags(self)
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
    
    class CodeTextView: NSTextView, @MainActor NSTextFinderClient {
        var showingAutoCompletionPanel: NSPanel?
        var lastPos: Int = -1
        var diagnostics: [Diagnostic] = []
        fileprivate var inlineDiagViews: [NSHostingView<InlineDiagnosticView>] = []
        
        override func keyDown(with event: NSEvent) {
            let nominalModifier = event.modifierFlags.isDisjoint(
                with: [.shift, .function, .control, .option, .command]
            )
            
            switch event.keyCode {
            case UInt16(kVK_ANSI_Period):
                super.keyDown(with: event)
                showAutoCompletion()
            case UInt16(kVK_ANSI_Quote) where event.modifierFlags.contains(.shift):
                super.keyDown(with: event)
                let location = self.selectedRange().location - 2
                guard location > 0 else { return }
                let text = self.string
                var currentIndex = text.index(text.startIndex, offsetBy: location)
                var hasAnotherQuote = false
                while currentIndex > text.startIndex && currentIndex < text.endIndex {
                    let char = text[currentIndex]
                    if char == "\"" {
                        hasAnotherQuote = true
                        break
                    } else if char == "\n" {
                        break
                    }
                    text.formIndex(before: &currentIndex)
                }
                if !hasAnotherQuote {
                    self.replaceCharacters(
                        in: .init(location: location + 2, length: 0),
                        with: "\""
                    )
                    self.setSelectedRange(
                        .init(location: location + 2, length: 0)
                    )
                    self.delegate?.textDidChange?(.init(name: NSTextView.didChangeNotification))
                    showAutoCompletion()
                }
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
                        self.string = item.replacedCode
                        self.delegate?.textDidChange?(.init(name: NSTextView.didChangeNotification))
                        self.setSelectedRange(.init(location: currentLoc, length: 0))
                        if !self.selectPlaceholder() {
                            let newLoc = currentLoc + item.replacingLength
                            self.setSelectedRange(.init(location: newLoc, length: 0))
                        }
                    })
                } else {
                    if event.keyCode == UInt16(kVK_Return) {
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
                    } else {
                        if !selectPlaceholder() {
                            if selectPlaceholder(previous: true) {
                                while selectPlaceholder(previous: true) {}
                            } else {
                                super.keyDown(with: event)
                            }
                        }
                    }
                }
            case let c where nominalModifier && [
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
                kVK_ANSI_0,
                kVK_ANSI_1,
                kVK_ANSI_2,
                kVK_ANSI_3,
                kVK_ANSI_4,
                kVK_ANSI_5,
                kVK_ANSI_6,
                kVK_ANSI_7,
                kVK_ANSI_8,
                kVK_ANSI_9,
                kVK_ANSI_Slash
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
        
        override func drawBackground(in rect: NSRect) {
            super.drawBackground(in: rect)
            
            for view in self.inlineDiagViews {
                view.removeFromSuperview()
            }
            self.inlineDiagViews.removeAll()
            
            guard let layoutManager = unsafe layoutManager,
                  let textContainer = unsafe textContainer else { return }
            
            var lineRanges: [NSRange] = []
            var rangeStartIndex = self.string.startIndex
            var currentIndex = self.string.startIndex
            while currentIndex < self.string.endIndex {
                let char = self.string[currentIndex]
                if char == "\n" {
                    lineRanges.append(
                        .init(rangeStartIndex..<currentIndex, in: self.string)
                    )
                    rangeStartIndex = self.string.index(after: currentIndex)
                }
                self.string.formIndex(after: &currentIndex)
            }
            
            for (line, range) in lineRanges.enumerated() {
                if let message = diagnostics.first(where: { $0.line == line + 1 }) {
                    let rect = layoutManager.boundingRect(
                        forGlyphRange: range,
                        in: textContainer
                    )
                    
                    let diagSize = CGSize(width: self.frame.width - rect.width - 5,
                                          height: rect.height)
                    let diagView = NSHostingView(rootView: InlineDiagnosticView(
                        diagnostic: message,
                        size: diagSize
                    ))
                    diagView.frame = .init(
                        x: rect.width + 5,
                        y: rect.minY,
                        width: diagSize.width,
                        height: diagSize.height
                    )
                    self.inlineDiagViews.append(diagView)
                    self.addSubview(diagView)
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
                let coordinator = (self.delegate as! Coordinator)
                let items = await asyncCompleteCode(
                    code,
                    at: index,
                    in: coordinator.locale,
                    assetFolder: coordinator.assetFolder
                )
                
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
                let hasPreviewContent = items.contains { $0.previewContent != nil }
                for item in items {
                    var newSize = item.displayName.size()
                    if hasPreviewContent {
                        newSize.width += 200
                    }
                    newSize.width += 60
                    if newSize.width > size.width {
                        size.width = newSize.width
                    }
                }
                
                let contentView = NSHostingView(
                    rootView: CodeCompletionView(
                        items: items,
                        size: size,
                        hasPreviewContent: hasPreviewContent
                    )
                )
                
                autocompletePanel.contentView = contentView
                
                if let window = unsafe self.window {
                    var panelFrame = contentView.frame
                    panelFrame.size = size
                    panelFrame.origin = rect.origin
                    panelFrame.origin.y -= panelFrame.height
                    panelFrame.origin = window.convertToScreen(panelFrame).origin
                    
                    if let screen = window.screen {
                        let visibleFrame = screen.visibleFrame
                        
                        if panelFrame.maxX > visibleFrame.maxX {
                            panelFrame.origin.x = visibleFrame.maxX - panelFrame.width
                        }
                        if panelFrame.minX < visibleFrame.minX {
                            panelFrame.origin.x = visibleFrame.minX
                        }
                        if panelFrame.maxY > visibleFrame.maxY {
                            panelFrame.origin.y = visibleFrame.maxY - panelFrame.height
                        }
                        if panelFrame.minY < visibleFrame.minY {
                            panelFrame.origin.y = visibleFrame.minY
                        }
                    }
                    
                    autocompletePanel.setFrame(panelFrame, display: true)
                    autocompletePanel.orderFront(nil)
                    showingAutoCompletionPanel = autocompletePanel
                }
            }
        }
        
        @discardableResult
        func selectPlaceholder(previous: Bool = false) -> Bool {
            let _range = self.selectedRange()
            var currentLoc = _range.location
            if previous {
                currentLoc -= 1
                if currentLoc < 0 { return false }
            } else {
                currentLoc += _range.length
            }
            let currentString = self.string
            let selectedIndex = currentString.index(
                currentString.startIndex,
                offsetBy: currentLoc
            )
            var placeholderStartIndex: String.Index?
            var placeholderEndIndex: String.Index?
            var checkingIndex = selectedIndex
            while checkingIndex > currentString.startIndex && checkingIndex < currentString.endIndex {
                let char = currentString[checkingIndex]
                if char == "<" {
                    let nextIndex = currentString.index(after: checkingIndex)
                    guard nextIndex < currentString.endIndex else { break }
                    let nextChar = currentString[nextIndex]
                    if nextChar == "#" {
                        placeholderStartIndex = checkingIndex
                        break
                    }
                } else if char == "\n" {
                    break
                }
                if previous {
                    currentString.formIndex(before: &checkingIndex)
                } else {
                    currentString.formIndex(after: &checkingIndex)
                }
            }
            guard let placeholderStartIndex else { return false }
            checkingIndex = placeholderStartIndex
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
                } else if char == "\n" {
                    break
                }
                currentString.formIndex(after: &checkingIndex)
            }
            if let endIndex = placeholderEndIndex {
                self.setSelectedRange(
                    .init(placeholderStartIndex...endIndex, in: currentString)
                )
                return true
            }
            return false
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
            self.wantsLayer = true
            self.layer?.masksToBounds = true
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
                                drawLineNumber(" ", lineRect.minY)
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
#else // os(macOS)
struct CodeEditor: UIViewRepresentable {
    @Binding var text: String
    var locale: DoriLocale
    var assetFolder: FileWrapper? = nil
    let textView = CodeTextView(usingTextLayoutManager: true)
    
    func makeUIView(context: Context) -> CodeTextView {
        textView.text = text
        updateAttributes()
        textView.smartQuotesType = .no
        textView.smartDashesType = .no
        textView.autocorrectionType = .no
        textView.spellCheckingType = .no
        textView.autocapitalizationType = .none
        textView.inlinePredictionType = .no
        textView.smartInsertDeleteType = .no
        textView.delegate = context.coordinator
        
        context.coordinator.environment = context.environment
        
        return textView
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {
        updateAttributes()
        context.coordinator.environment = context.environment
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func updateAttributes() {
        let storage = textView.textStorage
        storage.beginEditing()
        DoriStoryBuilder(for: locale).syntaxHighlight(for: storage)
        storage.addAttribute(
            .font,
            value: UIFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            range: .init(location: 0, length: storage.length)
        )
        storage.edited(
            .editedAttributes,
            range: .init(location: 0, length: storage.length),
            changeInLength: 0
        )
        storage.endEditing()
    }
    func updateDiags(_ sender: Coordinator) {
        let code = textView.text!
        sender.diagUpdateTask?.cancel()
        sender.diagUpdateTask = Task.detached {
            let diags = DoriStoryBuilder(for: locale).generateDiagnostics(for: code)
            await MainActor.run {
                textView.diagnostics = diags
                textView.setNeedsDisplay()
                sender.environment?.onDiagnosticsUpdate(diags)
            }
        }
    }
    
    class Coordinator: NSObject, UITextViewDelegate, @unchecked Sendable {
        var parent: CodeEditor
        
        init(parent: CodeEditor) {
            self.parent = parent
        }
        
        var environment: EnvironmentValues?
        var diagUpdateTask: Task<Void, Never>?
        
        // Prevent cycle selection change
        private var isSettingSelectionRange = false
        
        var locale: DoriLocale {
            parent.locale
        }
        var assetFolder: FileWrapper? {
            parent.assetFolder
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = parent.textView.text
            parent.updateAttributes()
            parent.updateDiags(self)
            textView.layoutSubviews()
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !isSettingSelectionRange else { return }
            
            let selectedLocation = parent.textView.selectedRange.location
            let currentString = parent.textView.text!
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
                parent.textView.selectedRange =
                    .init(startIndex...endIndex, in: parent.textView.text)
                isSettingSelectionRange = false
            }
            
            if (abs(parent.textView.selectedRange.location - parent.textView.lastPos) > 1) {
                parent.textView.showingAutoCompletionView?.removeFromSuperview()
                parent.textView.showingAutoCompletionView = nil
            }
            parent.textView.lastPos = parent.textView.selectedRange.location
        }
    }
    
    class CodeTextView: UITextView {
        var showingAutoCompletionView: UIView?
        var lastPos: Int = -1
        var diagnostics: [Diagnostic] = []
        fileprivate var inlineDiagViews: [_UIHostingView<InlineDiagnosticView>] = []
        private var lineNumberView: LineNumberView?
        
        override func layoutSubviews() {
            super.layoutSubviews()
            
            // Draw line number
            var isInitialLineNumberView = false
            if lineNumberView == nil {
                lineNumberView = .init(textView: self)
                isInitialLineNumberView = true
            }
            let lineCount = self.text.count { $0 == "\n" }
            let lineNumberLength = String(lineCount).count
            let lineNumberWidth: CGFloat = CGFloat(lineNumberLength) * 15.0
            self.textContainerInset.left = lineNumberWidth
            lineNumberView?.frame.size.width = lineNumberWidth
            lineNumberView?.frame.size.height = self.layoutManager.usedRect(
                for: self.textContainer
            ).height + self.textContainerInset.top
            if isInitialLineNumberView {
                self.addSubview(lineNumberView!)
            }
            lineNumberView?.setNeedsDisplay()
        }
        
        // The default implementation is really broken
        // for our range representation. We have to use the
        // private class `NSCountableTextRange` in UIFoundation
        // to make our custom `CodeTextRange` work,
        // which is not allowed on the App Store.
        // Therefore, we have to provide a implementation
        // for this method by our own
        override func replace(_ range: UITextRange, withText text: String) {
            guard let range = range as? CodeTextRange else {
                super.replace(range, withText: text)
                return
            }
            
            self.textStorage.replaceCharacters(in: range.range, with: text)
        }
        
        override func insertText(_ text: String) {
            switch text {
            case ".":
                super.insertText(text)
                showAutoCompletion()
            case "\"":
                super.insertText(text)
                let location = self.selectedRange.location - 2
                guard location > 0 else { return }
                let text = self.text!
                var currentIndex = text.index(text.startIndex, offsetBy: location)
                var hasAnotherQuote = false
                while currentIndex > text.startIndex && currentIndex < text.endIndex {
                    let char = text[currentIndex]
                    if char == "\"" {
                        hasAnotherQuote = true
                        break
                    } else if char == "\n" {
                        break
                    }
                    text.formIndex(before: &currentIndex)
                }
                if !hasAnotherQuote {
                    self.replace(
                        CodeTextRange(location: location + 2, length: 0),
                        withText: "\""
                    )
                    self.selectedRange = .init(location: location + 2, length: 0)
                    self.delegate?.textViewDidChange?(self)
                    showAutoCompletion()
                }
//            case UInt16(kVK_Escape):
//                if showingAutoCompletionView == nil {
//                    showAutoCompletion()
//                } else {
//                    showingAutoCompletionView?.close()
//                    showingAutoCompletionView = nil
//                }
//            case UInt16(kVK_UpArrow):
//                if showingAutoCompletionView != nil {
//                    CodeCompletionView.previousItemSubject.send()
//                } else {
//                    super.keyDown(with: event)
//                }
//            case UInt16(kVK_DownArrow):
//                if showingAutoCompletionView != nil {
//                    CodeCompletionView.nextItemSubject.send()
//                } else {
//                    super.keyDown(with: event)
//                }
            case "\n", "\u{9}":
                if showingAutoCompletionView != nil {
                    CodeCompletionView.getCurrentSubject.send({ item in
                        let currentLoc = self.selectedRange.location
                        self.text = item.replacedCode
                        self.delegate?.textViewDidChange?(self)
                        self.selectedRange = .init(location: currentLoc, length: 0)
                        if !self.selectPlaceholder() {
                            let newLoc = currentLoc + item.replacingLength
                            self.selectedRange = .init(location: newLoc, length: 0)
                        }
                    })
                } else {
                    if text == "\n" {
                        let selectedRange = self.selectedRange
                        let selectedText = self.text[Range(selectedRange, in: self.text)!]
                        if selectedText.hasPrefix("<#")
                            && selectedText.hasSuffix("#>") {
                            let newText = selectedText.dropFirst(2).dropLast(2)
                            self.replace(CodeTextRange(selectedRange), withText: String(newText))
                            self.delegate?.textViewDidChange?(self)
                        } else {
                            super.insertText(text)
                        }
                    } else {
                        if !selectPlaceholder() {
                            if selectPlaceholder(previous: true) {
                                while selectPlaceholder(previous: true) {}
                            } else {
                                super.insertText(text)
                            }
                        }
                    }
                }
            case let c where "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_".contains(c):
                super.insertText(text)
                showAutoCompletion()
            default:
                super.insertText(text)
                // Update auto completion content
                if showingAutoCompletionView != nil {
                    showAutoCompletion()
                }
            }
        }
        
        // If the code completion view is presenting
        // and users deletes any character,
        // we need to refresh the content in the completion view
        override func deleteBackward() {
            super.deleteBackward()
            
            if showingAutoCompletionView != nil {
                showAutoCompletion()
            }
        }
        
//        override func drawBackground(in rect: NSRect) {
//            super.drawBackground(in: rect)
//            
//            for view in self.inlineDiagViews {
//                view.removeFromSuperview()
//            }
//            self.inlineDiagViews.removeAll()
//            
//            guard let layoutManager = unsafe layoutManager,
//                  let textContainer = unsafe textContainer else { return }
//            
//            var lineRanges: [NSRange] = []
//            var rangeStartIndex = self.string.startIndex
//            var currentIndex = self.string.startIndex
//            while currentIndex < self.string.endIndex {
//                let char = self.string[currentIndex]
//                if char == "\n" {
//                    lineRanges.append(
//                        .init(rangeStartIndex..<currentIndex, in: self.string)
//                    )
//                    rangeStartIndex = self.string.index(after: currentIndex)
//                }
//                self.string.formIndex(after: &currentIndex)
//            }
//            
//            for (line, range) in lineRanges.enumerated() {
//                if let message = diagnostics.first(where: { $0.line == line + 1 }) {
//                    let rect = layoutManager.boundingRect(
//                        forGlyphRange: range,
//                        in: textContainer
//                    )
//                    
//                    let diagSize = CGSize(width: self.frame.width - rect.width - 5,
//                                          height: rect.height)
//                    let diagView = NSHostingView(rootView: InlineDiagnosticView(
//                        diagnostic: message,
//                        size: diagSize
//                    ))
//                    diagView.frame = .init(
//                        x: rect.width + 5,
//                        y: rect.minY,
//                        width: diagSize.width,
//                        height: diagSize.height
//                    )
//                    self.inlineDiagViews.append(diagView)
//                    self.addSubview(diagView)
//                }
//            }
//        }
        
        func caretRectInView() -> CGRect? {
            let selectedRange = self.selectedRange
            let location = min(selectedRange.location, self.text.count)
            let glyphIndex = layoutManager.glyphIndexForCharacter(at: location)
            
            let rect = layoutManager.boundingRect(
                forGlyphRange: NSRange(location: glyphIndex, length: 0),
                in: textContainer
            )
            
            return rect
        }
        
        func showAutoCompletion() {
            Task {
                let code = self.text!
                guard var index = Range(self.selectedRange, in: code)?.lowerBound,
                      index > code.startIndex else {
                    return
                }
                code.formIndex(before: &index)
                let coordinator = (self.delegate as! Coordinator)
                let items = await asyncCompleteCode(
                    code,
                    at: index,
                    in: coordinator.locale,
                    assetFolder: coordinator.assetFolder
                )
                
                showingAutoCompletionView?.removeFromSuperview()
                showingAutoCompletionView = nil
                
                guard !items.isEmpty else { return }
                
                guard let rect = caretRectInView() else { return }
                
                var size = CGSize(width: 300, height: 150)
                let hasPreviewContent = items.contains { $0.previewContent != nil }
                for item in items {
                    var newSize = item.displayName.size()
                    if hasPreviewContent {
                        newSize.width += 200
                    }
                    newSize.width += 60
                    if newSize.width > size.width {
                        size.width = newSize.width
                    }
                }
                
                let completionView = _UIHostingView(
                    rootView: CodeCompletionView(
                        items: items,
                        size: size,
                        hasPreviewContent: hasPreviewContent
                    )
                )
                
                var viewFrame = completionView.frame
                viewFrame.size = size
                viewFrame.origin = rect.origin
                viewFrame.origin.y += rect.height + 10
                
                let visibleFrame = self.frame
                if viewFrame.maxX > visibleFrame.maxX {
                    viewFrame.origin.x = visibleFrame.maxX - viewFrame.width
                }
                if viewFrame.minX < visibleFrame.minX {
                    viewFrame.origin.x = visibleFrame.minX
                }
                
                completionView.frame = viewFrame
                self.addSubview(completionView)
                showingAutoCompletionView = completionView
            }
        }
        
        @discardableResult
        func selectPlaceholder(previous: Bool = false) -> Bool {
            let _range = self.selectedRange
            var currentLoc = _range.location
            if previous {
                currentLoc -= 1
                if currentLoc < 0 { return false }
            } else {
                currentLoc += _range.length
            }
            let currentString = self.text!
            let selectedIndex = currentString.index(
                currentString.startIndex,
                offsetBy: currentLoc
            )
            var placeholderStartIndex: String.Index?
            var placeholderEndIndex: String.Index?
            var checkingIndex = selectedIndex
            while checkingIndex > currentString.startIndex && checkingIndex < currentString.endIndex {
                let char = currentString[checkingIndex]
                if char == "<" {
                    let nextIndex = currentString.index(after: checkingIndex)
                    guard nextIndex < currentString.endIndex else { break }
                    let nextChar = currentString[nextIndex]
                    if nextChar == "#" {
                        placeholderStartIndex = checkingIndex
                        break
                    }
                } else if char == "\n" {
                    break
                }
                if previous {
                    currentString.formIndex(before: &checkingIndex)
                } else {
                    currentString.formIndex(after: &checkingIndex)
                }
            }
            guard let placeholderStartIndex else { return false }
            checkingIndex = placeholderStartIndex
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
                } else if char == "\n" {
                    break
                }
                currentString.formIndex(after: &checkingIndex)
            }
            if let endIndex = placeholderEndIndex {
                self.selectedRange = .init(
                    placeholderStartIndex...endIndex,
                    in: currentString
                )
                return true
            }
            return false
        }
    }
    
    class LineNumberView: UIView {
        var font: UIFont! {
            didSet {
                self.setNeedsDisplay()
            }
        }
        
        var textView: UITextView
        
        init(textView: UITextView) {
            self.textView = textView
            self.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
            super.init(frame: .zero)
            self.isOpaque = false
        }
        
        required init(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func draw(_ rect: CGRect) {
            let layoutManager = textView.layoutManager
            let textInset = textView.textContainerInset
            let relativePoint = CGPoint(x: 0, y: textInset.top)
            let lineNumberAttributes: [NSAttributedString.Key: Any] = [
                .font: textView.font ?? UIFont.systemFont(ofSize: UIFont.systemFontSize),
                .foregroundColor: UIColor.gray
            ]
            
            func drawLineNumber(_ lineNumberString: String, at y: CGFloat) {
                let attString = NSAttributedString(string: lineNumberString, attributes: lineNumberAttributes)
                let x = bounds.width - attString.size().width - 4
                attString.draw(at: CGPoint(x: x, y: relativePoint.y + y))
            }
            
            let visibleGlyphRange = NSRange(
                location: 0,
                length: textView.textStorage.length
            )
            
            var lineNumber = 1
            var glyphIndexForStringLine = visibleGlyphRange.location
            
            while glyphIndexForStringLine < visibleGlyphRange.upperBound {
                let characterRangeForStringLine = (textView.text as NSString).lineRange(
                    for: NSMakeRange(layoutManager.characterIndexForGlyph(at: glyphIndexForStringLine), 0)
                )
                
                let glyphRangeForStringLine = layoutManager.glyphRange(
                    forCharacterRange: characterRangeForStringLine,
                    actualCharacterRange: nil
                )
                
                var glyphIndexForGlyphLine = glyphIndexForStringLine
                var glyphLineCount = 0
                
                while glyphIndexForGlyphLine < glyphRangeForStringLine.upperBound {
                    var effectiveRange = NSRange(location: 0, length: 0)
                    let lineRect = unsafe layoutManager.lineFragmentUsedRect(
                        forGlyphAt: glyphIndexForGlyphLine,
                        effectiveRange: &effectiveRange,
                        withoutAdditionalLayout: true
                    )
                    
                    if glyphLineCount == 0 {
                        drawLineNumber("\(lineNumber)", at: lineRect.minY)
                    } else {
                        drawLineNumber(" ", at: lineRect.minY)
                    }
                    
                    glyphLineCount += 1
                    glyphIndexForGlyphLine = NSMaxRange(effectiveRange)
                }
                
                glyphIndexForStringLine = NSMaxRange(glyphRangeForStringLine)
                lineNumber += 1
            }
            
            if layoutManager.extraLineFragmentTextContainer != nil {
                drawLineNumber("\(lineNumber)", at: layoutManager.extraLineFragmentRect.minY)
            }
        }
    }
    
    private class CodeTextRange: UITextRange {
        let range: NSRange
        
        init(_ range: NSRange) {
            self.range = range
        }
        init(location: Int, length: Int) {
            self.range = .init(location: location, length: length)
        }
        
        override var start: CodeTextPosition {
            .init(range.location)
        }
        override var end: CodeTextPosition {
            .init(range.upperBound)
        }
        
        fileprivate class CodeTextPosition: UITextPosition {
            let position: Int
            
            init(_ position: Int) {
                self.position = position
            }
        }
    }
}
#endif // os(macOS)

private struct CodeCompletionView: View {
    static let nextItemSubject = PassthroughSubject<Void, Never>()
    static let previousItemSubject = PassthroughSubject<Void, Never>()
    static let getCurrentSubject = PassthroughSubject<(CodeCompletionItem) -> Void, Never>()
    
    var items: [CodeCompletionItem]
    var size: CGSize
    var hasPreviewContent: Bool
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedItemIndex = 0
    var body: some View {
        HStack(spacing: 0) {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 0) {
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
                                                case .file:
                                                    Color.blue
                                                case .folder:
                                                    Color.blue
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
                                                Image(systemName: "circle.fill")
                                                    .font(.system(size: 3))
                                            case .file:
                                                Image(systemName: "document.fill")
                                                    .font(.system(size: 9, weight: .medium))
                                            case .folder:
                                                Image(systemName: "folder.fill")
                                                    .font(.system(size: 9, weight: .medium))
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
                    if !item.declaration.string.isEmpty {
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
            }
            .frame(width: hasPreviewContent ? size.width - 200 : size.width, height: size.height)
            if let preview = items[selectedItemIndex].previewContent {
                Divider()
                HStack {
                    Spacer(minLength: 0)
                    switch preview {
                    case .image(let url):
                        WebImage(url: url) { image in
                            image
                                .resizable()
                                .scaledToFit()
                        } placeholder: {
                            ProgressView()
                        }
                    case .live2d(let url):
                        Live2DView(resourceURL: url) {
                            ProgressView()
                        }
                        ._live2dZoomFactor(2)
                        ._live2dCoordinateMatrix("""
                        [ s, 0, 0, 0,
                          0,-s, 0, 0,
                          0, 0, 1, 0,
                          -1, 1, 0, 1 ]
                        """)
                        .clipped()
                        .frame(width: 200, height: 200)
                    case .live2dMotion(let url, let motion):
                        Live2DView(resourceURL: url) {
                            ProgressView()
                        }
                        .live2dMotion(motion)
                        ._live2dZoomFactor(2)
                        ._live2dCoordinateMatrix("""
                        [ s, 0, 0, 0,
                          0,-s, 0, 0,
                          0, 0, 1, 0,
                          -1, 1, 0, 1 ]
                        """)
                        .clipped()
                        .frame(width: 200, height: 200)
                    case .live2dExpression(let url, let expression):
                        Live2DView(resourceURL: url) {
                            ProgressView()
                        }
                        .live2dExpression(expression)
                        ._live2dZoomFactor(4)
                        ._live2dCoordinateMatrix("""
                        [ s, 0, 0, 0,
                          0,-s, 0, 0,
                          0, 0, 1, 0,
                          -2, 1.3, 0, 1 ]
                        """)
                        .clipped()
                        .frame(width: 200, height: 200)
                    @unknown default:
                        EmptyView()
                    }
                    Spacer(minLength: 0)
                }
                .frame(width: 200, height: size.height)
            }
        }
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

private struct InlineDiagnosticView: View {
    var diagnostic: Diagnostic
    var size: CGSize
    var body: some View {
        HStack(spacing: 0) {
            Spacer(minLength: 0)
            HStack(spacing: 0) {
                Image(systemName: diagnostic.severity.symbol)
                    .foregroundStyle(.white, diagnostic.severity.color)
                    .padding(.horizontal, 3)
                    .frame(height: size.height)
                    .background {
                        Rectangle()
                            .fill(diagnostic.severity.color.opacity(0.3))
                    }
                Spacer()
                    .frame(width: 1)
                Text(diagnostic.message)
                    .lineLimit(1)
                    .padding(.horizontal, 5)
                    .frame(height: size.height)
                    .background {
                        Rectangle()
                            .fill(diagnostic.severity.color.opacity(0.3))
                    }
            }
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .frame(width: size.width, height: size.height)
    }
}

private func asyncCompleteCode(
    _ code: String,
    at index: String.Index,
    in locale: DoriLocale,
    assetFolder: FileWrapper?
) async -> [CodeCompletionItem] {
    await withCheckedContinuation { continuation in
        DispatchQueue(label: "com.memz233.Greatdori.Zeile.Code-Completion", qos: .userInitiated).async {
            continuation.resume(
                returning: DoriStoryBuilder(for: locale).completeCode(
                    code,
                    at: index,
                    assetFolder: assetFolder
                )
            )
        }
    }
}

extension Diagnostic.Severity {
    var color: Color {
        switch self {
        case .error: .red
        case .warning: .yellow
        case .note: .gray
        case .remark: .blue
        @unknown default: .gray
        }
    }
    
    var symbol: String {
        switch self {
        case .error: "xmark.octagon.fill"
        case .warning: "exclamationmark.triangle.fill"
        case .note: "smallcircle.filled.circle.fill"
        case .remark: "exclamationmark.square.fill"
        @unknown default: "questionmark.circle.fill"
        }
    }
}

extension EnvironmentValues {
    @Entry var onDiagnosticsUpdate: ([Diagnostic]) -> Void = { _ in }
}

extension FileWrapper: @unchecked @retroactive Sendable {}
