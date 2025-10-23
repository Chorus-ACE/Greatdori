//===---*- Greatdori! -*---------------------------------------------------===//
//
// Functions.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.memz.top/LICENSE.txt for license information
// See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

// (In Alphabetic Order)

import CoreImage.CIFilterBuiltins
import DoriKit
import Network
import SDWebImageSwiftUI
import SwiftUI
import UniformTypeIdentifiers
import Vision

#if os(iOS)
import UIKit
#endif

// MARK: bindingCast
func bindingCast<T, U>(_ binding: Binding<T>, to type: U.Type) -> Binding<U>? {
    guard let value = binding.wrappedValue as? U else { return nil }
    return Binding<U>(
        get: { value },
        set: { newValue in
            binding.wrappedValue = newValue as! T
        }
    )
}

// MARK: compare
func compare<T: Comparable>(_ lhs: T?, _ rhs: T?, ascending: Bool = true) -> Bool {
    if lhs == nil {
        return false
    } else if rhs == nil {
        return true
    } else {
        if ascending {
            return lhs! > rhs!
        } else {
            return lhs! < rhs!
        }
    }
}

/* NO USAGE
func compareWithinNormalRange(_ lhs: Int, _ rhs: Int, largetAcceptableNumber: Int, ascending: Bool = true) -> Bool {
    let correctedLHS = lhs > largetAcceptableNumber ? lhs : nil
    let correctedRHS = rhs > largetAcceptableNumber ? rhs : nil
    return compare(correctedLHS, correctedRHS, ascending: ascending)
}
*/


// MARK: copyStringToClipboard
func copyStringToClipboard(_ content: String) {
#if os(macOS)
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()
    pasteboard.setString(content, forType: .string)
#else
    UIPasteboard.general.string = content
#endif
}

// MARK: formattedSongLength
func formattedSongLength(_ time: Double) -> String {
    let minutes = Int(time / 60)
    let seconds = time.truncatingRemainder(dividingBy: 60)
    return String(format: "%d:%04.1f", minutes, seconds) // 1:42.6
}

// MARK: getBirthdayTimeZone
func getBirthdayTimeZone(from input: BirthdayTimeZone? = nil) -> TimeZone {
    switch (input != nil ? input! : BirthdayTimeZone(rawValue: UserDefaults.standard.string(forKey: "BirthdayTimeZone") ?? "JST"))! {
    case .adaptive:
        return TimeZone.autoupdatingCurrent
    case .JST:
        return TimeZone(identifier: "Asia/Tokyo")!
    case .UTC:
        return TimeZone.gmt
    case .CST:
        return TimeZone(identifier: "Asia/Shanghai")!
    case .PT:
        return TimeZone(identifier: "America/Los_Angeles")!
    }
}

// MARK: getCharactersRelatingBand [?]
//func getCharactersRelatingBand(_ characterID: Int) -> Int {
//    return DoriCache.preCache.categorizedCharacters.first { (_, characters) in
//        characters.contains(where: { $0.id == characterID })
//    }?.key?.id ?? 0
//}


// MARK: getAttributedString
func getAttributedString(_ source: String, fontSize: Font.TextStyle = .body, fontWeight: Font.Weight = .regular, foregroundColor: Color = .primary) -> AttributedString {
    var attrString = AttributedString()
    attrString = AttributedString(source)
    attrString.font = .system(fontSize, weight: fontWeight)
    attrString.foregroundColor = foregroundColor
    return attrString
}

// MARK: getImageSubject
func getImageSubject(_ data: Data) async -> Data? {
    if #available(iOS 18.0, macOS 15.0, *) {
            guard var image = CIImage(data: data) else { return nil }
            do {
                image = image.oriented(.up)
               
                let request = GenerateForegroundInstanceMaskRequest()
                let result = try await request.perform(on: image)
                
                guard let cgImage = result?.allInstances.compactMap({ (index) -> (CGImage, Int)? in
                    let buffer = try? result?.generateMaskedImage(for: [index], imageFrom: .init(data))
                    if buffer != nil {
                        let _image = CIImage(cvPixelBuffer: unsafe buffer.unsafelyUnwrapped)
                        let context = CIContext()
                        guard let image = context.createCGImage(_image, from: _image.extent) else { return nil }
                        return (image, image.width * image.height)
                    } else {
                        return nil
                    }
                }).min(by: { $0.1 < $1.1 })?.0 else { return nil }
                
                let _imageData = NSMutableData()
                if let dest = CGImageDestinationCreateWithData(_imageData, UTType.png.identifier as CFString, 1, nil) {
                    CGImageDestinationAddImage(dest, cgImage, nil)
                    if CGImageDestinationFinalize(dest) {
                        return _imageData as Data
//#if os(macOS)
//                        NSPasteboard.general.clearContents()
//                        NSPasteboard.general.setData(_imageData as Data, forType: .png)
//#else
//                        UIPasteboard.general.image = .init(data: _imageData as Data)!
//#endif
                    }
                }
            } catch {
                print(error)
            }
    } else {
        return nil
    }
    return nil
}


