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
    @State var addSheetIsDisplaying = false
    @State var updateIndex = 0
    var body: some View {
        Form {
            SettingsAccountsSectionView(platform: .bandoriStation, usage: "Settings.account.bandori-station.usage", updateIndex: $updateIndex)
        }
        .formStyle(.grouped)
        .navigationTitle("Settings.account")
        .toolbar {
            Button(action: {
                addSheetIsDisplaying = true
            }, label: {
                Label("Settings.account.add", systemImage: "plus")
            })
        }
        .sheet(isPresented: $addSheetIsDisplaying, onDismiss: {
            updateIndex += 1
        }, content: {
            NavigationStack {
                SettingsAccountsAddView()
            } 
        })
    }
}

struct SettingsAccountsSectionView: View {
    var platform: GreatdoriAccount.Platform
    var usage: LocalizedStringResource? = nil
    @Binding var updateIndex: Int
    @State var currentPlatformAccounts: [GreatdoriAccount] = []
    @State var removeAccountAlertIsDisplaying = false
    @State var removingItemName = ""
    @State var removePendingItem = -1
    var body: some View {
        Section(content: {
            if !currentPlatformAccounts.isEmpty {
                ForEach(Array(currentPlatformAccounts.enumerated()), id: \.element.self) { index, item in
                    SettingsAccountsPreview(account: item, isPrimary: index == 0)
                        .contextMenu {
                            if index != 0 || isMACOS {
                                Button(action: {
                                    currentPlatformAccounts.move(fromOffsets: [index], toOffset: 0)
                                }, label: {
                                    Label("Settings.account.action.set-as-primary", systemImage: "arrow.up.to.line")
                                })
                                .disabled(index == 0)
                            }
                            Button(role: .destructive, action: {
                                removingItemName = item.description
                                removePendingItem = index
                                removeAccountAlertIsDisplaying = true
                            }, label: {
                                Label("Settings.account.action.remove", systemImage: "trash")
//                                    .foregroundStyle(.red)
                            })
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                            Button(role: .destructive, action: {
                                removingItemName = item.description
                                removePendingItem = index
                                removeAccountAlertIsDisplaying = true
                            }, label: {
                                Label("Settings.account.action.remove", systemImage: "trash")
                                    .foregroundStyle(.red)
                            })
                        })
                }
                .onMove { currentPlatformAccounts.move(fromOffsets: $0, toOffset: $1) }
            } else {
                Text("Settings.account.none")
                    .foregroundStyle(.secondary)
            }
        }, header: {
            Text(platform.standardName)
        }, footer: {
            if let usage {
                Text(usage)
            }
        })
        .onChange(of: currentPlatformAccounts) {
            do {
                try AccountManager(platform: platform).save(currentPlatformAccounts)
            } catch {
                print(error)
            }
        }
        .onChange(of: updateIndex, initial: true) {
            do {
                currentPlatformAccounts = try AccountManager(platform: platform).load()
            } catch {
                print(error)
            }
        }
        .alert("Settings.account.action.remove.alert.\(removingItemName)", isPresented: $removeAccountAlertIsDisplaying, actions: {
            Button(role: .destructive, action: {
                currentPlatformAccounts.remove(at: removePendingItem)
            }, label: {
                Text("Settings.account.action.remove.alert.confirm")
            })
        }, message: {
            Text("Settings.account.action.remove.alert.message")
        })
    }
}

struct SettingsAccountsPreview: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    var account: GreatdoriAccount
    var isPrimary: Bool = false
    @State var accountAvatarURL: URL? = nil
    @State var accountStatus: AccountStatus = .fetching
    var body: some View {
        HStack {
            WebImage(url: accountAvatarURL, content: { image in
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
                Group {
                    if isPrimary {
                        Text(account.identifider) + Text("Typography.bold-dot-seperater").bold() + Text("Settings.account.item.primary")
                    } else {
                        Text(account.identifider)
                    }
                }
                .foregroundStyle(.secondary)
            }
            Spacer()
            if account.isAutoRenewable {
                Image(systemName: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted")
                    .foregroundStyle(.secondary)
                    .help("Settings.account.item.auto-renew-is-on")
            }
            Group {
                if differentiateWithoutColor {
                    Image(systemName: accountStatus.symbol)
                } else {
                    Circle()
                        .frame(width: 10)
                }
            }
            .foregroundStyle(accountStatus.color)
            .padding(.trailing, 7)
        }
        .contentShape(Rectangle())
        .onAppear {
            Task {
                accountAvatarURL = await account.avatarURL()
            }
            Task {
                let tokenIsValid = await account.accountTokenIsValid()
                if let tokenIsValid {
                    accountStatus =  tokenIsValid ? .living : .dead
                } else {
                    accountStatus = .unknown
                }
            }
        }
    }
    
    enum AccountStatus: Codable {
        case living
        case dead
        case fetching
        case unknown
        
        var symbol: String {
            switch self {
            case .living:
                return "checkmark.circle"
            case .dead:
                return "exclamationmark.circle"
            case .fetching:
                return "questionmark.circle"
            case .unknown:
                return "questionmark.circle"
            }
        }
        
        var color: Color {
            switch self {
            case .living:
                return .green
            case .dead:
                return .red
            case .fetching:
                return .gray
            case .unknown:
                return .orange
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
        .wrapIf(!isMACOS) {
            $0.navigationTitle("Settings.account.new")
        }
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
            } else if let apiError = error as? DoriAPI.Station.APIError, apiError == .userNotFound {
                Text("Settings.account.new.error.user-not-found")
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
            } else {
                throw SimpleError(id: 4000)
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
                
                currentAccounts.append(newAccount)
                
                switch platform {
                case .bandoriStation:
                    try AccountManager.bandoriStation.save(currentAccounts)
                }
            } else {
                throw SimpleError(id: 4002, message: "No address given.")
            }
            
            accountIsAdding = false
            dismiss()
        } catch {
            accountAddingError = error
            errorAlertIsDisplaying = true
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

public struct SimpleError: Error, CustomStringConvertible {
    var id: Int
    var message: String? = nil
    
    public var description: String {
        if let message {
            return "\(message) (\(String(id)))"
        } else {
            return "Error \(String(id))"
        }
    }
}
