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
    
    func access(_ index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

// MARK: Bool
extension Bool {
    @_transparent
    func reversed() -> Bool {
        !self
    }
}

// MARK: Button
extension Button {
    @preconcurrency
    public init(
        optionalRole: UniversalButtonRole? = nil,
        action: @escaping @MainActor () -> Void,
        @ViewBuilder label: () -> Label
    ) {
        if #available(iOS 26.0, macOS 26.0, *), let role = optionalRole {
            var roleTable: [UniversalButtonRole: ButtonRole] = [.cancel: .cancel, .destructive: .destructive, .close: .close, .confirm: .confirm]
            self.init(role: roleTable[role]!, action: action, label: label)
        } else {
            self.init(action: action, label: label)
        }
    }
    
    public enum UniversalButtonRole {
        case cancel
        case destructive
        case close
        case confirm
    }
}

// MARK: Collection
extension Collection where Element: Equatable {
    var allElementsEqual: Bool {
        guard let first else { return true }
        return allSatisfy { $0 == first }
    }

    func allEqual<T: Equatable>(by keyPath: KeyPath<Element, T>) -> Bool {
        guard let first else { return true }
        let value = first[keyPath: keyPath]
        return allSatisfy { $0[keyPath: keyPath] == value }
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
    
    init(hex: String) {
            // 移除#与空白
            let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
            var int: UInt64 = 0
            Scanner(string: hex).scanHexInt64(&int)

            let r, g, b, a: UInt64
            switch hex.count {
            case 6: // RRGGBB
                (r, g, b, a) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF, 255)
            case 8: // RRGGBBAA
                (r, g, b, a) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
            default:
                (r, g, b, a) = (255, 255, 255, 255) // fallback: white
            }

            self.init(
                .sRGB,
                red: Double(r) / 255,
                green: Double(g) / 255,
                blue: Double(b) / 255,
                opacity: Double(a) / 255
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

// MARK: EnvironmentValues
extension EnvironmentValues {
@Entry var regularInfoImageSizeFactor: CGFloat = 1
}

// MARK: Image
extension Image {
    init(fallingSystemName: String) {
        if let name = systemImageFalling[fallingSystemName] {
            if let name {
                self.init(_internalSystemName: name)
            } else {
                self.init(fallingSystemName)
            }
        } else {
            self.init(_internalSystemName: fallingSystemName)
        }
    }
}

private let systemImageFalling = {
    // The value means the name that should be fallen back;
    // `nil` means find it in Asset Catalog
    var result: [String: String?] = [:]
    
    if #unavailable(iOS 18.0, macOS 15.0) {
        result.updateValue(nil, forKey: "person.crop.square.on.square.angled")
        result.updateValue(nil, forKey: "person.crop.square.on.square.angled.fill")
        result.updateValue(nil, forKey: "star.hexagon")
        result.updateValue(nil, forKey: "star.hexagon.fill")
        result.updateValue(nil, forKey: "apple.classical.pages")
        result.updateValue(nil, forKey: "apple.classical.pages.fill")
        result.updateValue(nil, forKey: "capsule.on.capsule")
        result.updateValue("text.below.photo", forKey: "text.below.rectangle")
        result.updateValue("persona", forKey: "person.and.viewfinder")
    }
    
    return result
}()

// MARK: Int
extension Int?: @retroactive Identifiable {
    public var id: Int? { self }
}

// MARK: LocalizedData
extension LocalizedData {
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

// MARK: MutableCollection
extension MutableCollection {
    @_transparent
    func swappedAt(_ i: Self.Index, _ j: Self.Index) -> Self {
        var copy = self
        copy.swapAt(i, j)
        return copy
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

extension URL {
    func directorySize(including fileMatch: some RegexComponent = /.+/) -> Int64 {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: self,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey]
        ) else { return 0 }
        
        var size: Int64 = 0
        for url in contents {
            guard let isDirectoryResourceValue = try? url.resourceValues(
                forKeys: [.isDirectoryKey]
            ) else { continue }
            
            if isDirectoryResourceValue.isDirectory == true {
                size += url.directorySize()
            } else {
                guard let fileSizeResourceValue = try? url.resourceValues(
                    forKeys: [.fileSizeKey]
                ) else { continue }
                if url.lastPathComponent.contains(fileMatch) {
                    size += Int64(fileSizeResourceValue.fileSize ?? 0)
                }
            }
        }
        return size
    }
}

// MARK: View
public extension View {
    func detailSectionHeader() -> some View {
        self
            .padding(.bottom, -40)
            .offset(y: 5)
    }
    
    // MARK: hidden
    @ViewBuilder
    func hidden(_ isHidden: Bool = true) -> some View {
        if isHidden {
            self.hidden()
        } else {
            self
        }
    }
    
    // MARK: insert
    func insert<V: View>(@ViewBuilder content: @escaping () -> V) -> some View {
        self._variadic { children in
            if let c = children.first {
                c
                ForEach(children.dropFirst(1)) { child in
                    content()
                    child
                }
            }
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
    
    //MARK: onChange
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
    
    func regularInfoImageSizeFactor(_ sizeFactor: CGFloat) -> some View {
        environment(\.regularInfoImageSizeFactor, sizeFactor)
    }
    
    @ViewBuilder
    func trailingTextFieldForIOS(_ label: LocalizedStringResource) -> some View {
        if !isMACOS {
            HStack {
                Text(label)
                Spacer()
                self
                    .multilineTextAlignment(.trailing)
            }
        } else {
            self
        }
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
    @ViewBuilder
    func wrapIfLet<T>(
        _ optional: T?,
        @ViewBuilder in container: (Self, T) -> some View
    ) -> some View {
        if let wrapped = optional {
            container(self, wrapped)
        } else {
            self
        }
    }
}

extension URL {
    func localeReplaced(to newLocale: DoriLocale) -> URL {
        .init(string: self.absoluteString.replacing(
            /bestdori\.com\/assets\/[jpentwcnkr]{2}\//,
            with: "bestdori.com/assets/\(newLocale.rawValue)/"
        ))!
    }
}
