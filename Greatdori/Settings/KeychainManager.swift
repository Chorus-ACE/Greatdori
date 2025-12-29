//===---*- Greatdori! -*---------------------------------------------------===//
//
// KeychainManager.swift
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

import Foundation
import Security

func keychainSave(
    service: String,
    account: String,
    data: Data
) throws {
    let baseQuery: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    ]

    var addQuery = baseQuery
    addQuery[kSecValueData as String] = data

    let status = SecItemAdd(addQuery as CFDictionary, nil)

    if status == errSecDuplicateItem {
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: data
        ]

        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            attributesToUpdate as CFDictionary
        )

        guard updateStatus == errSecSuccess else {
            throw NSError(
                domain: "Keychain",
                code: Int(updateStatus),
                userInfo: [NSLocalizedDescriptionKey: "Keychain update failed (\(updateStatus))"]
            )
        }
    } else if status != errSecSuccess {
        throw NSError(
            domain: "Keychain",
            code: Int(status),
            userInfo: [NSLocalizedDescriptionKey: "Keychain add failed (\(status))"]
        )
    }
}


func keychainLoad(
    service: String,
    account: String
) throws -> Data? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecReturnData as String: kCFBooleanTrue as Any,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    if status == errSecItemNotFound {
        return nil
    }

    guard status == errSecSuccess else {
        throw NSError(
            domain: "Keychain",
            code: Int(status),
            userInfo: [NSLocalizedDescriptionKey: "Keychain read failed (\(status))"]
        )
    }

    guard let data = result as? Data else {
        throw NSError(
            domain: "Keychain",
            code: -1,
            userInfo: [NSLocalizedDescriptionKey: "Keychain returned non-Data result"]
        )
    }

    return data
}


func keychainDelete(
    service: String,
    account: String
) throws {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account
    ]

    let status = SecItemDelete(query as CFDictionary)

    if status == errSecItemNotFound {
        return
    }

    guard status == errSecSuccess else {
        throw NSError(
            domain: "Keychain",
            code: Int(status),
            userInfo: [
                NSLocalizedDescriptionKey: "Keychain delete failed (\(status))"
            ]
        )
    }
}



struct GreatdoriAccount: Codable, Hashable {
    var platform: Platform
    var account: String
    var username: String
    var uid: String?
    var isAutoRenewable: Bool
    
    var avatarURL: URL? {
        return nil
    }
    
    enum Platform: String, Codable, Hashable, CaseIterable {
        case bandoriStation
        
        var standardName: LocalizedStringResource {
            switch self {
            case .bandoriStation: "Settings.account.platform.bandori-station"
            }
        }
    }
}

final class AccountManager: @unchecked Sendable {
    static let bandoriStation = AccountManager(platform: .bandoriStation)
    
    var platform: GreatdoriAccount.Platform
    
    private init(platform: GreatdoriAccount.Platform) {
        self.platform = platform
    }
    
    // MARK: - File URL
    
    private var fileURL: URL {
        let fm = FileManager.default
        
        let baseURL = fm.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first!
        
        let appFolder = baseURL.appendingPathComponent("Greatdori", isDirectory: true)
        
        if !fm.fileExists(atPath: appFolder.path) {
            try? fm.createDirectory(
                at: appFolder,
                withIntermediateDirectories: true
            )
        }
        
        return appFolder.appendingPathComponent("Accounts-\(platform.rawValue).plist")
    }
    
    // MARK: - Write
    
    func save(_ accounts: [GreatdoriAccount]) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        let data = try encoder.encode(accounts)
        try data.write(to: fileURL, options: .atomic)
    }
    
    // MARK: - Read
    
    func load() throws -> [GreatdoriAccount] {
        let fm = FileManager.default
        
        guard fm.fileExists(atPath: fileURL.path) else {
            return []
        }
        
        let data = try Data(contentsOf: fileURL)
        return try PropertyListDecoder().decode(
            [GreatdoriAccount].self,
            from: data
        )
    }
}
