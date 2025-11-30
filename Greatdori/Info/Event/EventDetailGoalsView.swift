//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventDetailGoalsView.swift
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

// MARK: EventDetailGoalsView
struct EventDetailGoalsView: View {
    var information: ExtendedEvent
    var body: some View {
        if let missions = information.event.liveTryMissions,
           let missionDetails = information.event.liveTryMissionDetails,
           let missionTypeSeqs = information.event.liveTryMissionTypeSequences {
            LazyVStack(pinnedViews: .sectionHeaders) {
                Section {
                    VStack {
                        let typedMissions = missions.reduce(into: [Event.LiveTryMissionType: [Event.LiveTryMission]]()) {
                            $0.updateValue(($0[$1.value.missionType] ?? []) + [$1.value], forKey: $1.value.missionType)
                        }.mapValues {
                            $0.sorted {
                                ($0.missionDifficultyType == $1.missionDifficultyType
                                 && $0.level < $1.level)
                                || $0.missionDifficultyType.rawValue > $1.missionDifficultyType.rawValue
                            }
                        }
                        ForEach(typedMissions.sorted {
                            (missionTypeSeqs[$0.key] ?? 0)
                            < (missionTypeSeqs[$1.key] ?? 0)
                        }, id: \.key) { type, missions in
                            SingleTypeGoalsView(
                                type: type,
                                missions: missions,
                                missionDetails: missionDetails
                            )
                        }
                    }
                    .frame(maxWidth: infoContentMaxWidth)
                } header: {
                    HStack {
                        Text("Event.goals")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    .frame(maxWidth: 615)
                }
            }
        }
    }
    
    private struct SingleTypeGoalsView: View {
        var type: Event.LiveTryMissionType
        var missions: [Event.LiveTryMission]
        var missionDetails: [Int: Event.LiveTryMissionDetail]
        @State private var isExpanded = false
        var body: some View {
            CustomGroupBox {
                VStack {
                    HStack {
                        Text(type.localizedString)
                            .bold()
                        Spacer()
                        Image(systemName: "chevron.forward")
                            .foregroundStyle(.secondary)
                            .rotationEffect(.init(degrees: isExpanded ? 90 : 0))
                            .font(isMACOS ? .body : .caption)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation {
                            isExpanded.toggle()
                        }
                    }
                    
                    if isExpanded {
                        ForEach(Array(missions.enumerated()), id: \.element.missionID) { index, mission in
                            if let detail = missionDetails[mission.missionID] {
                                Divider()
                                ListItem {
                                    Text("Event.goals.level.\(mission.level).\(mission.missionDifficultyType == .extra ? " EX" : "")")
                                } value: {
                                    MultilingualText(detail.description.map({ $0?.replacing(#/\[[0-9A-Fa-f]{3,6}\]|\[-\]/#, with: "") }))
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
