//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventDetailStageView.swift
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

struct EventDetailStageView: View {
    var information: ExtendedEvent
    @State private var stages: [_DoriAPI.Events.FestivalStage]?
    var body: some View {
        if information.event.eventType == .festival {
            LazyVStack(pinnedViews: .sectionHeaders) {
                Section {
                    CustomGroupBox {
                        VStack {
                            if let stages {
                                ForEach(stages.map { IdentifiableStage(stage: $0) }) { stage in
                                    ListItem {
                                        Text(stage.stage.type.localizedString)
                                    } value: {
                                        MultilingualTextForCountdown(
                                            startDate: .init(_jp: stage.stage.startAt, en: nil, tw: nil, cn: nil, kr: nil),
                                            endDate: .init(_jp: stage.stage.endAt, en: nil, tw: nil, cn: nil, kr: nil)
                                        )
                                    }
                                }
                                .insert {
                                    Divider()
                                }
                            } else {
                                HStack {
                                    Spacer()
                                    ProgressView()
                                        .controlSize(.large)
                                    Spacer()
                                }
                            }
                        }
                    }
                    .frame(maxWidth: infoContentMaxWidth)
                } header: {
                    HStack {
                        Text("Event.teams")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    .frame(maxWidth: 615)
                }
            }
            .task {
                withDoriCache(id: "EventFestivalStages_\(information.event.id)") {
                    await _DoriAPI.Events.festivalStages(of: information.event.id)
                }.onUpdate {
                    stages = $0
                }
            }
        }
    }
}

private struct IdentifiableStage: Identifiable {
    var id: UUID = .init()
    var stage: _DoriAPI.Events.FestivalStage
}
