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
    var isSelected: Bool
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
                Text(account.account)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundStyle(.tint)
                    .font(.title3)
            }
        }
    }
}

struct SettingsAccountsAddView: View {
    @Environment(\.dismiss) var dismiss
    @State var platform: GreatdoriAccount.Platform = .bandoriStation
    @State var account = ""
    @State var password = ""
    @State var autoRenew = false
    
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
                    
                }, label: {
                    Label("Settings.account.new.add", systemImage: "plus")
                        .wrapIf(isMACOS, in: {
                            $0.labelStyle(.titleOnly)
                        }, else: {
                            $0.labelStyle(.iconOnly)
                        })
                })
            }
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
