//===---*- Greatdori! -*---------------------------------------------------===//
//
// Station.swift
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

import Alamofire
import Combine
import SDWebImageSwiftUI
import SwiftyJSON
import SwiftUI

struct StationView: View {
    @State var allGamplays: [StationGameplay] = []
    @State var displayingGameplays: [StationGameplay] = []
    @State var informationIsAvailable = true
    @State var informationIsLoading = true
    @State var fetchError: Int? = nil

    var body: some View {
        Group {
            if informationIsAvailable {
                if informationIsLoading {
                    ExtendedConstraints {
                        ProgressView()
                    }
                } else if !displayingGameplays.isEmpty {
                    ScrollView {
                        HStack {
                            Spacer(minLength: 0)
                            VStack {
                                Section(content: {
                                    ForEach(displayingGameplays, id: \.self) { item in
                                        StationItemView(item: item)
                                    }
                                    .animation(.easeInOut(duration: 0.5), value: displayingGameplays)
                                }, footer: {
                                    HStack {
                                        Text("Station.footer")
                                            .foregroundStyle(.secondary)
                                            .font(.footnote)
                                        Spacer()
                                    }
                                })
                                .frame(maxWidth: infoContentMaxWidth)
                            }
                            .padding(.vertical)
                            Spacer(minLength: 0)
                        }
                    }
                } else {
                    ExtendedConstraints {
                        ContentUnavailableView("Station.empty", systemImage: "flag.2.crossed", description: Text("Station.empty.description"))
                    }
                }
            } else {
                ExtendedConstraints {
                    ContentUnavailableView("Station.unavailable", systemImage: "flag.2.crossed", description: Text("Station.unavailable.description.\(fetchError ?? -1)"))
                }
                .onTapGesture {
                    Task {
                        await refreshGameplayInforation()
                    }
                }
            }
        }
        .navigationTitle("Station")
        .withSystemBackground()
        .onAppear {
            Task {
                await refreshGameplayInforation()
            }
        }
    }
    
    func refreshGameplayInforation() async {
        informationIsAvailable = true
        // TODO: !!!!!!!!
//        let task = Task {
//            do {
//                try await _DoriAPI.Station.receiveRooms { newRooms in
//                    roomArray.append(contentsOf: newRooms)
//                }
//                print("Finished!")
//            } catch {
//                let 
//            }
//        }
        informationIsLoading = false
    }
}

