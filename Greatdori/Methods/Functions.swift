//===---*- Greatdori! -*---------------------------------------------------===//
//
// Functions.swift
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

// (In Alphabetic Order)

import Alamofire
import CoreImage.CIFilterBuiltins
import DoriKit
import Network
import SDWebImageSwiftUI
import SwiftJWT
import SwiftUI
import SwiftyJSON
import UniformTypeIdentifiers
import Vision

#if os(iOS)
import UIKit
#else
import IOKit
import IOKit.pwr_mgt
#endif

// MARK: bindingCast
func bindingCast<T, U>(_ binding: Binding<T>, to type: U.Type) -> Binding<U>? {
    guard T.self == U.self, let value = binding.wrappedValue as? U else { return nil }
    return Binding<U>(
        get: { value },
        set: { newValue in
            binding.wrappedValue = newValue as! T
        }
    )
}

func caffeinate(reason: String) -> UInt32? {
    #if os(iOS)
    DispatchQueue.main.async {
        UIApplication.shared.isIdleTimerDisabled = true
    }
    return nil
    #else
    var assertionID: IOPMAssertionID = 0
    var success = unsafe IOPMAssertionCreateWithName(
        kIOPMAssertionTypeNoDisplaySleep as CFString,
        IOPMAssertionLevel(kIOPMAssertionLevelOn),
        reason as CFString,
        &assertionID
    )
    if success == kIOReturnSuccess {
        return assertionID
    } else {
        return nil
    }
    #endif
}
func decaffeinate(_ id: UInt32?) {
    #if os(iOS)
    DispatchQueue.main.async {
        UIApplication.shared.isIdleTimerDisabled = false
    }
    #else
    if let id {
        IOPMAssertionRelease(id)
    }
    #endif
}

// MARK: compare
func compare<T: Comparable>(_ lhs: T?, _ rhs: T?, direction: SortDirection, putNilAtFirst: Bool = false) -> Bool {
    if lhs == nil {
        return putNilAtFirst
    } else if rhs == nil {
        return !putNilAtFirst
    } else {
        if direction == .ascending {
            return lhs! < rhs!
        } else {
            return lhs! > rhs!
        }
    }
}

