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
import SwiftyJSON
import SwiftUI

struct StationView: View {
    @State var allAvailableGamplays: [StationGameplay] = []
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
                } else if !allAvailableGamplays.isEmpty {
                    ScrollView {
                        HStack {
                            Spacer(minLength: 0)
                            VStack {
                                Section {
                                    ForEach(allAvailableGamplays, id: \.self) { item in
                                        CustomGroupBox {
                                            Text(item.roomNumber)
                                        }
                                    }
                                }
                                .frame(maxWidth: 600)
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
    }
    
    func refreshGameplayInforation() async {
        informationIsLoading = true
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

func getAllAvailableGameplays() async -> Result<[StationGameplay], Int> {
    do {
        let data = try await fetchData(from: "https://api.bandoristation.com/?function=query_room_number")
        let json = try JSON(data: data)
        
        if json["status"].string == "success" {
            if let gameplays = json["response"].array {
                var finalGameplays: [StationGameplay] = []
                for gameplay in gameplays {
                    if let roomNumber = gameplay["number"].string, let description = gameplay["raw_message"].string, let roomType = gameplay["type"].string, let timestamp = gameplay["time"].int {
                        finalGameplays.append(StationGameplay(roomNumber: roomNumber, description: description, roomType: roomType, timestamp: timestamp))
                    }
                }
                return .success(finalGameplays)
//                gameplays[""]
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

struct StationGameplay: Hashable {
    var roomNumber: String
    var description: String
//    var source: String
    var roomType: String
    var timestamp: Int
//    var userInfo: String
}

extension String: @retroactive Error {}
extension Int: @retroactive Error {}