struct StationItemView: View {
    var item: StationGameplay
    @State var itemTipStatus = 0
    @State var reporingSheetIsDisplaying = false
    @State var blockingSheetIsDisplaying = false
    @State var reasonOfReport = ""
    var body: some View {
        Button(action: {
            copyStringToClipboard(String(item.roomNumber))
            itemTipStatus = 1
        }, label: {
            CustomGroupBox(cornerRadius: 20) {
                HStack {
                    WebImage(url: item.userInfo?.avatarLink(), content: { image in
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
                    .iconBadge(item.quantity, ignoreOne: true)
                    VStack(alignment: .leading) {
                        if let username = item.userInfo?.username {
                            HStack {
                                Text(username)
                                    .bold()
                                if let bandPower = item.userInfo?.bandPower, bandPower > 0 {
                                    Text("Station.item.band-power.\(bandPower)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        HStack {
                            Text(item.roomNumber)
                                .bold()
                            Group {
                                switch item.roomType {
                                case "7":
                                    Text("Station.item.type.7")
                                case "12":
                                    Text("Station.item.type.12")
                                case "18":
                                    Text("Station.item.type.18")
                                case "25":
                                    Text("Station.item.type.25")
                                default:
                                    EmptyView()
                                }
                            }
                            .foregroundStyle(.secondary)
                        }
                        Text(item.description)
                    }
                    .textSelection(.enabled)
                    Spacer()
                    VStack(alignment: .trailing) {
                        HStack {
                            if let source = item.sourceInfo {
                                Text(source.name)
                            }
                            Text(Date(timeIntervalSince1970: Double(item.timestamp)/1000), style: .relative)
                        }
                        .foregroundStyle(.secondary)
                        .font(.caption)
                        Spacer(minLength: 0)
                        ZStack(alignment: .trailing, content: {
                            Label("Station.item.block.success", systemImage: "nosign")
                                .foregroundStyle(.red)
                                .opacity(itemTipStatus == 3 ? 1 : 0)
                            Label("Station.item.report.success", systemImage: "flag")
                                .foregroundStyle(.red)
                                .opacity(itemTipStatus == 2 ? 1 : 0)
                            Label("Station.item.copy.success", systemImage: "checkmark.circle")
                                .foregroundStyle(.green)
                                .opacity(itemTipStatus == 1 ? 1 : 0)
                            HStack {
                                Button(action: {
                                    blockingSheetIsDisplaying = true
                                }, label: {
                                    Label("Station.item.block", systemImage: "nosign")
                                        .foregroundStyle(.secondary)
                                        .labelStyle(.iconOnly)
                                })
                                Button(action: {
                                    reasonOfReport = ""
                                    reporingSheetIsDisplaying = true
                                }, label: {
                                    Label("Station.item.report", systemImage: "flag")
                                        .foregroundStyle(.secondary)
                                        .labelStyle(.iconOnly)
                                })
                                Button(action: {
                                    copyStringToClipboard(String(item.roomNumber))
                                    itemTipStatus = 1
                                }, label: {
                                    Label("Station.item.copy", systemImage: "document.on.document")
                                        .labelStyle(.iconOnly)
                                })
                            }
                            .buttonStyle(.plain)
                            .opacity(itemTipStatus == 0 ? 1 : 0)
                        })
                        .animation(.easeIn(duration: 0.2), value: itemTipStatus)
                        .onChange(of: itemTipStatus, {
                            if itemTipStatus != 0 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    itemTipStatus = 0
                                }
                            }
                        })
                    }
                }
            }
        })
        .buttonStyle(.plain)
        .alert("Station.item.report.alert.title.\(item.userInfo?.username ?? "nil")", isPresented: $reporingSheetIsDisplaying, actions: {
            TextField("Station.item.report.alert.reason", text: $reasonOfReport)
            Button(role: .cancel, action: {}, label: {
                Text("Station.item.report.alert.cancel")
            })
            Button(optionalRole: .destructive, action: {
                itemTipStatus = 2
            }, label: {
                Text("Station.item.report.alert.confirm")
            })
//            .keyboardShortcut(.defaultAction)
        }, message: {
            Text("Station.item.report.alert.message")
        })
        .alert("Station.item.block.alert.title.\(item.userInfo?.username ?? "nil")", isPresented: $blockingSheetIsDisplaying, actions: {
            Button(role: .cancel, action: {}, label: {
                Text("Station.item.block.alert.cancel")
            })
            Button(optionalRole: .destructive, action: {
                itemTipStatus = 3
            }, label: {
                Text("Station.item.block.alert.confirm")
            })
//            .keyboardShortcut(.defaultAction)
        }, message: {
            Text("Station.item.block.alert.message")
        })
    }
}

func getAllAvailableGameplays() async -> Result<[StationGameplay], Int> {
    do {
        let data = try await fetchData(from: "https://api.bandoristation.com/?function=query_room_number")
        let json = try JSON(data: data)
        
        if json["status"].string == "success" {
            if let gameplays = json["response"].array {
                var finalGameplays: [StationGameplay] = []
                for gameplay in gameplays {
                    if let roomNumber = gameplay["number"].string, let description = gameplay["raw_message"].string, let roomType = gameplay["type"].string, let timestamp = gameplay["time"].int {
                        
                        var shorterDesc = description
                        
                        if description.hasPrefix(String(roomNumber)) {
                            shorterDesc.removeFirst(roomNumber.count)
                        }
                        if shorterDesc.hasPrefix(" ") {
                            shorterDesc.removeFirst()
                        }
                        
                        var userInfo: StationGameplay.StationUser? = nil
                        let jsonUserInfo = gameplay["user_info"]
                        if let userType = jsonUserInfo["type"].string, let userID = jsonUserInfo["user_id"].int, let userName = jsonUserInfo["username"].string, let userAvatar = jsonUserInfo["avatar"].string {
                            userInfo = StationGameplay.StationUser(type: userType, avatar: userAvatar, username: userName, id: userID, bandPower: jsonUserInfo["bandori_player_brief_info"]["band_power"].int)
                        }
                        
                        var sourceInfo: StationGameplay.SourceInfo? = nil
                        let jsonSourceInfo = gameplay["source_info"]
                        if let sourceName = jsonSourceInfo["name"].string, let sourceType = jsonSourceInfo["type"].string {
                            sourceInfo = StationGameplay.SourceInfo(name: sourceName, type: sourceType)
                        }
                        finalGameplays.append(StationGameplay(roomNumber: roomNumber, description: shorterDesc, roomType: roomType, timestamp: timestamp, userInfo: userInfo, sourceInfo: sourceInfo))
                    }
                }
                let historyGameplays = HistoryGameplayHolder.shared.historyGameplays
                HistoryGameplayHolder.shared.historyGameplays = finalGameplays
                return .success(finalGameplays.merge(with: historyGameplays).combiningReferenceRepeatingItems())
            } else {
                return .failure(502)
            }
        } else {
            return .failure(501)
        }
    } catch {
        return .failure(400)
    }
}

func fetchData(from url: String) async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
        AF.request(url).response { response in
            switch response.result {
            case .success(let data):
                if let data = data {
                    continuation.resume(returning: data)
                } else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                }
            case .failure(let error):
                continuation.resume(throwing: error)
            }
        }
    }
}

