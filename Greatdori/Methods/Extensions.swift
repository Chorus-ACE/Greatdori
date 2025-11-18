//===---*- Greatdori! -*---------------------------------------------------===//
//
// Extensions.swift
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

// (In Alphabetical Order)


import BackgroundAssets
import CoreImage.CIFilterBuiltins
import DoriKit
import Network
import SDWebImageSwiftUI
import SwiftUI
import System
import UniformTypeIdentifiers
import Vision

// MARK: Array
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: Bool
extension Bool {
    @_transparent
    func reversed() -> Bool {
        !self
    }
}

// MARK: Color
extension Color {
    func toHex() -> String? {
#if os(macOS)
        let nativeColor = NSColor(self).usingColorSpace(.deviceRGB)
        guard let color = nativeColor else { return nil }
#else
        let color = UIColor(self)
#endif
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
#if os(macOS)
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
#else
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
#endif
        
        return String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(red * 255)),
            lroundf(Float(green * 255)),
            lroundf(Float(blue * 255))
        )
    }
    
    func hue(factor: CGFloat) -> Color {
        return modifyHSB { (h, s, b, a) in
            let newHue = (h * factor).truncatingRemainder(dividingBy: 1.0)
            return (newHue, s, b, a)
        }
    }
    
    func saturation(factor: CGFloat) -> Color {
        return modifyHSB { (h, s, b, a) in
            (h, min(max(s * factor, 0), 1), b, a)
        }
    }
    
    func brightness(factor: CGFloat) -> Color {
        return modifyHSB { (h, s, b, a) in
            (h, s, min(max(b * factor, 0), 1), a)
        }
    }
    
    private func modifyHSB(_ transform: (CGFloat, CGFloat, CGFloat, CGFloat) -> (CGFloat, CGFloat, CGFloat, CGFloat)) -> Color {
#if canImport(UIKit)
        let uiColor = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let (newH, newS, newB, newA) = transform(h, s, b, a)
        return Color(UIColor(hue: newH, saturation: newS, brightness: newB, alpha: newA))
#elseif canImport(AppKit)
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? .black
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let (newH, newS, newB, newA) = transform(h, s, b, a)
        return Color(NSColor(hue: newH, saturation: newS, brightness: newB, alpha: newA))
#else
        return self
#endif
    }
    
    static func random() -> Color {
        .init(
            red: .random(in: 0...1),
            green: .random(in: 0...1),
            blue: .random(in: 0...1)
        )
    }
}

// MARK: Date
extension Date {
    public func corrected() -> Date? {
        if self.timeIntervalSince1970 >= 3786879600 {
            return nil
        } else {
            return self
        }
    }
    
    public func formattedRelatively() -> String {
            let calendar = Calendar.current
            let formatter = DateFormatter()
            formatter.locale = .current
            formatter.doesRelativeDateFormatting = true
            
            // 判断是不是今天
            if calendar.isDateInToday(self) {
                formatter.timeStyle = .short
                formatter.dateStyle = .none
                return formatter.string(from: self)
            }
            
            // 判断是不是昨天
            if calendar.isDateInYesterday(self) {
                formatter.timeStyle = .none
                formatter.dateStyle = .medium
                formatter.doesRelativeDateFormatting = true
                return formatter.string(from: self)
            }
            
            // 判断是否在本周内
            if let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()),
               self >= weekAgo {
                let weekdayFormatter = DateFormatter()
                weekdayFormatter.locale = .current
                weekdayFormatter.setLocalizedDateFormatFromTemplate("EEEE") // 例如 "Wednesday" / "周三"
                return weekdayFormatter.string(from: self)
            }
            
            // 判断是否在今年内
            let nowYear = calendar.component(.year, from: Date())
            let targetYear = calendar.component(.year, from: self)
            if nowYear == targetYear {
                let shortFormatter = DateFormatter()
                shortFormatter.locale = .current
                shortFormatter.setLocalizedDateFormatFromTemplate("Md") // 例如 "3/30"
                return shortFormatter.string(from: self)
            }
            
            // 更早的日期（不同年份）
            let fullFormatter = DateFormatter()
            fullFormatter.locale = .current
            fullFormatter.setLocalizedDateFormatFromTemplate("yMd") // 例如 "2017/3/30"
            return fullFormatter.string(from: self)
        }
}

// MARK: LocalizedData
extension LocalizedData<Set<ExtendedCard.Source>> {
    public enum CardSource {
        case event, gacha, loginCampaign
    }
    
