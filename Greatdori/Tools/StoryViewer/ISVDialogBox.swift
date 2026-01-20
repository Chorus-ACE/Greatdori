//===---*- Greatdori! -*---------------------------------------------------===//
//
// ISVDialogBox.swift
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
import SymbolAvailability

struct ISVDialogBoxView: View {
    var data: TalkData
    var locale: DoriLocale
    var isDelaying: Bool
    var isAutoPlaying: Bool
    @AppStorage("interactiveStoryViewerShowsNextIndicator") var interactiveStoryViewerShowsNextIndicator = false
    @Binding var isAnimating: Bool
    @Binding var shakeDuration: Double
    @State private var currentBody = ""
    @State private var bodyAnimationTimer: Timer?
    @State private var shakeTimer: Timer?
    @State private var shakingOffset = CGSize(width: 0, height: 0)
    @State private var autoPlayLabelBlinkTimer: Timer?
    @State private var isShowingAutoPlayLabel = false
    @State var cornerRadius: CGFloat = 20
    @State var fontSize: CGFloat = 20
    
    @State var boxWidth: CGFloat = 0
    @State var boxHeight: CGFloat = 0
    @State var nameTagBarHeight: CGFloat = 0
    var body: some View {
        ZStack(alignment: .topLeading) {
            // MARK: Background
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.white.opacity(0.9))
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(Color.gray.opacity(0.8))
                }
                .shadow(radius: 20)
                .aspectRatio(6.8, contentMode: .fit)
            
            // MARK: Text
            Text({
                var result = AttributedString()
                for character in currentBody {
                    var str = AttributedString(String(character))
                    //                if locale == .cn && "[，。！？；：（）【】「」『』、“”‘’——…]".contains(character) {
                    //                    // The font for cn has too wide punctuations,
                    //                    // we have to fix it here.
                    //                    // System font seems higher than cn font,
                    //                    // we use a smaller size for it to prevent
                    //                    // the line height being changed during animation
                    //#if os(macOS)
                    //                    str.font = .system(size: 19, weight: .medium)
                    //#else
                    //                    str.font = .system(size: 15, weight: .medium)
                    //#endif
                    //                }
                    result.append(str)
                }
                return result
            }())
            .font(.custom(fontName(in: locale), size: fontSize))
            .wrapIf(locale == .en || locale == .tw) { content in
                // TODO: Require Revision
                content
                    .lineSpacing(locale == .en ? 10 : -5)
            }
            .typesettingLanguage(locale.nsLocale().language)
            //            .textSelection(.enabled)
            .foregroundStyle(Color(red: 80 / 255, green: 80 / 255, blue: 80 / 255))
            .padding(.horizontal, boxWidth/40)
            .padding(.top, boxHeight/10)
            
            // MARK: Label
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(red: 255 / 255, green: 59 / 255, blue: 114 / 255))
                    .overlay {
                        HStack {
                            Spacer()
                            Image("NameSideStar")
                                .resizable()
                                .scaledToFit()
                                .frame(height: nameTagBarHeight)
                        }
                        .clipShape(Capsule())
                    }
                    .overlay {
                        Capsule()
                            .strokeBorder(Color.white, lineWidth: boxWidth/500)
                    }
                    .aspectRatio(6.5, contentMode: .fit)
                    .frame(height: nameTagBarHeight)
                Text(data.characterNames.joined(separator: " & "))
                    .font(.custom(fontName(in: locale), size: fontSize))
                    .foregroundStyle(.white)
                    .padding(.vertical)
                    .padding(.leading, nameTagBarHeight*6.5/15)
            }
            .offset(y: -boxWidth*0.0207-18.615)
            HStack {
                Spacer()
                if isShowingAutoPlayLabel {
                    HStack(spacing: 2) {
                        Image(systemName: .arrowtriangleForwardFill)
                            .scaleEffect(x: 0.7, y: 1, anchor: .trailing)
                        Text(verbatim: "AUTO")
                    }
                    .font(.system(size: fontSize, weight: .bold, design: .rounded))
                    .modifier(StrokeTextModifier(width: Double(1.5), color: .white))
                    .foregroundStyle(Color(red: 255 / 255, green: 59 / 255, blue: 114 / 255))
                }
            }
            .padding(.horizontal, boxWidth/20)
            .offset(y: -5)
            
        }
        .onFrameChange(perform: { geometry in
            boxWidth = geometry.size.width
            boxHeight = geometry.size.height
            
            cornerRadius = boxWidth/40
            fontSize = boxWidth/40
            nameTagBarHeight = boxHeight/4
        })
        .offset(shakingOffset)
        .onAppear {
            animateText()
        }
        .onChange(of: data.text) {
            animateText()
        }
        .onChange(of: isAutoPlaying) {
            if isAutoPlaying {
                autoPlayLabelBlinkTimer = .scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                    DispatchQueue.main.async {
                        isShowingAutoPlayLabel.toggle()
                    }
                }
            } else {
                autoPlayLabelBlinkTimer?.invalidate()
                isShowingAutoPlayLabel = false
            }
        }
        .onChange(of: isAnimating) {
            if !isAnimating {
                bodyAnimationTimer?.invalidate()
                currentBody = data.text
            }
        }
        .onChange(of: shakeDuration) {
            if shakeDuration > 0 {
                let startTime = CFAbsoluteTimeGetCurrent()
                shakeTimer = .scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                    DispatchQueue.main.async {
                        if _fastPath(CFAbsoluteTimeGetCurrent() - startTime < shakeDuration) {
                            shakingOffset = .init(width: .random(in: -5...5), height: .random(in: -5...5))
                        } else {
                            shakeTimer?.invalidate()
                            shakingOffset = .init(width: 0, height: 0)
                            shakeDuration = 0
                        }
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var backgroundLayer: some View {
        
        /*
         .overlay {
         HStack {
         Spacer()
         VStack(spacing: 0) {
         Spacer()
         if !isDelaying && interactiveStoryViewerShowsNextIndicator {
         TimelineView(.animation(minimumInterval: 1 / 120)) { context in
         Image("ContinuableMark")
         .resizable()
         .scaledToFit()
         .frame(width: 25)
         .visualEffect { content, geometry in
         content
         .colorEffect(ShaderLibrary.continuableMark(.float2(geometry.size)))
         }
         //                                    .offset(y: sin(context.date.timeIntervalSince1970 * 5) * 7)
         //                                    .scaleEffect(x: 1, y: 0.95 + (1.05 - 0.95) * sin(-context.date.timeIntervalSince1970 * 5), anchor: .bottom)
         // Animation looks horribly weird. Sorry to say so but it's just so bad.
         }
         .zIndex(1)
         Circle()
         .fill(Color.gray.opacity(0.8))
         .blur(radius: 5)
         .transformEffect(.init(scaleX: 1, y: 0.5))
         .frame(width: 25, height: 25)
         .offset(x: -3)
         }
         }
         .transition(.opacity)
         .animation(.spring(duration: 0.2, bounce: 0.15), value: isDelaying)
         }
         .padding(.trailing)
         }
         */
//
        //            .containerRelativeFrame(.vertical) { length, _ in
        //                min(length / 2 - 80, 130)
        //            }
    }
    
    func animateText() {
        isAnimating = true
        currentBody = ""
        var iterator = data.text.makeIterator()
        bodyAnimationTimer?.invalidate()
        bodyAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            DispatchQueue.main.async {
                if let character = iterator.next() {
                    currentBody += String(character)
                } else {
                    isAnimating = false
                }
            }
        }
    }
}
