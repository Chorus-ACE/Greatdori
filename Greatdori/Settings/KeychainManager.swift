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
        case .bestdori:
            let userInfo = await DoriAPI.User.userInformation(username: self.account)
            if let posterCard = userInfo?.posterCard {
                let card = await Card(id: posterCard.id)
                return posterCard.isTrained ? card?.thumbAfterTrainingImageURL : card?.thumbNormalImageURL
            }
            return nil
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
            case .bestdori:
                do {
                    guard let expiryDate = try self.readExpiryDate() else { throw SimpleError(id: 4299) }
                    
                    let result = await withUserToken(DoriAPI.User.Token(token, expirationDate: expiryDate)) {
                        await DoriAPI.User.myInformation()
                    }
                    
                    if !(result?.email ?? "").isEmpty {
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
        case bestdori
        case bandoriStation
        
        var standardName: LocalizedStringResource {
            switch self {
            case .bestdori: "Settings.account.platform.bestdori"
            case .bandoriStation: "Settings.account.platform.bandori-station"
            }
        }
    }
    
    public func writeToken(_ token: String) throws {
        if let tokenData = token.data(using: .utf8) {
            try Keychain.shared.save(service: "Greatdori-Token-\(self.platform.rawValue)", account: self.account, data: tokenData)
        } else {
            throw SimpleError(id: 4001, message: "Cannot encode token.")
        }
    }
    
    public func writePassword(_ password: String) throws {
        if let passwordData = password.data(using: .utf8) {
            try Keychain.shared.save(service: "Greatdori-Password-\(self.platform.rawValue)", account: self.account, data: passwordData)
        } else {
            throw SimpleError(id: 4002, message: "Cannot encode password.")
        }
    }
    
    public func writeExpiryDate(_ expiryDate: Date) throws {
        if let dateData = "\(String(expiryDate.timeIntervalSince1970))".data(using: .utf8) {
            try Keychain.shared.save(service: "Greatdori-ExpiryDate-\(self.platform.rawValue)", account: self.account, data: dateData)
        } else {
            throw SimpleError(id: 4003, message: "Cannot encode expiry date.")
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
    
    public func readExpiryDate() throws -> Date? {
        if let dateData = try Keychain.shared.load(service: "Greatdori-ExpiryDate-\(self.platform.rawValue)", account: self.account) {
            if let literalDate = String(data: dateData, encoding: .utf8), let doubleDate = Double(literalDate) {
                return Date(timeIntervalSince1970: doubleDate)
            } else {
                throw SimpleError(id: 4203, message: "Expiry date is unparsable.")
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
                case .success(let token, _):
                    try self.writeToken(token.value)
                default:
                    throw SimpleError(id: -1)
                }
            case .bestdori:
                let token = try await DoriAPI.User.login(username: self.account, password: password)
                try self.writeToken(token.value)
                try self.writeExpiryDate(token.expirationDate)
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
    static let bestdori = AccountManager(platform: .bestdori)
    
    var platform: GreatdoriAccount.Platform
    
    init(platform: GreatdoriAccount.Platform) {
        self.platform = platform
    }
    
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
    
    func save(_ accounts: [GreatdoriAccount]) throws {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        let data = try encoder.encode(accounts)
        try data.write(to: fileURL, options: .atomic)
    }
    
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
    
    static func addAccount(forPlatform platform: GreatdoriAccount.Platform, account: String, password: String, isAutoRenewable autoRenew: Bool = false) async throws {
        var accountUsername: String? = nil
        var accountPassword: String? = nil
        var accountAddress: String? = nil
        var accountToken: String? = nil
        var accountUID: String? = nil
        var accountTokenExpiryDate: Date? = nil
        
        guard !account.isEmpty && !password.isEmpty else {
            throw SimpleError(id: 1001)
        }
        
        switch platform {
        case .bandoriStation:
            let loginResponse = try await DoriAPI.Station.login(username: account, password: password)
            if case .success(let token, let incompleteUserInfo) = loginResponse {
                let userInfo = try await DoriAPI.Station.userInformation(id: incompleteUserInfo.id)
                accountAddress = userInfo.username
                accountToken = token.value
                accountPassword = password
                accountUsername = userInfo.username
                accountUID = String(userInfo.id)
            } else {
                throw SimpleError(id: 3001)
            }
        case .bestdori:
            let token = try await DoriAPI.User.login(username: account, password: password)
            let userInfo = await withUserToken(token, {
                await DoriAPI.User.myInformation()
            })
            if let userInfo {
                accountAddress = userInfo.username
                accountToken = token.value
                accountPassword = password
                accountUsername = userInfo.nickname.isEmpty ? userInfo.username : userInfo.nickname
                //                    accountUID = userInfo.email
                accountUID = "@\(userInfo.username)"
                accountTokenExpiryDate = token.expirationDate
            }
        }
        
        if let accountAddress, let accountUsername, let accountPassword, let accountToken {
            
            var currentAccounts: [GreatdoriAccount] = try AccountManager(platform: platform).load()
            
            if currentAccounts.contains(where: { $0.platform == platform && $0.account == accountAddress }) {
                throw SimpleError(id: 1000)
            }
            
            var newAccount = GreatdoriAccount(platform: platform, account: accountAddress, username: accountUsername, uid: accountUID, isAutoRenewable: autoRenew)
            
            try newAccount.writeToken(accountToken)
            
            if autoRenew {
                try newAccount.writePassword(password)
            }
            
            if let accountTokenExpiryDate {
                try newAccount.writeExpiryDate(accountTokenExpiryDate)
            }
            
            currentAccounts.append(newAccount)
            
            try AccountManager(platform: platform).save(currentAccounts)
        } else {
            throw SimpleError(id: 4002, message: "No address given.")
        }
    }
}