    public func containsSource(from source: CardSource) -> Bool {
        for locale in DoriLocale.allCases {
            for item in Array(self.forLocale(locale) ?? Set()) {
                switch item {
                case .event:
                    if source == .event { return true }
                case .gacha:
                    if source == .gacha { return true }
                case .login:
                    if source == .loginCampaign { return true }
                default: continue
                }
            }
        }
        return false
    }
}

// MARK: Int
extension Int?: @retroactive Identifiable {
    public var id: Int? { self }
}

// MARK: LocalizedData
extension LocalizedData {
    init(jp: T? = nil, en: T? = nil, tw: T? = nil, cn: T? = nil, kr: T? = nil) {
        self.init(_jp: jp, en: en, tw: tw, cn: cn, kr: kr)
    }
    
    init(forEveryLocale item: T?) {
        self.init(jp: item, en: item, tw: item, cn: item, kr: item)
    }
    
    func allAvailableLocales() -> [DoriLocale] {
        var result: [DoriLocale] = []
        for locale in DoriLocale.allCases {
            if self.availableInLocale(locale) {
                result.append(locale)
            }
        }
        return result
    }
    
    func allUnvailableLocales() -> [DoriLocale] {
        var result: [DoriLocale] = []
        for locale in DoriLocale.allCases {
            if !self.availableInLocale(locale) {
                result.append(locale)
            }
        }
        return result
    }
}

// MARK: LocalizedStringResource
extension LocalizedStringResource: Hashable {
    public static func == (lhs: LocalizedStringResource, rhs: LocalizedStringResource) -> Bool {
        lhs.key == rhs.key && lhs.table == rhs.table
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(table)
    }
}


// MARK: Optional
extension Optional {
    var id: Self { self }
}

// MARK: Picker
extension Picker {
    public init(selection: Binding<SelectionValue>, @ViewBuilder content: () -> Content, @ViewBuilder label: () -> Label, @ViewBuilder optionalCurrentValueLabel: () -> some View) {
        if #available(iOS 18.0, macOS 15.0, *) {
            self.init(selection: selection, content: {
                content()
            }, label: {
                label()
            }, currentValueLabel: {
                optionalCurrentValueLabel()
            })
        } else {
            self.init(selection: selection, content: {
                content()
            }, label: {
                label()
            })
        }
    }
}

// MARK: View
public extension View {
    // MARK: hidden
    @ViewBuilder
    func hidden(_ isHidden: Bool = true) -> some View {
        if isHidden {
            self.hidden()
        } else {
            self
        }
    }
    
    // MARK: inverseMask
    func inverseMask<Mask: View>(
        @ViewBuilder _ mask: () -> Mask,
        alignment: Alignment = .center
    ) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    mask().blendMode(.destinationOut)
                }
        }
    }
    
    // MARK: onFrameChange
    func onFrameChange(perform action: @escaping (_ geometry: GeometryProxy) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .onChange(of: geometry.size, initial: true) {
                        action(geometry)
                    }
            }
        )
    }
    
    @_disfavoredOverload
    func onChange<each V: Equatable>(
        of value: repeat each V,
        initial: Bool = false,
        _ action: @escaping () -> Void
    ) -> some View {
        var result = AnyView(self)
        for v in repeat each value {
            result = AnyView(result.onChange(of: v, action))
        }
        if initial {
            result = AnyView(result.onAppear { action() })
        }
        return result
    }
    
    // MARK: wrapIf
    @ViewBuilder
    func wrapIf(_ condition: Bool, @ViewBuilder in container: (Self) -> some View) -> some View {
        if condition {
            container(self)
        } else {
            self
        }
    }
    @ViewBuilder
    func wrapIf(_ condition: Bool, @ViewBuilder in container: (Self) -> some View, @ViewBuilder else elseContainer: (Self) -> some View) -> some View {
        if condition {
            container(self)
        } else {
            elseContainer(self)
        }
    }
}

extension MutableCollection {
    @_transparent
    func swappedAt(_ i: Self.Index, _ j: Self.Index) -> Self {
        var copy = self
        copy.swapAt(i, j)
        return copy
    }
}

extension EnvironmentValues {
    @Entry var regularInfoImageSizeFactor: CGFloat = 1
}
extension View {
    func regularInfoImageSizeFactor(_ sizeFactor: CGFloat) -> some View {
        environment(\.regularInfoImageSizeFactor, sizeFactor)
    }
}
