//===---*- Greatdori! -*---------------------------------------------------===//
//
// InfoView.swift
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

import SwiftUI


@MainActor let allInfoDestinationItems: [InfoDestinationItem] = [
    InfoDestinationItem(
        title: "App.info.characters",
        shortenedTitle: "App.info.characters.abbr",
        symbol: "person.2",
        lightColor: .mint,
        tabValue: .characters,
        destination: {CharacterSearchView()}
    ),
    InfoDestinationItem(
        title: "App.info.cards",
        symbol: "person.crop.square.on.square.angled",
        lightColor: .orange,
        tabValue: .cards,
        destination: {CardSearchView()}
    ),
    InfoDestinationItem(
        title: "App.info.costumes",
        symbol: "swatchpalette",
        lightColor: .blue,
        tabValue: .costumes,
        destination: {CostumeSearchView()}
    ),
    InfoDestinationItem(
        title: "App.info.events",
        symbol: "star.hexagon",
        lightColor: .green,
        tabValue: .events,
        destination: {EventSearchView()}
    ),
    InfoDestinationItem(
        title: "App.info.gachas",
        symbol: "dice",
        lightColor: .yellow,
        tabValue: .gacha,
        destination: {GachaSearchView()}
    ),
    InfoDestinationItem(
        title: "App.info.songs",
        symbol: "music.note",
        lightColor: .red,
        tabValue: .songs,
        destination: {SongSearchView()}
    ),
    InfoDestinationItem(
        title: "App.info.song-meta",
        symbol: "music.note.list",
        lightColor: .pink,
        tabValue: .songMeta,
        destination: {EmptyView()}
    ),
    InfoDestinationItem(
        title: "App.info.login-campaign",
        shortenedTitle: "App.info.login-campaign.abbr",
        symbol: "calendar",
        lightColor: .cyan,
        tabValue: .songMeta,
        destination: {LoginCampaignSearchView()}
    ),
    InfoDestinationItem(
        title: "App.info.miracle-ticket",
        symbol: "ticket",
        lightColor: .indigo,
        tabValue: .miracleTicket,
        destination: {MiracleTicketView()}
    ),
    InfoDestinationItem(
        title: "App.info.comics",
        symbol: "book",
        lightColor: .brown,
        tabValue: .comics,
        destination: {ComicSearchView()}
    ),
]

@MainActor let allToolsDestinationItems: [ToolDestinationItem] = [
    ToolDestinationItem(
        title: "App.tools.event-tracker",
        symbol: "chart.line.uptrend.xyaxis",
        tabValue: .eventTracker,
        destination: {EventTrackerView()}
    ),
    ToolDestinationItem(
        title: "App.tools.station",
        symbol: "flag.2.crossed",
        tabValue: .station,
        destination: {StationView()}
    ),
    ToolDestinationItem(
        title: "App.tools.chart-simulator",
        symbol: "apple.classical.pages",
        tabValue: .chartSimulator,
        destination: {ChartSimulatorView()}
    ),
    ToolDestinationItem(
        title: "App.tools.story-viewer",
        symbol: "books.vertical",
        tabValue: .storyViewer,
        destination: {StoryViewerView()}
    ),
    ToolDestinationItem(
        title: "App.tools.live2d-viewer",
        symbol: "person.and.viewfinder",
        tabValue: .live2dViewer,
        destination: {Live2DViewerView()}
    ),
    ToolDestinationItem(
        title: "App.tools.asset-explorer",
        symbol: "folder",
        tabValue: .assetExplorer,
        destination: {AssetExplorerView()}
    ),
    ToolDestinationItem(
        title: "App.tools.zeile-editor",
        symbol: "hammer",
        tabValue: .zeileEditor,
        destination: {ZeileWelcomeView()}
    )
]


struct InfoDestinationItem {
    let title: LocalizedStringKey
    let shortenedTitle: LocalizedStringKey?
    let symbol: String
    let lightColor: Color
    let darkColor: Color?
    let tabValue: InfoTab
    let destination: () -> AnyView
    let note: String
    
    init<T: View>(title: LocalizedStringKey, shortenedTitle: LocalizedStringKey? = nil, symbol: String, lightColor: Color, darkColor: Color? = nil, tabValue: InfoTab, @ViewBuilder destination: @escaping () -> T, note: String = "") {
        self.title = title
        self.shortenedTitle = shortenedTitle
        self.symbol = symbol
        self.lightColor = lightColor
        self.darkColor = darkColor
        self.tabValue = tabValue
        self.destination = { AnyView(destination()) }
        self.note = note
    }
}

struct InfoView: View {
    @Environment(\.colorScheme) var colorScheme
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(), count: 2)) {
                    ForEach(0..<allInfoDestinationItems.count, id: \.self) { itemIndex in
                        NavigationLink(destination: {
                            allInfoDestinationItems[itemIndex].destination()
                        }, label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .foregroundStyle(Color((colorScheme == .dark && allInfoDestinationItems[itemIndex].darkColor != nil) ? (allInfoDestinationItems[itemIndex].darkColor!) : (allInfoDestinationItems[itemIndex].lightColor)).gradient)
                                //                    .foregroundStyle(
                                //                        LinearGradient(
                                //                            colors: [color, color.saturation(factor: 0.9).brightness(factor: 2.2)],
                                //                            startPoint: .leading,
                                //                            endPoint: .trailing
                                //                        )
                                //                    )
                                HStack {
                                    VStack(alignment: .leading) {
                                        Image(fallingSystemName: allInfoDestinationItems[itemIndex].symbol)
                                            .font(.largeTitle)
                                        Spacer()
                                        ViewThatFits {
                                            Text(allInfoDestinationItems[itemIndex].title)
                                                .font(.title3)
                                                .bold()
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(1)
                                                .allowsTightening(true)
                                            if let shortenedTitle = allInfoDestinationItems[itemIndex].shortenedTitle {
                                                Text(shortenedTitle)
                                                    .font(.title3)
                                                    .bold()
                                                    .multilineTextAlignment(.leading)
                                                    .lineLimit(1)
                                                    .allowsTightening(true)
                                            }
                                        }
                                    }
                                    .foregroundStyle(.white)
                                    Spacer()
                                }
                                .padding()
                            }
                        })
                    }
                }
                .padding()
            }
            .navigationTitle("App.info")
            .handlesExternalView()
        }
    }
}


struct ToolDestinationItem {
    let title: LocalizedStringKey
//    let shortenedTitle: LocalizedStringKey?
    let symbol: String
//    let lightColor: Color
//    let darkColor: Color?
    let tabValue: ToolTab
    let destination: () -> AnyView
    
    init<T: View>(title: LocalizedStringKey, symbol: String, tabValue: ToolTab, @ViewBuilder destination: @escaping () -> T) {
        self.title = title
        self.symbol = symbol
        self.tabValue = tabValue
        self.destination = { AnyView(destination()) }
    }
}

struct ToolsView: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<allToolsDestinationItems.count, id: \.self) { itemIndex in
                    NavigationLink(destination: {
                        allToolsDestinationItems[itemIndex].destination()
                    }, label: {
                        Label(title: {
                            Text(allToolsDestinationItems[itemIndex].title)
                        }, icon: {
                            Image(fallingSystemName: allToolsDestinationItems[itemIndex].symbol)
                        })
                    })
                }
            }
            .navigationTitle("App.tools")
            .handlesExternalView()
        }
    }
}
