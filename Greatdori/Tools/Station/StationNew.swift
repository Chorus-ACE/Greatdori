//===---*- Greatdori! -*---------------------------------------------------===//
//
// StationNew.swift
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
import SwiftUI

struct StationAddView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @State var allAccounts: [GreatdoriAccount?] = []
    @State var selectedAccount: GreatdoriAccount? = nil
    
    @State var roomNumber = ""
    @State var message = ""
    
    @State var gameplayIsSubmitting = false
    @State var errorAlertIsDisplaying = false
    @State var submitError: Error? = nil
    var body: some View {
        Form {
            Section(content: {
                Picker(selection: $selectedAccount, content: {
                    ForEach(allAccounts, id: \.self) { item in
                        if let item {
                            VStack {
                                Text(item.username)
                                Text(item.identifider)
                            }
                            .tag(item)
                        } else {
                            Text("Station.new.account.anon")
                                .tag(item)
                        }
                    }
                }, label: {
                    Text("Station.new.account")
                })
            }, footer: {
                if selectedAccount == nil {
                    Text("Station.new.account.new.declaration")
                }
            })
            
            Section {
                TextField("Station.new.number", value: $roomNumber, formatter: DigitStringFormatter(maxLength: 6))
                // Keyboard Layout?
                TextField("Station.new.description", text: $message)
            }
            
            Section {
                if roomNumber.count < 5 {
                    Label("Station.new.issue.number-too-short", systemImage: "exclamationmark.circle")
                        .foregroundStyle(.yellow)
                }
                if message.isEmpty {
                    Label("Station.new.issue.empty-message", systemImage: "exclamationmark.circle")
                        .foregroundStyle(.yellow)
                }
                if !message.isEmpty && roomNumber.count >= 5 {
                    Label("Station.new.issue.ready", systemImage: "checkmark.circle")
                        .foregroundStyle(.green)
                }
            }
        }
        .formStyle(.grouped)
        .wrapIf(!isMACOS) {
            $0.navigationTitle("Station.new")
        }
        .toolbar {
            if isMACOS && gameplayIsSubmitting {
                ToolbarItem(placement: .destructiveAction) {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Station.new.submitting")
                    }
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    dismiss()
                }, label: {
                    Label("Station.new.cancel", systemImage: "xmark")
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
//                        await addAccount()
                    }
                }, label: {
                    if !isMACOS && gameplayIsSubmitting {
                        ProgressView()
                    } else {
                        Label("Station.new.submit", systemImage: "plus")
                            .wrapIf(isMACOS, in: {
                                $0.labelStyle(.titleOnly)
                            }, else: {
                                $0.labelStyle(.iconOnly)
                            })
                    }
                })
                .disabled(roomNumber.count < 5 || message.isEmpty)
                .disabled(gameplayIsSubmitting)
            }
        }
        .onAppear {
            allAccounts = ((try? AccountManager.bandoriStation.load()) ?? []) + [nil]
            selectedAccount = allAccounts.first ?? nil
        }
        .loginError(isPresented: $errorAlertIsDisplaying, presenting: submitError, retryAction: {  }, openURL: openURL)
    }
    
    func submitGameplay() async {
        gameplayIsSubmitting = true
        
    }
}

final class DigitStringFormatter: Formatter {
    let maxLength: Int
    
    init(maxLength: Int = 6) {
        self.maxLength = maxLength
        super.init()
    }
    
    required init?(coder: NSCoder) {
        self.maxLength = 6
        super.init(coder: coder)
    }
    
    override func string(for obj: Any?) -> String? {
        obj as? String
    }
    
    override func getObjectValue(
        _ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
        for string: String,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        let filtered = string
            .filter { $0.isNumber }
            .prefix(maxLength)
        
        obj?.pointee = String(filtered) as NSString
        return true
    }
    
    override func isPartialStringValid(
        _ partialString: String,
        newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        // 只允许数字
        guard partialString.allSatisfy(\.isNumber) else {
            return false
        }
        
        // 限制长度
        return partialString.count <= maxLength
    }
}
