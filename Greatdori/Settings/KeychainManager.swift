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

import DoriKit
import Foundation
import Security

class Keychain: @unchecked Sendable {
    static let shared: Keychain = Keychain()
    
    func save(service: String, account: String, data: Data) throws {
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
    
    func load(service: String, account: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = unsafe SecItemCopyMatching(query as CFDictionary, &result)

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
    
    func delete(service: String, account: String) throws {
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
}


struct GreatdoriAccount: Codable, Hashable {
    var platform: Platform
    var account: String
    var username: String
    var uid: String?
    var isAutoRenewable: Bool
    
    func avatarURL() async -> URL? {
        switch platform {
        case .bandoriStation:
            guard let literalUID = self.uid, let uid = Int(literalUID) else {
                return nil
            }
            
            do {
                let info = try await DoriAPI.Station.userInformation(id: uid)
                return info.avatarURL()
            } catch {
                return nil
            }
        }
    }
    
    var identifider: String {
        uid ?? account
    }
    
    var description: String {
        "\(self.username) (\(identifider))"
    }
    
    
    func accountTokenIsValid(rescueIfDead: Bool = true) async -> Bool? {
        do {
            let token = try self.readToken()
            
            switch platform {
            case .bandoriStation:
                do {
                    let result = try await DoriAPI.Station.userInformation(userToken: DoriAPI.Station.UserToken(token))
                    if !(result.username ?? "").isEmpty {
                        return true
                    } else if !rescueIfDead || !self.isAutoRenewable {
                        return false
                    } else {
                        try await self.updateToken()
                        return await accountTokenIsValid(rescueIfDead: false)
                    }
                } catch {
                    return false
                }
            }
        } catch {
            print(error)
            return nil
        }
    }
    
    enum Platform: String, Codable, Hashable, CaseIterable {
        case bandoriStation
        
        var standardName: LocalizedStringResource {
            switch self {
            case .bandoriStation: "Settings.account.platform.bandori-station"
            }
        }
    }
    
    public func writeToken(_ token: String) throws {
        if let tokenData = token.data(using: .utf8) {
            try Keychain.shared.save(service: "Greatdori-Token-\(self.platform.rawValue)", account: self.account, data: tokenData)
        } else {
            throw SimpleError(id: 4001, message: "Cannot write token.")
        }
    }
    
    public func writePassword(_ password: String) throws {
        if let passwordData = password.data(using: .utf8) {
            try Keychain.shared.save(service: "Greatdori-Password-\(self.platform.rawValue)", account: self.account, data: passwordData)
        } else {
            throw SimpleError(id: 4002, message: "Cannot write password.")
        }
    }
    
    public func readToken() throws -> String {
        if let tokenData = try Keychain.shared.load(service: "Greatdori-Token-\(self.platform.rawValue)", account: self.account) {
            if let token = String(data: tokenData, encoding: .utf8) {
                return token
            } else {
                throw SimpleError(id: 4101, message: "Token is unparsable.")
            }
        } else {
            throw SimpleError(id: 4102, message: "No token found.")
        }
    }
    
    public func readPassword() throws -> String? {
        if let passwordData = try Keychain.shared.load(service: "Greatdori-Password-\(self.platform.rawValue)", account: self.account) {
            if let password = String(data: passwordData, encoding: .utf8) {
                return password
            } else {
                throw SimpleError(id: 4201, message: "Password is unparsable.")
            }
        } else {
            return nil
        }
    }
    
    public func updateToken(withPassword givenPassword: String? = nil) async throws {
        var password = givenPassword
        if password == nil {
            do {
                password = try self.readPassword()
            } catch {
                throw SimpleError(id: 4301, message: "Cannot read password.")
            }
        }
        if let password {
            switch self.platform {
            case .bandoriStation:
                let loginResult = try await DoriAPI.Station.login(username: self.account, password: password)
                switch loginResult {
                case .success(let token, let userInfo):
                    try self.writeToken(token.value)
                default:
                    throw SimpleError(id: -1)
                }
            }
        } else {
            throw SimpleError(id: 4300, message: "No password.")
        }
    }
    
    public func removePassword() throws {
        try Keychain.shared.delete(service: "Greatdori-Password-\(self.platform.rawValue)", account: self.account)
    }
    
    public func deleteAccount() throws {
        try self.removePassword()
        try Keychain.shared.delete(service: "Greatdori-Token-\(self.platform.rawValue)", account: self.account)
    }
}

final class AccountManager: @unchecked Sendable {
    static let bandoriStation = AccountManager(platform: .bandoriStation)
    
    var platform: GreatdoriAccount.Platform
    
    init(platform: GreatdoriAccount.Platform) {
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
