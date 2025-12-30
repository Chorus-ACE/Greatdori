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
import DoriKit
import SDWebImageSwiftUI
import SwiftyJSON
import SwiftUI

struct StationView: View {
    @State var allGameplays: [DoriAPI.Station.Room] = []
    @State var displayingGameplays: [CombinedRoom] = []
    @State var informationIsAvailable = true
    @State var informationIsLoading = true
    
    @State var fetchingTask: Task<(), Never>? = nil
    @State var fetchError: Error? = nil
    var body: some View {
        Group {
            if informationIsAvailable {
                if informationIsLoading {
                    ExtendedConstraints {
                        ProgressView()
                    }
                } else if !displayingGameplays.isEmpty {
                    CustomScrollView {
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
                } else {
                    ExtendedConstraints {
                        ContentUnavailableView("Station.empty", systemImage: "flag.2.crossed", description: Text("Station.empty.description"))
                    }
                }
            } else {
                ExtendedConstraints {
                    ContentUnavailableView("Station.unavailable", systemImage: "flag.2.crossed", description: Text("Station.unavailable.description.\(String(describing: fetchError))"))
                }
                .onTapGesture {
                    startConnection()
                }
            }
        }
        .navigationTitle("Station")
        .withSystemBackground()
        .onAppear {
            startConnection()
        }
        .onDisappear {
            fetchingTask?.cancel()
        }
    }
    
    func startConnection() {
        informationIsAvailable = true
        fetchingTask = Task {
            do {
                try await DoriAPI.Station.receiveRooms { newRooms in
                    informationIsLoading = false
                    allGameplays += newRooms
                    displayingGameplays = allGameplays.reversed().combiningReferenceRepeatingItems()
                }
            } catch {
                informationIsAvailable = false
                fetchError = error
            }
        }
    }
}

struct StationItemView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var item: CombinedRoom
    @State var itemTipStatus = 0
    @State var reporingSheetIsDisplaying = false
    @State var blockingSheetIsDisplaying = false
    @State var reasonOfReport = ""
    var body: some View {
        Button(action: {
            copyStringToClipboard(String(item.room.number))
            itemTipStatus = 1
        }, label: {
            CustomGroupBox(cornerRadius: 20) {
                HStack {
                    WebImage(url: item.room.creator.avatarURL(), content: { image in
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
                        if let username = item.room.creator.username {
                            HStack {
                                Text(username)
                                    .bold()
                                if let bandPower = item.room.creator.gameProfile?.bandPower, bandPower > 0 {
                                    Text("Station.item.band-power.\(bandPower)")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        HStack {
                            Text(item.room.number)
                                .bold()
                            Group {
                                switch item.room.type {
                                case .standard:
                                    Text("Station.item.type.7")
                                case .master:
                                    Text("Station.item.type.12")
                                case .grand:
                                    Text("Station.item.type.18")
                                case .legend:
                                    Text("Station.item.type.25")
                                default:
                                    EmptyView()
                                }
                            }
                            .foregroundStyle(.secondary)
                        }
                        Text(item.room.description)
                            .font(isMACOS ? .body : .caption)
                        if let mainDeck = item.room.creator.gameProfile?.mainDeck {
                            HStack(spacing: 5) {
                                ForEach(mainDeck.sortAsStandardBand(), id: \.self) { item in
                                    CardPreviewViewWithPlaceholder(id: item.id, isTrained: item.trained)
                                }
                            }
                        }
                    }
                    .textSelection(.enabled)
                    Spacer(minLength: 0)
                    VStack(alignment: .trailing) {
                        HStack {
                            if sizeClass == .regular {
                                switch item.room.source {
                                case .qq(let name):
                                    Text(name)
                                case .website(let name):
                                    Text(name)
                                default:
                                    EmptyView()
                                }
                            }
                            Text(item.room.dateCreated, style: .relative)
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
                                    copyStringToClipboard(String(item.room.number))
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
        .alert("Station.item.report.alert.title.\(item.room.creator.username ?? "nil")", isPresented: $reporingSheetIsDisplaying, actions: {
            TextField("Station.item.report.alert.reason", text: $reasonOfReport)
            Button(optionalRole: .destructive, action: {
                itemTipStatus = 2
            }, label: {
                Text("Station.item.report.alert.confirm")
            })
            //            .keyboardShortcut(.defaultAction)
        }, message: {
            Text("Station.item.report.alert.message")
        })
        .alert("Station.item.block.alert.title.\(item.room.creator.username ?? "nil")", isPresented: $blockingSheetIsDisplaying, actions: {
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
    
    struct CardPreviewViewWithPlaceholder: View {
        var id: Int
        var isTrained: Bool
        var sideLength: CGFloat = 40
        
        @State var card: Card? = nil
        var body: some View {
            if let card {
                CardPreviewImage(card, showTrainedVersion: isTrained, sideLength: sideLength)
            } else {
                RoundedRectangle(cornerRadius: 2)
                    .fill(getPlaceholderColor())
                    .frame(width: sideLength, height: sideLength)
                    .onAppear {
                        Task {
                            card = await Card(id: id)
                        }
                    }
            }
        }
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

extension DoriAPI.Station.Room {
    func isSameReference(as rhs: DoriAPI.Station.Room) -> Bool {
        return self.number == rhs.number &&
        self.type == rhs.type &&
        self.creator == rhs.creator
        // Same room, same type and same user counts as "referring to the same gameplay".
    }
    
    var description: String {
        var result = self.message
        if result.hasPrefix(String(self.number)) {
            result.removeFirst(self.number.count)
        }
        if result.hasPrefix(" ") {
            result.removeFirst()
        }
        return result
    }
}

extension DoriAPI.Station.UserInformation {
    func avatarURL(isQQ: Bool? = nil) -> URL {
        // Use prefix check instead of type check is to avoid Tsugu and other active user from losing their avatar pic
        let condition = isQQ ?? self.username?.hasPrefix("QQ用户") ?? false
        if condition {
            return URL(string: "https://q1.qlogo.cn/g?b=qq&nk=\(id)&s=640")!
        } else {
            return URL(string: "https://asset.bandoristation.com/images/user-avatar/\(self._avatarFileName)")!
        }
    }
}

extension Array<DoriAPI.Station.Room> {
    func combiningReferenceRepeatingItems() -> Array<CombinedRoom> {
        var result: [CombinedRoom] = []
        for item in self {
            if let firstIndex = result.firstIndex(where: { $0.room.isSameReference(as: item) }) {
                result[firstIndex].quantity += 1
            } else {
                result.append(CombinedRoom(item))
            }
        }
        return result
    }
}

extension Array {
    func sortAsStandardBand() -> Array {
        guard self.count == 5 else { return self }
        var mutableSelf = self
        mutableSelf.swapAt(0, 2)
        mutableSelf.swapAt(0, 3)
        return mutableSelf
    }
}

extension String: @retroactive Error {}
extension Int: @retroactive Error {}

struct CombinedRoom: Hashable, Sendable {
    var room: DoriAPI.Station.Room
    var quantity: Int = 1
    
    init(_ room: DoriAPI.Station.Room, quantity: Int = 1) {
        self.room = room
        self.quantity = quantity
    }
}
