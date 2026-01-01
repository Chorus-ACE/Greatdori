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
            SettingsAccountsSectionView(platform: .bestdori, usage: "Settings.account.bestdori.usage", updateIndex: $updateIndex)
            SettingsAccountsSectionView(platform: .bandoriStation, usage: "Settings.account.bandori-station.usage", updateIndex: $updateIndex)
            SettingsDocumentButton(document: "Accounts", label: {
                Text("Settings.account.learn-more")
            })
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
    @State var actionPendingItemName = ""
    @State var actionPendingItemIndex = -1
    
    @State var removeAccountAlertIsDisplaying = false
    @State var turnOffAutoRenewAlertIsDisplaying = false
    @State var turnOnAutoRenewAlertIsDisplaying = false
    
    @State var autoRenewPassword: String = ""
    @State var autoRenewError: Error? = nil
    @State var autoRenewErrorAlertIsDisplaying = false
    @State var autoRenewIsActivating = false
    var body: some View {
        Section(content: {
            if !currentPlatformAccounts.isEmpty {
                ForEach(Array(currentPlatformAccounts.enumerated()), id: \.element.self) { index, item in
                    SettingsAccountsWithContextMenu(item: item, index: index, currentPlatformAccounts: $currentPlatformAccounts, actionPendingItemName: $actionPendingItemName, actionPendingItemIndex: $actionPendingItemIndex, removeAccountAlertIsDisplaying: $removeAccountAlertIsDisplaying, turnOffAutoRenewAlertIsDisplaying: $turnOffAutoRenewAlertIsDisplaying, turnOnAutoRenewAlertIsDisplaying: $turnOnAutoRenewAlertIsDisplaying, autoRenewPassword: $autoRenewPassword)
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
        .alert("Settings.account.action.remove.alert.\(actionPendingItemName)", isPresented: $removeAccountAlertIsDisplaying, actions: {
            Button(role: .destructive, action: {
                do {
                    try currentPlatformAccounts[actionPendingItemIndex].deleteAccount()
                } catch {
                    print(error)
                }
                currentPlatformAccounts.remove(at: actionPendingItemIndex)
                    
            }, label: {
                Text("Settings.account.action.remove.alert.confirm")
            })
        }, message: {
            Text("Settings.account.action.remove.alert.message")
        })
        .alert("Settings.account.action.turn-off-auto-renew.alert.\(actionPendingItemName)", isPresented: $turnOffAutoRenewAlertIsDisplaying, actions: {
            Button(role: .destructive, action: {
                currentPlatformAccounts[actionPendingItemIndex].isAutoRenewable = false
                do {
                    try currentPlatformAccounts[actionPendingItemIndex].removePassword()
                } catch {
                    print(error)
                }
            }, label: {
                Text("Settings.account.action.turn-off-auto-renew.alert.confirm")
            })
        }, message: {
            Text("Settings.account.action.turn-off-auto-renew.alert.message")
        })
        .alert("Settings.account.action.turn-on-auto-renew.alert.\(actionPendingItemName)", isPresented: $turnOnAutoRenewAlertIsDisplaying, actions: {
            SecureField("Settings.account.action.turn-on-auto-renew.alert.password", text: $autoRenewPassword)
            Button(action: {
                Task {
                    autoRenewIsActivating = true
                    do {
                        try await currentPlatformAccounts[actionPendingItemIndex].updateToken(withPassword: autoRenewPassword)
                        try currentPlatformAccounts[actionPendingItemIndex].writePassword(autoRenewPassword)
                        currentPlatformAccounts[actionPendingItemIndex].isAutoRenewable = true
                    } catch {
                        autoRenewError = error
                        autoRenewErrorAlertIsDisplaying = true
                    }
                    autoRenewIsActivating = false
                }
            }, label: {
                if autoRenewIsActivating {
                    ProgressView()
                } else {
                    Text("Settings.account.action.turn-on-auto-renew.alert.confirm")
                }
            })
            .keyboardShortcut(.defaultAction)
            .disabled(autoRenewIsActivating || autoRenewPassword.isEmpty)
            Button(role: .cancel, action: {}, label: {
                Text("Settings.account.action.turn-on-auto-renew.alert.cancel")
            })
        }, message: {
            Text("Settings.account.action.turn-on-auto-renew.alert.message")
        })
        .loginError(isPresented: $autoRenewErrorAlertIsDisplaying, presenting: autoRenewError, retryAction: {
            autoRenewIsActivating = true
            do {
                try await currentPlatformAccounts[actionPendingItemIndex].updateToken(withPassword: autoRenewPassword)
                try currentPlatformAccounts[actionPendingItemIndex].writePassword(autoRenewPassword)
                currentPlatformAccounts[actionPendingItemIndex].isAutoRenewable = true
            } catch {
                autoRenewError = error
                autoRenewErrorAlertIsDisplaying = true
            }
            autoRenewIsActivating = false
        })
    }
}

struct SettingsAccountsWithContextMenu: View {
    @Environment(\.openURL) var openURL
    
    var item: GreatdoriAccount
    var index: Int
    @Binding var currentPlatformAccounts: [GreatdoriAccount]
    
    @Binding var actionPendingItemName: String
    @Binding var actionPendingItemIndex: Int
    
    @Binding var removeAccountAlertIsDisplaying: Bool
    @Binding var turnOffAutoRenewAlertIsDisplaying: Bool
    @Binding var turnOnAutoRenewAlertIsDisplaying: Bool
    
    @Binding var autoRenewPassword: String
    var body: some View {
        SettingsAccountsPreview(account: item, isPrimary: index == 0 && currentPlatformAccounts.count > 1)
            .contextMenu {
                if index != 0 || isMACOS {
                    Button(action: {
                        currentPlatformAccounts.move(fromOffsets: [index], toOffset: 0)
                    }, label: {
                        Label("Settings.account.action.set-as-primary", systemImage: "arrow.up.to.line")
                    })
                    .disabled(index == 0)
                }
                
                if let profile = item.personalProfile {
                    Button(action: {
                        openURL(profile)
                    }, label: {
                        Label("Settings.account.action.open", systemImage: "arrow.up.forward.app")
                    })
                }
                
                if item.isAutoRenewable {
                    Button(role: .destructive, action: {
                        actionPendingItemName = item.description
                        actionPendingItemIndex = index
                        turnOffAutoRenewAlertIsDisplaying = true
                    }, label: {
                        Label("Settings.account.action.turn-off-auto-renew", systemImage: "clock.badge.xmark")
                    })
                } else {
                    Button(action: {
                        autoRenewPassword = ""
                        actionPendingItemName = item.description
                        actionPendingItemIndex = index
                        turnOnAutoRenewAlertIsDisplaying = true
                    }, label: {
                        Label("Settings.account.action.turn-on-auto-renew", systemImage: "clock.arrow.trianglehead.clockwise.rotate.90.path.dotted")
                    })
                }
                
                Button(role: .destructive, action: {
                    actionPendingItemName = item.description
                    actionPendingItemIndex = index
                    removeAccountAlertIsDisplaying = true
                }, label: {
                    Label("Settings.account.action.remove", systemImage: "trash")
//                                    .foregroundStyle(.red)
                })
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true, content: {
                Button(role: .destructive, action: {
                    actionPendingItemName = item.description
                    actionPendingItemIndex = index
                    removeAccountAlertIsDisplaying = true
                }, label: {
                    Label("Settings.account.action.remove", systemImage: "trash")
                        .foregroundStyle(.red)
                })
            })
    }
}


struct SettingsAccountsPreview: View {
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    @Environment(\.dismiss) var dismiss
    var account: GreatdoriAccount
    var isPrimary: Bool = false
    @State var accountAvatarURL: URL? = nil
    @State var accountStatus: AccountStatus = .fetching
    
    @State var rescuePassword = ""
    @State var rescueAlertIsDisplaying = false
    @State var isRescuing = false
    @State var rescueErrorAlertIsDisplaying = false
    @State var rescueError: Error? = nil
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
                    if accountStatus == .dead {
                        Text(account.identifider) + Text("Typography.bold-dot-seperater").bold() + Text("Settings.account.item.actions-needed")
                    } else if isPrimary {
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
        .onTapGesture {
            if accountStatus == .dead {
                isRescuing = false
                rescuePassword = ""
                rescueAlertIsDisplaying = true
            }
        }
        .alert("Settings.account.item.rescue.alert.\(account.description)", isPresented: $rescueAlertIsDisplaying, actions: {
            SecureField("Settings.account.item.rescue.alert.password", text: $rescuePassword)
            Button(optionalRole: .destructive, action: {
                Task {
                    isRescuing = true
                    do {
                        try await account.updateToken(withPassword: rescuePassword)
                    } catch {
                        rescueError = error
                        rescueErrorAlertIsDisplaying = true
                    }
                    isRescuing = false
                }
            }, label: {
                if isRescuing {
                    Text("Station.item.report.alert.confirm")
                }
            })
            .keyboardShortcut(.defaultAction)
            .disabled(rescuePassword.isEmpty || isRescuing)
            Button(role: .cancel, action: {}, label: {
                Text("Settings.account.item.rescue.alert.cancel")
            })
        }, message: {
            Text("Settings.account.item.rescue.alert.message")
        })
        .loginError(isPresented: $rescueAlertIsDisplaying, presenting: rescueError, retryAction: {
            isRescuing = true
            do {
                try await account.updateToken(withPassword: rescuePassword)
            } catch {
                rescueErrorAlertIsDisplaying = true
            }
            isRescuing = false
        })
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
    @State var platform: GreatdoriAccount.Platform = .bestdori
    @State var account = ""
    @State var password = ""
    @State var autoRenew = false
    @State var accountIsAdding = false
    @State var errorAlertIsDisplaying = false
    @State var accountAddingError: Error? = nil
    
    private var demoEmailAddress: String = getRandomExmapleEmailAddress()
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
                TextField("Settings.account.new.username", text: $account, prompt: Text(demoEmailAddress))
                    .trailingTextFieldForIOS("Settings.account.new.username")
                SecureField("Settings.account.new.password", text: $password, prompt: Text("Settings.account.new.password.prompt"))
                    .trailingTextFieldForIOS("Settings.account.new.password")
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
        .loginError(isPresented: $errorAlertIsDisplaying, presenting: accountAddingError, retryAction: { await addAccount() }, openURL: openURL)
    }
    
    func addAccount() async {
        accountAddingError = nil
        accountIsAdding = true
        do {
            try await AccountManager.addAccount(forPlatform: platform, account: account, password: password, isAutoRenewable: autoRenew)
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

extension View {
//    @ViewBuilder
    func loginError(isPresented: Binding<Bool>, presenting: Error?, retryAction: (() async -> Void)? = nil, openURL: OpenURLAction? = nil) -> some View {
        let knownSimpleErrorIDs = [1000, 3001]
        return self.alert("Settings.account.error.title", isPresented: isPresented, presenting: presenting, actions: { error in
            if let simpleError = error as? SimpleError, knownSimpleErrorIDs.contains(simpleError.id) {
                switch simpleError.id {
                case 3001:
                    if let openURL {
                        Button(action: {
                            openURL(URL(string: "https://bandoristation.com/#/login")!)
                        }, label: {
                            Text("Settings.account.error.go-to-bandori-station")
                        })
                        .keyboardShortcut(.defaultAction)
                    }
                default:
                    EmptyView()
                }
            } else if let castedError = error as? DoriAPI.Station.APIError, castedError == .wrongPassword {
                EmptyView()
            } else if let castedError = error as? DoriAPI.User.LoginError, [DoriAPI.User.LoginError.invalidCredential, .invalidPassword, .invalidUsername].contains(castedError) {
                EmptyView()
            } else {
                if let retryAction {
                    Button(action: {
                        Task {
                            await retryAction()
                        }
                    }, label: {
                        Text("Settings.account.error.retry")
                    })
                    .keyboardShortcut(.defaultAction)
                }
            }
            Button(optionalRole: .cancel, action: {}, label: {
                Text("Settings.account.error.cancel")
            })
        }, message: { error in
            if let simpleError = error as? SimpleError, knownSimpleErrorIDs.contains(simpleError.id) {
                switch simpleError.id {
                case 1000:
                    Text("Settings.account.error.existed")
                case 3001:
                    Text("Settings.account.error.email-not-verified")
                default:
                    EmptyView()
                }
            } else if let castedError = error as? DoriAPI.Station.APIError, castedError == .userNotFound {
                Text("Settings.account.error.user-not-found")
            } else if let castedError = error as? DoriAPI.Station.APIError, castedError == .wrongPassword {
                Text("Settings.account.error.wrong-password")
            } else if let castedError = error as? DoriAPI.User.LoginError, [DoriAPI.User.LoginError.invalidCredential, .invalidPassword, .invalidUsername].contains(castedError) {
                Text("Settings.account.error.wrong-password")
            } else if let castedError = error as? DoriAPI.Station.APIError, castedError == .tooManyRequests {
                Text("Settings.account.error.too-many-requests")
            } else {
                Text("Settings.account.error.\("\(error)")")
            }
        })
    }
}
