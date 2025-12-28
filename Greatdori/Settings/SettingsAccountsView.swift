//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsAccountsView.swift
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
import SDWebImageSwiftUI
import SwiftUI

struct SettingsAccountsView: View {
    @State var allAccounts: [GreatdoriAccount] = []
    @State var addSheetIsDisplaying = false
    var body: some View {
        Group {
            Section(content: {
                if !allAccounts.filter({ $0.platform == .bandoriStation }).isEmpty {
                    ForEach(allAccounts.filter({ $0.platform == .bandoriStation }), id: \.account) { item in
                        SettingsAccountsPreview(account: item)
                    }
                } else {
                    Text("Settings.account.none")
                        .foregroundStyle(.secondary)
                }
            }, header: {
                Text("Settings.account.bandori-station")
            }, footer: {
                Text("Settings.account.bandori-station.usage")
                    .toolbar { // Had to place it here.
                        Button(action: {
                            addSheetIsDisplaying = true
                        }, label: {
                            Label("Settings.account.add", systemImage: "plus")
                        })
                    }
            })
        }
        .navigationTitle("Settings.account")
        .onAppear {
            do {
                allAccounts = try AccountManager.shared.load()
            } catch {
                print(error)
            }
        }
        .onChange(of: allAccounts) {
            do {
                try AccountManager.shared.save(allAccounts)
            } catch {
                print(error)
            }
        }
        .sheet(isPresented: $addSheetIsDisplaying, content: {
            SettingsAccountsAddView()
        })
    }
}

