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
    @State var allAvailableGamplays: [StationGameplay] = []
    @State var informationIsAvailable = true
    @State var informationIsLoading = true
    @State var fetchError: Int? = nil
    
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var body: some View {
        Group {
            if informationIsAvailable {
                if informationIsLoading {
                    ExtendedConstraints {
                        ProgressView()
                    }
                } else if !allAvailableGamplays.isEmpty {
                    ScrollView {
                        HStack {
                            Spacer(minLength: 0)
                            VStack {
                                Section {
                                    ForEach(allAvailableGamplays, id: \.self) { item in
                                        StationItemView(item: item)
                                    }
                                }
                                .frame(maxWidth: infoContentMaxWidth)
                            }
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
        .onReceive(timer) { _ in
            Task {
                await refreshGameplayInforation()
            }
        }
    }
    
    func refreshGameplayInforation() async {
        informationIsAvailable = true
        //        do {
        let availableGameplayResults = await getAllAvailableGameplays()
        switch availableGameplayResults {
        case .success(let data):
            allAvailableGamplays = data
            informationIsAvailable = true
        case .failure(let error):
            fetchError = error
            informationIsAvailable = false
        }
        informationIsLoading = false
    }
}

struct StationItemView: View {
    var item: StationGameplay
    var body: some View {
        CustomGroupBox(cornerRadius: 20) {
            HStack {
                WebImage(url: item.userInfo?.avatarLink, content: { image in
                    image
                        .resizable()
                }, placeholder: {
//                    Circle()
//                        .foregroundStyle(getPlaceholderColor())
                    Image(systemName: "person.crop.circle")
                        .resizable()
                        .foregroundStyle(.secondary)
                })
                .mask {
                    Circle()
                }
                .frame(width: 40, height: 40)
                .iconBadge(item.quantity, ignoreOne: true)
                VStack(alignment: .leading) {
                    if let username = item.userInfo?.username {
                        Text(username)
                            .bold()
                    }
                    Text(item.roomNumber)
                        .bold()
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
                    Spacer()
                }
            }
        }
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
                        
                        var userInfo: StationGameplay.StationUser? = nil
                        let jsonUserInfo = gameplay["user_info"]
                        if let userType = jsonUserInfo["type"].string, let userID = jsonUserInfo["user_id"].int, let userName = jsonUserInfo["username"].string, let userAvatar = jsonUserInfo["avatar"].string {
                            userInfo = StationGameplay.StationUser(type: userType, avatar: userAvatar, username: userName, id: userID)
                        }
                        
                        var sourceInfo: StationGameplay.SourceInfo? = nil
                        let jsonSourceInfo = gameplay["source_info"]
                        if let sourceName = jsonSourceInfo["name"].string, let sourceType = jsonSourceInfo["type"].string {
                            sourceInfo = StationGameplay.SourceInfo(name: sourceName, type: sourceType)
                        }
                        finalGameplays.append(StationGameplay(roomNumber: roomNumber, description: description, roomType: roomType, timestamp: timestamp, userInfo: userInfo, sourceInfo: sourceInfo))
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
        
        var avatarLink: URL? {
            URL(string: "https://asset.bandoristation.com/images/user-avatar/\(avatar)")
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
        var result = self.map { $0.dropQuantity() }
        for play in history.map({ $0.dropQuantity() }) {
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
