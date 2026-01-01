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
    @Environment(\.horizontalSizeClass) var sizeClass
    
    @State var allGameplays: [DoriAPI.Station.Room] = []
    @State var displayingGameplays: [CombinedRoom] = []
    @State var informationIsAvailable = true
    @State var informationIsLoading = true
    
    @State var fetchingTask: Task<(), Never>? = nil
    @State var fetchError: Error? = nil
    
    @State var filter: StationFilter = .init()
    @State var filterIsDisplaying = false
    
    @State var newGameplaySheetIsDisplaying = false
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
                                StationItemView(item: item, filter: $filter)
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
            filter = (try? CodableStorage.load(StationFilter.self, forKey: "StationFilter")) ?? .init()
            startConnection()
        }
        .onDisappear {
            fetchingTask?.cancel()
        }
        .onChange(of: filter) {
            displayingGameplays = allGameplays.reversed().filter(withFilter: filter).combiningReferenceRepeatingItems()
            try? CodableStorage.save(filter, forKey: "StationFilter")
        }
        .toolbar {
            ToolbarItem {
                Button(action: {
                    filterIsDisplaying.toggle()
                }, label: {
                    Label("Station.filter", systemImage: "line.3.horizontal.decrease")
                })
            }
            
            if #available(iOS 26.0, macOS 26.0, *) {
                ToolbarSpacer()
            }
            
            ToolbarItem {
                Button(action: {
                    newGameplaySheetIsDisplaying = true
                }, label: {
                    Label("Station.new", systemImage: "plus")
                })
            }
        }
        .sheet(isPresented: $newGameplaySheetIsDisplaying, content: {
            StationAddView()
        })
        .wrapIf(sizeClass == .regular) { content in
            content
                .inspector(isPresented: $filterIsDisplaying) {
                    StationFilterView(filter: $filter)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                        .presentationBackgroundInteraction(.enabled)
                }
        } else: { content in
            content
                .sheet(isPresented: $filterIsDisplaying) {
                    StationFilterView(filter: $filter)
                        .presentationDetents([.medium, .large])
                        .presentationDragIndicator(.visible)
                        .presentationBackgroundInteraction(.enabled)
                }
        }
    }
    
    func startConnection() {
        informationIsAvailable = true
        fetchingTask = Task {
            do {
                try await DoriAPI.Station.receiveRooms { newRooms in
                    informationIsLoading = false
                    allGameplays += newRooms
                    displayingGameplays = allGameplays.reversed().filter(withFilter: filter).combiningReferenceRepeatingItems()
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
    @Binding var filter: StationFilter
    @State var itemTipStatus = 0
    @State var reporingSheetIsDisplaying = false
    @State var reporingUnavailableSheetIsDisplaying = false
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
                                if item.room.type != .daredemo {
                                    Text(item.room.type.localizedName)
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
                                    if (try? AccountManager.bandoriStation.load().first) != nil  {
                                        reasonOfReport = ""
                                        reporingSheetIsDisplaying = true
                                    } else {
                                        reporingUnavailableSheetIsDisplaying = true
                                    }
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
            TextField("Station.item.report.alert.reason", text: $reasonOfReport, axis: .vertical)
            Button(optionalRole: .destructive, action: {
                Task {
                    let account = try? AccountManager.bandoriStation.load().first
                    if let account {
                        let token = try? account.readToken()
                        if let token {
                            try? await DoriAPI.Station.reportRoom(item.room, reason: reasonOfReport, userToken: .init(token))
                        }
                    }
                }
                itemTipStatus = 2
            }, label: {
                Text("Station.item.report.alert.confirm")
            })
            .disabled(reasonOfReport.isEmpty)
        }, message: {
            Text("Station.item.report.alert.message")
        })
        .alert("Station.item.report.unavailable", isPresented: $reporingUnavailableSheetIsDisplaying, actions: {}, message: {
            Text("Station.item.report.unavailable.message")
        })
        .alert("Station.item.block.alert.title.\(item.room.creator.username ?? "nil")", isPresented: $blockingSheetIsDisplaying, actions: {
            Button(optionalRole: .destructive, action: {
                filter.disallowedUsers.append(.init(id: item.room.creator.id, name: item.room.creator.username ?? String(item.room.creator.id)))
                itemTipStatus = 3
            }, label: {
                Text("Station.item.block.alert.confirm")
            })
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

extension DoriAPI.Station.RoomType {
    var localizedName: LocalizedStringResource {
        switch self {
        case .standard:
            return "Station.item.type.7"
        case .master:
            return "Station.item.type.12"
        case .grand:
            return "Station.item.type.18"
        case .legend:
            return "Station.item.type.25"
        default:
            return "Station.item.type.other"
        }
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
    func filter(withFilter filter: StationFilter) -> Self {
        var result = self
        result = self
            .filter({ filter.roomTypes.contains($0.type) })
            .filter({ room in !filter.disallowedKeywords.contains(where: { keyword in room.description.contains(keyword) }) })
            .filter({ room in !filter.disallowedUsers.map({ $0.id }).contains(where: { id in room.creator.id == id }) })
        return result
    }
    
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
