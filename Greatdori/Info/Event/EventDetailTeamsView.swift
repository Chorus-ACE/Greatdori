//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventDetailTeamsView.swift
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

// MARK: EventDetailTeamsView
struct EventDetailTeamsView: View {
    var information: ExtendedEvent
    var body: some View {
        if let teams = information.event.teamList, teams.count >= 2 {
            Section {
                CustomGroupBox {
                    HStack {
                        Spacer()
                        VStack {
                            Text(teams[0].themeTitle)
                                .font(.title3)
                                .bold()
                                .multilineTextAlignment(.center)
                            HStack {
                                VStack {
                                    WebImage(url: teams[0].iconImageURL(with: information.event))
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                    Text(teams[0].teamName)
                                }
                                Text(verbatim: "vs")
                                    .padding(.horizontal, 20)
                                VStack {
                                    WebImage(url: teams[1].iconImageURL(with: information.event))
                                        .resizable()
                                        .scaledToFit()
                                        .frame(height: 100)
                                    Text(teams[1].teamName)
                                }
                            }
                        }
                        Spacer()
                    }
                }
                .textSelection(.enabled)
                .frame(maxWidth: infoContentMaxWidth)
            } header: {
                HStack {
                    Text("Event.teams")
                        .font(.title2)
                        .bold()
                    Spacer()
                }
                .frame(maxWidth: 615)
                .detailSectionHeader()
            }
        }
    }
}