// MARK: getPlaceholderColor
func getPlaceholderColor() -> Color {
#if os(iOS)
    return Color(UIColor.placeholderText)
#else
    return Color.gray
#endif
}

// MARK: getProperDataSourceType
@MainActor func getProperDataSourceType(dataPrefersInternet: Bool = false) -> OfflineAssetBehavior {
    let dataSourcePreference = DataSourcePreference(rawValue: UserDefaults.standard.string(forKey: "DataSourcePreference") ?? "hybrid") ?? .hybrid
    switch dataSourcePreference {
    case .hybrid :
        if dataPrefersInternet && NetworkMonitor.shared.isConnected {
            return .disabled
        } else {
            return .enableIfAvailable
        }
    case .useLocal:
        return .enabled
    case .useInternet:
        return .disabled
    }
}

// MARK: getSecondaryBackgroundColor
func getTertiaryLabelColor() -> Color {
#if os(iOS)
    return Color(UIColor.tertiaryLabel)
#else
    return Color(NSColor.tertiaryLabelColor)
#endif
}

// MARK: highlightOccurrences
/// Highlights all occurrences of a keyword within a string in blue.
/// - Parameters:
///   - keyword: The substring to highlight within `content`. If empty or only whitespace, no highlighting occurs.
///   - content: The string to search in.
/// - Returns: An AttributedString (from `content`) with all `keyword` occurrences colored blue.
func highlightOccurrences(of keyword: String, in content: String?) -> AttributedString? {
    if let content {
        var attributedString = AttributedString(content)
        guard !keyword.isEmpty else { return attributedString }
        guard !content.isEmpty else { return attributedString }
        //    let keywordTrimmed = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let range = attributedString.range(of: keyword, options: .caseInsensitive) else { return attributedString }
        attributedString[range].foregroundColor = .accent
        
        return attributedString
    } else {
        return nil
    }
}

// MARK: NetworkMonitor
final class NetworkMonitor: Sendable {
    @MainActor static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @MainActor private(set) var isConnected: Bool = false
    @MainActor private(set) var connectionType: NWInterface.InterfaceType?
    
    private init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
                
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .wiredEthernet
                } else {
                    self.connectionType = nil
                }
            }
        }
        monitor.start(queue: queue)
    }
}

func timeZoneDifference(to targetTimeZone: TimeZone) -> String {
    let now = Date()
    let systemTimeZone = TimeZone.current
    
    // 获取两个时区的偏移（秒）
    let systemOffset = systemTimeZone.secondsFromGMT(for: now)
    let targetOffset = targetTimeZone.secondsFromGMT(for: now)
    
    // 小时差（可能是负数）
    let hoursDiff = (targetOffset - systemOffset) / 3600
    
    if hoursDiff == 0 {
        return String(localized: "Time-zone.same-time")
    }
    
    // 比较日期差异
    let systemDate = Calendar.current.dateComponents(in: systemTimeZone, from: now).day
    let targetDate = Calendar.current.dateComponents(in: targetTimeZone, from: now).day
    
    var dayDescription = String(localized: "Time-zone.today")
    if let sysDay = systemDate, let tgtDay = targetDate {
        if tgtDay == sysDay - 1 {
            dayDescription = String(localized: "Time-zone.yesterday")
        } else if tgtDay == sysDay + 1 {
            dayDescription = String(localized: "Time-zone.tomorrow")
        }
    }
    
    return String(localized: "Time-zone.\(dayDescription).\(hoursDiff >= 0 ? "+" : "-").\(abs(hoursDiff))")
}

func timeZoneUTCOffsetDescription(for timeZone: TimeZone) -> String {
    let seconds = timeZone.secondsFromGMT(for: Date())
    let hours = seconds / 3600
    let minutes = abs(seconds % 3600 / 60)
    
    if minutes == 0 {
        return String(format: "UTC%+d", hours)
    } else {
        return String(format: "UTC%+d:%02d", hours, minutes)
    }
}

#if os(iOS)
@MainActor
func setDeviceOrientation(to orientation: UIInterfaceOrientationMask? = nil, allowing mask: UIInterfaceOrientationMask) {
    AppDelegate.orientationLock = mask
    if let orientation {
        if let scene = UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first {
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: orientation))
        } else {
            // This is deprecated, we use it as a fallback
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        }
    }
    UIViewController.attemptRotationToDeviceOrientation()
}
#endif

// MARK: ListItemType
enum ListItemType: Hashable, Equatable {
    case compactOnly
    case expandedOnly
    case automatic
    case basedOnUISizeClass
}