struct StationGameplay: Hashable, Equatable {
    var roomNumber: String
    var description: String
    var roomType: String
    var timestamp: Int
    var userInfo: StationUser?
    var sourceInfo: SourceInfo?
    var quantity: Int = 1 // This number goes up if repeating items are found.
    
    struct StationUser: Hashable, Equatable {
        var type: String
        var avatar: String
        var username: String
        var id: Int
        var bandPower: Int?
        
        func avatarLink(isQQ: Bool? = nil) -> URL {
            // Use prefix check instead of type check is to avoid Tsugu and other active user from losing their avatar pic
            let condition = isQQ ?? username.hasPrefix("QQ用户")
            if condition {
                return URL(string: "https://q1.qlogo.cn/g?b=qq&nk=\(id)&s=640")!
            } else {
                return URL(string: "https://asset.bandoristation.com/images/user-avatar/\(avatar)")!
            }
        }
    }
    
    struct SourceInfo: Hashable, Equatable {
        var name: String
        var type: String
    }
    
    func isSameReference(as rhs: StationGameplay) -> Bool {
        return self.roomNumber == rhs.roomNumber &&
        self.roomType == rhs.roomType &&
        self.userInfo == rhs.userInfo
        // Same room, same type and same user counts as "referring to the same gameplay".
    }
    
    func dropQuantity() -> Self {
        var mutableSelf = self
        mutableSelf.quantity = 0
        return mutableSelf
    }
}

extension Array<StationGameplay> {
    func merge(with history: [StationGameplay]) -> Self {
        var result = self
        for play in history {
            if !result.contains(play) {
                result.append(play)
            }
        }
        return result.sorted(by: { $0.timestamp > $1.timestamp })
    }
    
    // Must have order new to old, or else older items overtakes representing data.
    func combiningReferenceRepeatingItems() -> Self {
        var result: [StationGameplay] = []
        for item in self {
            if result.contains(where: { $0.isSameReference(as: item) }) {
                result[result.firstIndex(where: { $0.isSameReference(as: item) })!].quantity += 1
            } else {
                result.append(item)
            }
        }
        return result
    }
}

extension String: @retroactive Error {}
extension Int: @retroactive Error {}

class HistoryGameplayHolder: @unchecked Sendable {
    static let shared = HistoryGameplayHolder()
    
    var historyGameplays: [StationGameplay] = []
}