struct SettingsAccountsPreview: View {
    var account: GreatdoriAccount
    var body: some View {
        HStack {
            WebImage(url: account.avatarURL, content: { image in
                image
                    .resizable()
            }, placeholder: {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .foregroundStyle(.gray)
            })
            .mask {
                Circle()
            }
            .frame(width: 40, height: 40)
            VStack(alignment: .leading) {
                Text(account.username)
                Text(account.uid ?? account.account)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if account.isAutoRenewable {
                Image(systemName: "clock")
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct SettingsAccountsAddView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @State var platform: GreatdoriAccount.Platform = .bandoriStation
    @State var account = ""
    @State var password = ""
    @State var autoRenew = false
    @State var accountIsAdding = false
    @State var errorAlertIsDisplaying = false
    @State var accountAddingError: Error? = nil
    
    private var demoEmailAddress: String = getRandomExmapleEmailAddress()
    let knownSimpleErrorIDs = [1000, 3001]
    var body: some View {
        Form {
            Section {
                Picker(selection: $platform, content: {
                    ForEach(GreatdoriAccount.Platform.allCases, id: \.self) { item in
                        Text(item.standardName)
                            .tag(item)
                    }
                }, label: {
                    Text("Settings.account.new.platform")
                })
            }
            
            Section {
                TextField("Settings.account.new.username", text: $account, prompt: Text(verbatim: demoEmailAddress))
                SecureField("Settings.account.new.password", text: $password)
            }
            
            Section(content: {
                Toggle(isOn: $autoRenew, label: {
                    Text("Settings.account.new.auto-renew")
                })
            }, footer: {
                Text("Settings.account.new.auto-renew.description")
            })
        }
        .formStyle(.grouped)
        .navigationTitle("Settings.account.new")
        .toolbar {
            if isMACOS && accountIsAdding {
                ToolbarItem(placement: .destructiveAction) {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Settings.account.new.adding")
                    }
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    dismiss()
                }, label: {
                    Label("Settings.account.new.cancel", systemImage: "xmark")
                        .wrapIf(isMACOS, in: {
                            $0.labelStyle(.titleOnly)
                        }, else: {
                            $0.labelStyle(.iconOnly)
                        })
                })
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(action: {
                    Task {
                        await addAccount()
                    }
                }, label: {
                    if !isMACOS && accountIsAdding {
                        ProgressView()
                    } else {
                        Label("Settings.account.new.add", systemImage: "plus")
                            .wrapIf(isMACOS, in: {
                                $0.labelStyle(.titleOnly)
                            }, else: {
                                $0.labelStyle(.iconOnly)
                            })
                    }
                })
                .disabled(account.isEmpty || password.isEmpty)
                .disabled(accountIsAdding)
            }
        }
        .alert("Settings.account.new.error.title", isPresented: $errorAlertIsDisplaying, presenting: accountAddingError, actions: { error in
            if let simpleError = error as? SimpleError, knownSimpleErrorIDs.contains(simpleError.id) {
                switch simpleError.id {
                case 3001:
                    Button(action: {
                        openURL(URL(string: "https://bandoristation.com/#/login")!)
                    }, label: {
                        Text("Settings.account.new.error.go-to-bandori-station")
                    })
                    .keyboardShortcut(.defaultAction)
                default:
                    EmptyView()
                }
            } else {
                Button(action: {
                    Task {
                        await addAccount()
                    }
                }, label: {
                    Text("Settings.account.new.error.retry")
                })
                .keyboardShortcut(.defaultAction)
            }
            Button(optionalRole: .cancel, action: {}, label: {
                Text("Settings.account.new.error.cancel")
            })
        }, message: { error in
            if let simpleError = error as? SimpleError, knownSimpleErrorIDs.contains(simpleError.id) {
                switch simpleError.id {
                case 1000:
                    Text("Settings.account.new.error.existed")
                case 3001:
                    Text("Settings.account.new.error.email-not-verified")
                default:
                    EmptyView()
                }
            } else if let apiError = error as? DoriAPI.Station.APIError, apiError == .wrongPassword {
                Text("Settings.account.new.error.wrong-password")
            } else if let apiError = error as? DoriAPI.Station.APIError, apiError == .tooManyRequests {
                Text("Settings.account.new.error.too-many-requests")
            } else {
                Text("Settings.account.new.error.\("\(error)")")
            }
        })
    }
    
    func addAccount() async {
        accountAddingError = nil
        accountIsAdding = true
        
        var accountUsername: String? = nil
        var accountPassword: String? = nil
        var accountAddress: String? = nil
        var accountToken: String? = nil
        var accountUID: String? = nil
        
        do {
            guard !account.isEmpty && !password.isEmpty else {
                throw SimpleError(id: 1001)
            }
            
            if platform == .bandoriStation {
                let loginResponse = try await DoriAPI.Station.login(username: account, password: password)
                if case .success(let token, let userInfo) = loginResponse {
                    accountAddress = "TODO: NO USERNAME"
                    accountToken = token.value
                    accountPassword = password
                    accountUsername = "TODO: NO USERNAME"
                    accountUID = String(userInfo.id)
                } else {
                    throw SimpleError(id: 3001)
                }
            } else {
                throw SimpleError(id: 4000)
            }
            
            // FIXME: Debate use, temp
            //            DoriAPI.Station.login(with: DoriAPI.Station.Credential(username: account, password: password))
            //            DoriAPI.Station.login(username: account, password: password)
            
            if let accountAddress, let accountUsername, let accountPassword, let accountToken {
                var currentAccounts = try AccountManager.shared.load()
                
                if currentAccounts.contains(where: { $0.platform == platform && $0.account == accountAddress }) {
                    throw SimpleError(id: 1000)
                }
                
                currentAccounts.append(GreatdoriAccount(platform: platform, account: accountAddress, username: accountUsername, uid: accountUID, isAutoRenewable: autoRenew))
                
                if let tokenData = accountToken.data(using: .utf8) {
                    try keychainSave(service: "Greatdori-Token-\(platform.rawValue)", account: accountAddress, data: tokenData)
                } else {
                    throw SimpleError(id: 4001, message: "Cannot write token.")
                }
                if autoRenew {
                    if let passwordData = accountPassword.data(using: .utf8) {
                        try keychainSave(service: "Greatdori-Password-\(platform.rawValue)", account: accountAddress, data: passwordData)
                    } else {
                        throw SimpleError(id: 4002, message: "Cannot write password.")
                    }
                }
                try AccountManager.shared.save(currentAccounts)
            } else {
                throw SimpleError(id: 4002, message: "No address given.")
            }
            
            accountIsAdding = false
            dismiss()
        } catch {
            errorAlertIsDisplaying = true
            accountAddingError = error
            accountIsAdding = false
        }
    }
}

func getRandomExmapleEmailAddress() -> String {
    // For fun only
    let randomCharacter = DoriCache.preCache.characters.filter({ $0.bandID != nil }).randomElement()
    if let name = randomCharacter?.nickname.en ?? randomCharacter?.characterName.en {
        return "\(name.replacingOccurrences(of: " ", with: "-").replacingOccurrences(of: "²", with: "2").lowercased())@example.com"
    } else {
        return "username@example.com"
    }
}

private struct SimpleError: Error, CustomStringConvertible {
    var id: Int
    var message: String? = nil
    
    var description: String {
        if let message {
            return "\(message) (\(String(id)))"
        } else {
            return "Error \(String(id))"
        }
    }
}
