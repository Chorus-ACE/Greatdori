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
    @State var description = ""
    @State var roomType: DoriAPI.Station.RoomType = .daredemo
    
    @State var gameplayIsSubmitting = false
    @State var errorAlertIsDisplaying = false
    @State var submitError: Error? = nil
    
    @State var wordbankIsExpanded = false
    @State var wordbank: [String] = []
    @State var wordbankNewEntry = ""
    @State var wordbankIsImporting = false
    @State var wordbankImportResultAlertIsDisplaying = false
    @State var wordbankImportResult: Result<(Int, Int), Error> = .failure(NSError(domain: "", code: -1))
    var body: some View {
        NavigationStack {
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
                    TextField("Station.new.number", value: $roomNumber, formatter: DigitStringFormatter(maxLength: 6), prompt: Text(verbatim: "123456"))
                        .trailingTextFieldForIOS("Station.new.number")
                        .wrapIf(true) {
#if os(iOS)
                            $0.keyboardType(.numberPad)
#else
                            $0
#endif
                        }
                    TextField("Station.new.description", text: $description, prompt: Text("Station.new.description.prompt"))
                        .trailingTextFieldForIOS("Station.new.description")
                    Picker("Station.new.type", selection: $roomType, content: {
                        ForEach(DoriAPI.Station.RoomType.allCases, id: \.self) { item in
                            Text(item.localizedName)
                                .tag(item)
                        }
                    })
                }
                
                Section {
                    Button(action: {
                        wordbankIsExpanded.toggle()
                    }, label: {
                        HStack {
                            Text("Station.new.wordbank")
                            Spacer()
                            if wordbank.count > 0 {
                                Text("\(wordbank.count)")
                                    .foregroundStyle(.secondary)
                            }
                            Image(systemName: "chevron.forward")
                                .foregroundStyle(.secondary)
                                .rotationEffect(Angle(degrees: wordbankIsExpanded ? 90 : 0))
                        }
                        .contentShape(Rectangle())
                    })
                    .buttonStyle(.plain)
                    
                    if wordbankIsExpanded {
                        if !wordbank.isEmpty {
                            FlowLayout(items: wordbank, verticalSpacing: flowLayoutDefaultVerticalSpacing, horizontalSpacing: flowLayoutDefaultHorizontalSpacing) { item in
                                TextCapsuleWithDeleteButton(deleteAction: {
                                    wordbank.removeAll(where: { $0 == item })
                                }, showDivider: true, content: {
                                    Button(action: {
                                        description.append(" \(item)")
                                    }, label: {
                                        Text(item)
                                    })
                                })
                                .buttonStyle(.plain)
                            }
                        } else {
                            HStack {
                                Text("Station.new.wordbank.empty")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                        
                        HStack {
                            TextField("Station.new.wordbank.new.text-field", text: $wordbankNewEntry, prompt: Text(isMACOS ? "Station.new.wordbank.new.prompt" : "Station.new.wordbank.new.text-field"))
                            Button(action: {
                                wordbank.append(wordbankNewEntry)
                                wordbankNewEntry = ""
                            }, label: {
                                Image(systemName: "plus")
                            })
                            .disabled(wordbank.contains(wordbankNewEntry) || wordbankNewEntry.isEmpty)
                        }
                        
                        if let selectedAccount {
                            HStack {
                                Text("Station.new.wordbank.import")
                                Spacer()
                                Text("Station.new.wordbank.import.from.\(selectedAccount.username)")
                                    .foregroundStyle(.secondary)
                                Button(action: {
                                    Task {
                                        await fetchKeyword()
                                    }
                                }, label: {
                                    if wordbankIsImporting {
                                        ProgressView()
                                            .controlSize(.small)
                                    } else {
                                        Text("Station.new.wordbank.import.import")
                                    }
                                })
                                .disabled(wordbankIsImporting)
                            }
                        }
                    }
                }
                .animation(.easeInOut(duration: 0.2), value: wordbankIsExpanded)
                .alert("Station.new.wordbank.import.alert.title", isPresented: $wordbankImportResultAlertIsDisplaying, actions: {}, message: {
                    switch wordbankImportResult {
                    case .success(let success):
                        if success.1 == 0 {
                            Text("Station.new.wordbank.import.alert.success.\(success.0)")
                        } else {
                            Text("Station.new.wordbank.import.alert.success.\(success.0).\(success.1)")
                        }
                    case .failure(let failure):
                        Text("Station.new.wordbank.import.alert.error.\("\(failure)")")
                    }
                })
                
                Section {
                    if roomNumber.count < 5 {
                        Label("Station.new.issue.number-too-short", systemImage: "exclamationmark.circle")
                            .foregroundStyle(.yellow)
                    }
                    if description.isEmpty {
                        Label("Station.new.issue.empty-description", systemImage: "exclamationmark.circle")
                            .foregroundStyle(.yellow)
                    }
                    if !description.isEmpty && roomNumber.count >= 5 {
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
                            await submitGameplay()
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
                    .disabled(roomNumber.count < 5 || description.isEmpty)
                    .disabled(gameplayIsSubmitting)
                }
            }
            .onAppear {
                roomType = .init(rawValue: UserDefaults.standard.integer(forKey: "DefaultSubmittingRoomType")) ?? .daredemo
                wordbank = (UserDefaults.standard.array(forKey: "StationWordbank") as? [String]) ?? []
                
                allAccounts = ((try? AccountManager.bandoriStation.load()) ?? []) + [nil]
                selectedAccount = allAccounts.first ?? nil
            }
            .onChange(of: roomType, {
                UserDefaults.standard.set(roomType.rawValue, forKey: "DefaultSubmittingRoomType")
            })
            .onChange(of: wordbank, {
                UserDefaults.standard.set(wordbank, forKey: "StationWordbank")
            })
            .loginError(isPresented: $errorAlertIsDisplaying, presenting: submitError, retryAction: { await submitGameplay() }, openURL: openURL)
        }
    }
    
    func submitGameplay(rescueIfDead: Bool = true) async {
        gameplayIsSubmitting = true
        if let selectedAccount {
            do {
                let token = try selectedAccount.readToken()
                try await DoriAPI.Station.postRoom(number: roomNumber, type: roomType, description: description, user: .init(token), client: "Greatdori")
                dismiss()
            } catch {
                do {
                    if rescueIfDead {
                        try await selectedAccount.updateToken()
                        await submitGameplay(rescueIfDead: false)
                    } else {
                        throw error
                    }
                } catch {
                    submitError = error
                    errorAlertIsDisplaying = true
                }
            }
        } else {
            if let error = await stationAnonymousSubmit(
                number: roomNumber,
                type: roomType,
                description: description
            ) {
                submitError = SimpleError(id: 500, message: error)
            }
            dismiss()
        }
        gameplayIsSubmitting = false
    }
    
    func fetchKeyword(rescueIfDead: Bool = true) async {
        if let selectedAccount {
            Task {
                wordbankIsImporting = true
                do {
                    let token = try selectedAccount.readToken()
                    let userInfo = try await DoriAPI.Station.userInformation(userToken: .init(token))
                    let preferredWords = userInfo.websiteSettings?.postPreference.preselectedWordList
                    
                    if let preferredWords {
                        var duplicatesCount = 0
                        for word in preferredWords {
                            if !wordbank.contains(word) {
                                wordbank.append(word)
                            } else {
                                duplicatesCount += 1
                            }
                        }
                        
                        wordbankImportResult = .success((preferredWords.count, duplicatesCount))
                    } else {
                        throw SimpleError(id: 5010, message: "Cannot get word list")
                    }
                } catch {
                    do {
                        if rescueIfDead {
                            try await selectedAccount.updateToken()
                            await fetchKeyword(rescueIfDead: false)
                        } else {
                            throw error
                        }
                    } catch {
                        wordbankImportResult = .failure(error)
                    }
                }
                wordbankIsImporting = false
                wordbankImportResultAlertIsDisplaying = true
            }
        }
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