enum SortDirection: CaseIterable {
    case ascending
    case descending
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

// MARK: doNothing
// Super super weird. I know it's replacable, though. --@ThreeManager785
func doNothing() {}

// MARK: formattedSongLength
func formattedSongLength(_ time: Double) -> String {
    let minutes = Int(time / 60)
    let seconds = time.truncatingRemainder(dividingBy: 60)
    return String(format: "%d:%04.1f", minutes, seconds) // 1:42.6
}

// MARK: getAttributedString
func getAttributedString(_ source: String, fontSize: Font.TextStyle = .body, fontWeight: Font.Weight = .regular, foregroundColor: Color = .primary) -> AttributedString {
    var attrString = AttributedString()
    attrString = AttributedString(source)
    attrString.font = .system(fontSize, weight: fontWeight)
    attrString.foregroundColor = foregroundColor
    return attrString
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

// MARK: getLocalizedColon
@inline(__always)
func getLocalizedColon(forLocale locale: DoriLocale) -> String {
    return locale == .en ? ": " : "："
}

// MARK: getPlaceholderColor
@inline(__always)
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
@inline(__always)
func getTertiaryLabelColor() -> Color {
#if os(iOS)
    return Color(UIColor.tertiaryLabel)
#else
    return Color(NSColor.tertiaryLabelColor)
#endif
}

// MARK: getStorageDictionary
func getStorageDictionary() -> [String: Any]? {
    let prefPath = NSHomeDirectory() + "/Library/Preferences/\(Bundle.main.infoDictionary?["CFBundleIdentifier"] as! String).plist"
    if let plistData = FileManager.default.contents(atPath: prefPath) {
        do {
            if var plistObject = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] {
                return plistObject
            }
        } catch {
            print(error)
        }
    }
    return nil
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

@discardableResult
func submitStats(
    key: String,
    action: Bool /* true: +1, false: -1 */
) async -> Bool {
    #if targetEnvironment(simulator)
    return false
    #endif
    
    guard !statsAPIPrivateKey.isEmpty else {
        return false
    }
    struct S: Claims {
        var sub: String
        var action: Bool
        var iat: Date
    }
    return await withCheckedContinuation { continuation in
        var jwt = JWT(header: .init(), claims: S(sub: key, action: action, iat: .now))
        let signer = JWTSigner.rs512(privateKey: statsAPIPrivateKey.data(using: .utf8)!)
        guard let signed = try? jwt.sign(using: signer) else {
            return continuation.resume(returning: false)
        }
        AF.request(
            "https://stats.greatdori.com/submit",
            method: .post,
            parameters: ["payload": signed],
            encoder: .json
        ).response { response in
            if let data = response.data, let json = try? JSON(data: data) {
                return continuation.resume(returning: json["success"].boolValue)
            } else {
                return continuation.resume(returning: false)
            }
        }
    }
}
@discardableResult
func submitCombinedStats(
    key: String,
    subKey: String,
    action: Bool /* true: +1, false: -1 */
) async -> Bool {
    #if targetEnvironment(simulator)
    return false
    #endif
    
    guard !statsAPIPrivateKey.isEmpty else {
        return false
    }
    struct S: Claims {
        var sub: String
        var action: Bool
        var subKey: String
        var iat: Date
    }
    return await withCheckedContinuation { continuation in
        var jwt = JWT(header: .init(), claims: S(sub: key, action: action, subKey: subKey, iat: .now))
        let signer = JWTSigner.rs512(privateKey: statsAPIPrivateKey.data(using: .utf8)!)
        guard let signed = try? jwt.sign(using: signer) else {
            return continuation.resume(returning: false)
        }
        AF.request(
            "https://stats.greatdori.com/submitCombined",
            method: .post,
            parameters: ["payload": signed],
            encoder: .json
        ).response { response in
            if let data = response.data, let json = try? JSON(data: data) {
                return continuation.resume(returning: json["success"].boolValue)
            } else {
                return continuation.resume(returning: false)
            }
        }
    }
}

/// Submit a room to BandoriStation anonymously with the ANON API.
/// - Parameters:
///   - number: Room number.
///   - type: Room type.
///   - description: Description text.
/// - Returns: Error text, or `nil` if succeeded.
func stationAnonymousSubmit(
    number: String,
    type: DoriAPI.Station.RoomType,
    description: String
) async throws {
    guard !anonAPIPrivateKey.isEmpty else {
        throw SimpleError(id: 2666000, message: "Private key is not available")
    }
    struct S: Claims {
        var iat: Date
        var iss: String
        var sub: String
        var aud: String
        var rtp: String
    }
    
    #if os(macOS)
    let platformExpert = unsafe IOServiceGetMatchingService(
        kIOMainPortDefault,
        IOServiceMatching("IOPlatformExpertDevice")
    )
    guard platformExpert != 0 else { throw SimpleError(id: 2666100, message: "Internal error") }
    defer { IOObjectRelease(platformExpert) }
    let key = kIOPlatformUUIDKey as CFString
    guard let _uuid = unsafe IORegistryEntryCreateCFProperty(
        platformExpert,
        key,
        kCFAllocatorDefault,
        0
    ).takeUnretainedValue() as? String else { throw SimpleError(id: 2666101, message: "Internal error") }
    let uuid = UUID(uuidString: _uuid)!
    #else
    guard let uuid = await UIDevice.current.identifierForVendor else {
        throw SimpleError(id: 2666157, message: "Internal error")
    }
    #endif
    
    return try await withCheckedThrowingContinuation { continuation in
        var jwt = JWT(
            header: .init(),
            claims: S(
                iat: .now,
                iss: uuid.uuidString,
                sub: number,
                aud: description,
                rtp: type.rawValue == 0 ? "" : String(type.rawValue)
            )
        )
        let signer = JWTSigner.rs512(privateKey: anonAPIPrivateKey.data(using: .utf8)!)
        guard let signed = try? jwt.sign(using: signer) else {
            return continuation.resume(throwing: SimpleError(id: 2666737, message: "Failed to generate request"))
        }
        AF.request(
            "https://station-anon.greatdori.com/room/anon",
            method: .post,
            parameters: ["payload": signed],
            encoder: .json
        ).response { response in
            if let data = response.data, let json = try? JSON(data: data) {
                print(json)
                if !json["success"].boolValue {
                    return continuation.resume(throwing: SimpleError(id: 2666999, message: json["error"].string ?? "Unknown error"))
                }
            } else {
                return continuation.resume(throwing: SimpleError(id: 2666638, message: "Network error"))
            }
        }
    }
}
