//===---*- Greatdori! -*---------------------------------------------------===//
//
// TextStyleRender.swift
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
@_private(sourceFile: "FrontendSong.swift") import DoriKit

struct TextStyleRender: View {
    var text: String
    var partialStyle: [ClosedRange<Int>: Lyrics.Style]
    @Environment(\.font) var envFont
    @Environment(\.fontResolutionContext) var envFontContext
    @State var factor: CGFloat = 14
    
    init(text: String, style: Lyrics.Style) {
        self.text = text
        self.partialStyle = [.init(0..<text.count): style]
    }
    init(text: String, partialStyle: [ClosedRange<Int>: Lyrics.Style]) {
        self.text = text
        self.partialStyle = partialStyle
    }
    
    var body: some View {
        Text(text)
            .wrapIfLet(partialStyle.first?.value.fontOverride) { content, fontName in
                if let envFont {
                    content
                        .font(.custom(fontName, size: envFont.resolve(in: envFontContext).pointSize))
                        .onAppear {
                            factor = envFont.resolve(in: envFontContext).pointSize
                        }
                } else {
                    content
                        .font(.custom(fontName, size: 14))
                }
            }
            .textRenderer(_StyleRenderer(factor: factor, partialStyle: partialStyle))
    }
}

private struct _StyleRenderer: TextRenderer {
    var factor: CGFloat
    var partialStyle: [ClosedRange<Int>: Lyrics.Style]
    func draw(layout: Text.Layout, in ctx: inout GraphicsContext) {
        if partialStyle.isEmpty {
            for line in layout {
                ctx.draw(line)
            }
            return
        }
        for line in layout {
            for run in line {
                let runIndent = run.startIndex
                for glyph in run {
                    let glyphRange = (glyph.startIndex + runIndent)..<(glyph.endIndex + runIndent)
                    var hasDrawn = false
                    for (range, style) in partialStyle {
                        if range.overlaps(glyphRange) {
                            // Apply style
                            if let shadow = style.shadow {
                                var ctxShadow = ctx
                                ctxShadow.clipToLayer { lctx in
                                    lctx.translateBy(x: shadow.x / 30 * factor, y: shadow.y / 30 * factor)
                                    lctx.draw(glyph)
                                }
                                ctxShadow.addFilter(.blur(radius: shadow.blur / 30 * factor))
                                ctxShadow.fill(Rectangle().path(in: glyph.typographicBounds.rect), with: .color(shadow.color))
                            }
                            if let stroke = style.stroke {
                                var ctxStroke = ctx
                                if stroke.radius > 0 {
                                    ctxStroke.addFilter(.blur(radius: stroke.radius / 30 * factor))
                                }
                                var ctxStrokecpy = ctxStroke
                                ctxStrokecpy.clipToLayer { lctx in
                                    lctx.translateBy(x: stroke.width / 30 * factor, y: stroke.width / 30 * factor)
                                    lctx.draw(glyph)
                                }
                                ctxStrokecpy.fill(Rectangle().path(in: glyph.typographicBounds.rect), with: .color(stroke.color))
                                ctxStrokecpy = ctxStroke
                                ctxStrokecpy.clipToLayer { lctx in
                                    lctx.translateBy(x: -stroke.width / 30 * factor, y: -stroke.width / 30 * factor)
                                    lctx.draw(glyph)
                                }
                                ctxStrokecpy.fill(Rectangle().path(in: glyph.typographicBounds.rect), with: .color(stroke.color))
                                ctxStrokecpy = ctxStroke
                                ctxStrokecpy.clipToLayer { lctx in
                                    lctx.translateBy(x: -stroke.width / 30 * factor, y: stroke.width / 30 * factor)
                                    lctx.draw(glyph)
                                }
                                ctxStrokecpy.fill(Rectangle().path(in: glyph.typographicBounds.rect), with: .color(stroke.color))
                                ctxStrokecpy = ctxStroke
                                ctxStrokecpy.clipToLayer { lctx in
                                    lctx.translateBy(x: stroke.width / 30 * factor, y: -stroke.width / 30 * factor)
                                    lctx.draw(glyph)
                                }
                                ctxStrokecpy.fill(Rectangle().path(in: glyph.typographicBounds.rect), with: .color(stroke.color))
                            }
                            var ctxcpy = ctx
                            ctxcpy.clipToLayer { lctx in
                                lctx.draw(glyph)
                            }
                            if let color = style.color {
                                ctxcpy.fill(Rectangle().path(in: glyph.typographicBounds.rect), with: .color(color))
                            } else {
                                ctxcpy.fill(Rectangle().path(in: glyph.typographicBounds.rect), with: .foreground)
                            }
                            hasDrawn = true
                        }
                    }
                    if !hasDrawn {
                        ctx.draw(glyph)
                    }
                }
            }
        }
        for (range, style) in partialStyle {
            let glyphs = layout.flatMap { $0 }.flatMap { $0 }
            guard range.lowerBound < glyphs.count else { continue }
            let glyphSlice = glyphs[range.lowerBound..<min(range.upperBound, glyphs.count)]
            for maskLine in style.maskLines {
                var ctxMaskLine = ctx
                ctxMaskLine.clipToLayer { lctx in
                    for glyph in glyphSlice {
                        lctx.draw(glyph)
                    }
                }
                let _size = layout.compactMap {
                    ($0.typographicBounds.rect.width, $0.typographicBounds.rect.height)
                }.reduce(into: (0.0, 0.0)) {
                    if $0.0 == 0 { $0.0 = $1.0 }
                    $0.1 += $1.1
                }
                let size = CGSize(width: _size.0, height: _size.1)
                let path = Path { path in
                    let startAbs = CGPoint(
                        x: maskLine.start.x * size.width,
                        y: maskLine.start.y * size.height
                    )
                    let endAbs = CGPoint(
                        x: maskLine.end.x * size.width,
                        y: maskLine.end.y * size.height
                    )
                    path.move(to: startAbs)
                    path.addLine(to: endAbs)
                }
                ctxMaskLine.stroke(path, with: .color(maskLine.color), lineWidth: maskLine.width / 30 * factor)
            }
        }
    }
}
