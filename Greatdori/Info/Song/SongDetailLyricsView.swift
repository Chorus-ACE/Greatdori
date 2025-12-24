//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongDetailLyricsView.swift
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

@available(iOS 26.0, macOS 26.0, *)
struct SongDetailLyricsView: View {
    var lyrics: _DoriFrontend.Songs.Lyrics
    @State private var isReportPresented = false
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section {
                CustomGroupBox {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(lyrics.lyrics) { lyricLine in
                                VStack(alignment: .leading, spacing: 0) {
                                    Group {
                                        if let mainStyle = lyrics.mainStyle {
                                            TextStyleRender(
                                                text: lyricLine.original,
                                                partialStyle: mergingMainStyle(
                                                    mainStyle,
                                                    with: lyricLine.partialStyle,
                                                    for: lyricLine
                                                )
                                            )
                                        } else {
                                            TextStyleRender(
                                                text: lyricLine.original,
                                                partialStyle: lyricLine.partialStyle
                                            )
                                        }
                                    }
                                    .font(.system(size: 20))
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .frame(maxWidth: infoContentMaxWidth)
            } header: {
                HStack {
                    Text("Song.lyrics")
                        .font(.title2)
                        .bold()
                    Spacer()
                    Button(action: {
                        isReportPresented = true
                    }, label: {
                        Text("Song.lyrics.report")
                            .foregroundStyle(.secondary)
                    })
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 615)
            }
        }
    }
}

private func mergingMainStyle(
    _ mainStyle: _DoriFrontend.Songs.Lyrics.Style,
    with partialStyle: [ClosedRange<Int>: _DoriFrontend.Songs.Lyrics.Style],
    for line: _DoriFrontend.Songs.Lyrics.LyricLine
) -> [ClosedRange<Int>: _DoriFrontend.Songs.Lyrics.Style] {
    var mainRangeSet = Set(0..<line.original.count)
    var result = [ClosedRange<Int>: _DoriFrontend.Songs.Lyrics.Style]()
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

@available(iOS 26.0, macOS 26.0, *)
private struct TextStyleRender: View {
    var text: String
    var partialStyle: [ClosedRange<Int>: _DoriFrontend.Songs.Lyrics.Style]
    @Environment(\.font) var envFont
    @Environment(\.fontResolutionContext) var envFontContext
    @State var factor: CGFloat = 14
    
    init(text: String, style: _DoriFrontend.Songs.Lyrics.Style) {
        self.text = text
        self.partialStyle = [.init(0..<text.count): style]
    }
    init(text: String, partialStyle: [ClosedRange<Int>: _DoriFrontend.Songs.Lyrics.Style]) {
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

@available(iOS 26.0, macOS 26.0, *)
private struct _StyleRenderer: TextRenderer {
    var factor: CGFloat
    var partialStyle: [ClosedRange<Int>: _DoriFrontend.Songs.Lyrics.Style]
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
