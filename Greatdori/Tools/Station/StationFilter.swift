//===---*- Greatdori! -*---------------------------------------------------===//
//
// FilterView.swift
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

#if os(iOS)
import UIKit
#endif

struct StationFilter: Hashable, Sendable, Codable {
    var roomTypes: Set<DoriAPI.Station.RoomType> = Set(DoriAPI.Station.RoomType.allCases)
    var disallowedKeywords: [String] = []
    var disallowedUsers: [DisallowedUser] = []
    
    struct DisallowedUser: Hashable, Sendable, Codable {
        var id: Int
        var name: String
    }
    
    var isFiltering: Bool {
        return roomTypes != Set(DoriAPI.Station.RoomType.allCases) || !roomTypes.isEmpty || !disallowedUsers.isEmpty
    }
}


struct StationFilterView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Binding var filter: StationFilter
    
    @State var lastSelectAllActionIsDeselect: Bool = false
    @State var theItemThatShowsSelectAllTips: DoriFrontend.Filter.Key? = nil
    @State var keywordNewItem = ""
    
    @State var allAccounts: [GreatdoriAccount] = []
    @State var selectedAccount: GreatdoriAccount? = nil
    
    @State var isImporting = false
    @State var importResultAlertIsDisplaying = false
    @State var importResult: Result<Void, Error> = .failure(NSError(domain: "", code: -1))
    var body: some View {
        Form {
            Section(content: {
                VStack {
                    HStack {
                        VStack {
                            Text("Station.filter.type")
                                .bold()
                                .accessibilityHeading(.h2)
                        }
                        Spacer()
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.05)) {
                                if filter.roomTypes.isEmpty {
                                    filter.roomTypes = Set(DoriAPI.Station.RoomType.allCases)
                                } else {
                                    filter.roomTypes = Set([])
                                }
                            }
                        }, label: {
                            Group {
                                let selectionStatus = (filter.roomTypes.count == DoriAPI.Station.RoomType.allCases.count) ? true : (filter.roomTypes.count == 0 ? false : nil)
                                CompactToggle(isLit: selectionStatus)
                                    .accessibilityValue({
                                        if selectionStatus == true {
                                            return "Accessibility.filter.selections-toggle.value.all-selected"
                                        } else if selectionStatus == false {
                                            return "Accessibility.filter.selections-toggle.value.none-selected"
                                        } else {
                                            return "Accessibility.filter.selections-toggle.value.partially-selected"
                                        }
                                    }())
                                    .accessibilityHint({
                                        if selectionStatus == false {
                                            return "Accessibility.filter.selections-toggle.hint.select-all"
                                        } else {
                                            return "Accessibility.filter.selections-toggle.hint.deselect-all"
                                        }
                                    }())
                            }
                            .foregroundStyle(.secondary)
                            .accessibilityLabel("Accessibility.filter.selections-toggle")
                        })
                        .buttonStyle(.plain)
                    }
                    
                    FlowLayout(items: DoriAPI.Station.RoomType.allCases, verticalSpacing: flowLayoutDefaultVerticalSpacing, horizontalSpacing: flowLayoutDefaultHorizontalSpacing) { item in
                        Button(action: {
                            if filter.roomTypes.contains(item) {
                                filter.roomTypes.remove(item)
                            } else {
                                filter.roomTypes.insert(item)
                            }
                        }, label: {
                            FilterItemView.FilterSelectionCapsuleView(isActive: filter.roomTypes.contains(item), content: {
                                Text(item.localizedName)
                            })
                        })
                        .buttonStyle(.plain)
                        .wrapIf(filter.roomTypes.contains(item), in: {
                            $0.accessibilityValue("Accessibility.filter.activated")
                        })
                        .accessibilityHint("Accessibility.filter.tap-to-toggle")
                    }
                }
                VStack {
                    HStack {
                        VStack {
                            Text("Station.filter.keyword")
                                .bold()
                                .accessibilityHeading(.h2)
                        }
                        Spacer()
                        Button(action: {
                            filter.disallowedKeywords.removeAll()
                        }, label: {
                            Text("Station.filter.clear")
                                .foregroundStyle(.secondary)
                        })
                        .buttonStyle(.plain)
                    }
                    
                    HStack {
                        TextField("", text: $keywordNewItem, prompt: Text("Station.filter.keyword.prompt"))
                            .labelsHidden()
//                            .textFieldStyle(.roundedBorder)
                        Button(action: {
                            if !filter.disallowedKeywords.contains(keywordNewItem) {
                                filter.disallowedKeywords.append(keywordNewItem)
                                keywordNewItem = ""
                            }
                        }, label: {
                            Label("Station.filter.keyword.add", systemImage: "plus")
                                .labelStyle(.iconOnly)
                        })
                        .disabled(keywordNewItem.isEmpty || filter.disallowedKeywords.contains(keywordNewItem))
                    }
                    
                    Group {
                        if !filter.disallowedKeywords.isEmpty {
                            FlowLayout(items: filter.disallowedKeywords, verticalSpacing: flowLayoutDefaultVerticalSpacing, horizontalSpacing: flowLayoutDefaultHorizontalSpacing) { item in
                                TextCapsuleWithDeleteButton(deleteAction: {
                                    filter.disallowedKeywords.removeAll(where: { $0 == item })
                                }, content: {
                                    Text(item)
                                })
                                .buttonStyle(.plain)
                            }
                        } else {
                            HStack {
                                Text("Station.filter.keyword.none")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .padding(.top, 3)
                }
                
                VStack {
                    HStack {
                        VStack {
                            Text("Station.filter.user")
                                .bold()
                                .accessibilityHeading(.h2)
                        }
                        Spacer()
                        Button(action: {
                            filter.disallowedUsers.removeAll()
                        }, label: {
                            Text("Station.filter.clear")
                                .foregroundStyle(.secondary)
                        })
                        .buttonStyle(.plain)
                    }
                    
                    Group {
                        if !filter.disallowedUsers.isEmpty {
                            FlowLayout(items: filter.disallowedUsers, verticalSpacing: flowLayoutDefaultVerticalSpacing, horizontalSpacing: flowLayoutDefaultHorizontalSpacing) { item in
                                TextCapsuleWithDeleteButton(deleteAction: {
                                    filter.disallowedUsers.removeAll(where: { $0 == item })
                                }, content: {
                                    Text(item.name)
                                })
                                .buttonStyle(.plain)
                            }
                        } else {
                            HStack {
                                Text("Station.filter.user.none")
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .padding(.top, 1)
                }
            }, header: {
                VStack(alignment: .leading) {
                    if sizeClass == .compact {
                        Color.clear.frame(height: 10)
                    }
                    Text("Station.filter")
                }
            })
            
            Section {
                Button(action: {
                    filter = .init()
                }, label: {
                    Text("Station.filter.clear-all")
                })
                .disabled(!filter.isFiltering)
            }
            
            if !allAccounts.isEmpty {
                Section("Station.filter.import") {
                    Picker(selection: $selectedAccount, content: {
                        ForEach(allAccounts, id: \.self) { item in
                            Text(item.description)
                                .tag(item)
                        }
                    }, label: {
                        Text("Station.filter.import.source")
                    }, optionalCurrentValueLabel: {
                        if let selectedAccount {
                            Text(selectedAccount.username)
                        } else {
                            Text("Station.filter.import.source.none")
                        }
                    })
                    .id(allAccounts)
                    HStack {
                        Button(action: {
                            Task {
                                await importFilter()
                            }
                        }, label: {
                            Text("Station.filter.import.import")
                        })
                        .disabled(isImporting || selectedAccount == nil)
                        Spacer()
                        if isImporting {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
            }
        }
        .onAppear {
            allAccounts = (try? AccountManager.bandoriStation.load()) ?? []
            selectedAccount = allAccounts.first
        }
        .alert("Station.filter.import.alert.title", isPresented: $importResultAlertIsDisplaying, actions: {}, message: {
            switch importResult {
            case .success(_):
                Text("Station.filter.import.alert.success")
            case .failure(let failure):
                Text("Station.filter.import.alert.error.\("\(failure)")")
            }
        })
    }
    
    func importFilter(rescueIfDead: Bool = true) async {
        if let selectedAccount {
            Task {
                isImporting = true
                do {
                    let token = try selectedAccount.readToken()
                    let onlineFilter = try await DoriAPI.Station.roomFilter(fromUserToken: .init(token))
                    
                    filter.roomTypes = onlineFilter.roomTypes
                    
                    for keyword in onlineFilter.keywords {
                        if !filter.disallowedKeywords.contains(keyword) {
                            filter.disallowedKeywords.append(keyword)
                        }
                    }
                    
                    for user in onlineFilter.users {
                        if !filter.disallowedUsers.contains(where: { $0.id == user.id }) {
                            filter.disallowedUsers.append(StationFilter.DisallowedUser(id: user.id, name: user.username ?? String(user.id)))
                        }
                    }
                    
                    importResult = .success(())
                } catch {
                    do {
                        if rescueIfDead {
                            try await selectedAccount.updateToken()
                            await importFilter(rescueIfDead: false)
                        } else {
                            throw error
                        }
                    } catch {
                        importResult = .failure(error)
                    }
                }
                isImporting = false
                importResultAlertIsDisplaying = true
            }
        }
    }
}

struct TextCapsuleWithDeleteButton<Content: View>: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let deleteAction: () -> Void
    let showDivider: Bool
    let content: Content
    let cornerRadius: CGFloat = capsuleDefaultCornerRadius
    @State var textWidth: CGFloat = 0
    
    init(deleteAction: @escaping () -> Void, showDivider: Bool = false, @ViewBuilder content: () -> Content) {
        self.deleteAction = deleteAction
        self.showDivider = showDivider
        self.content = content()
    }
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(lineWidth: 2)
                .foregroundStyle(.primary)
                .frame(width: textWidth, height: filterItemHeight)
            HStack {
                content
                if showDivider {
                    Divider()
                }
                Button(action: {
                    deleteAction()
                }, label: {
                    Image(systemName: "xmark")
                        .font(showDivider ? .body : .caption)
                })
            }
            .foregroundStyle(.primary)
            .frame(height: filterItemHeight)
            .padding(.horizontal, isMACOS ? 10 : nil)
            .onFrameChange(perform: { geometry in
                textWidth = geometry.size.width
            })
        }
    }
}


class CodableStorage {
    static func save<T: Codable>(
        _ value: T,
        forKey key: String
    ) throws {
        let data = try JSONEncoder().encode(value)
        UserDefaults.standard.set(data, forKey: key)
    }
    
    static func load<T: Codable>(
        _ type: T.Type,
        forKey key: String
    ) throws -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else {
            return nil
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
