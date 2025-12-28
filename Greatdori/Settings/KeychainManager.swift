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
    let query: [String: Any] = [
        kSecClass as String: kSecClassInternetPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecValueData as String: data,
        kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
    ]

    SecItemDelete(query as CFDictionary)
    let status = SecItemAdd(query as CFDictionary, nil)

    guard status == errSecSuccess else {
        throw NSError(domain: "Keychain", code: Int(status))
    }
}

func keychainLoad(
    service: String,
    account: String
) throws -> Data? {
    let query: [String: Any] = [
        kSecClass as String: kSecClassInternetPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account,
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    if status == errSecItemNotFound {
        return nil
    }

    guard status == errSecSuccess else {
        throw NSError(domain: "Keychain", code: Int(status))
    }

    return result as? Data
}

func keychainDelete(
    service: String,
    account: String
) {
    let query: [String: Any] = [
        kSecClass as String: kSecClassInternetPassword,
        kSecAttrService as String: service,
        kSecAttrAccount as String: account
    ]

    SecItemDelete(query as CFDictionary)
}


struct GreatdoriAccount: Codable, Hashable {
    var platform: Platform
    var account: String
    var username: String
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
    static let shared = AccountManager()
    
    private init() {}
    
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
        
        return appFolder.appendingPathComponent("Accounts.plist")
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
