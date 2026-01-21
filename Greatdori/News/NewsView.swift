//===---*- Greatdori! -*---------------------------------------------------===//
//
// NewsView.swift
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
import SDWebImageSwiftUI
import SymbolAvailability

//MARK: NewsView
struct NewsView: View {
    let filterLocalizedString: [DoriFrontend.News.ListFilter?: LocalizedStringResource] = [nil: "News.filter.selection.all", .bestdori: "News.filter.selection.bestdori", .article: "News.filter.selection.article", .patchNote: "News.filter.selection.patch-note", .update: "News.filter.selection.update", .locale(.jp): "News.filter.selection.jp", .locale(.en): "News.filter.selection.en", .locale(.tw): "News.filter.selection.tw", .locale(.cn): "News.filter.selection.cn", .locale(.kr): "News.filter.selection.kr"]
    let filterOptions: [DoriFrontend.News.ListFilter?] = [nil, .bestdori, .article, .patchNote, .update, .locale(.jp), .locale(.en), .locale(.tw), .locale(.cn), .locale(.kr)]
    @Environment(\.colorScheme) var colorScheme
    @State var newsList: [DoriFrontend.News.ListItem]?
    @State var filter: DoriFrontend.News.ListFilter? = nil
    @State var allEvents: [PreviewEvent]?
    @State var allGacha: [PreviewGacha]?
    @State var allSongs: [PreviewSong]?
    var dateFormatter = DateFormatter()
    init() {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
    }
    var body: some View {
        Group {
            if let newsList {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        LazyVStack {
                            ForEach(newsList, id: \.self) { newsItem in
                                NavigationLink(destination: {
                                    switch newsItem.type {
                                    case .article:
                                        NewsDetailView(id: newsItem.relatedID, title: newsItem.title)
                                    case .event:
                                        EventDetailView(id: newsItem.relatedID)
                                    case .gacha:
                                        GachaDetailView(id: newsItem.relatedID)
                                    case .loginCampaign:
                                        LoginCampaignDetailView(id: newsItem.relatedID)
                                    case .song:
                                        SongDetailView(id: newsItem.relatedID)
                                    @unknown default:
                                        EmptyView()
                                    }
                                }, label: {
                                    CustomGroupBox {
                                        NewsPreview(allEvents: allEvents, allGacha: allGacha, allSongs: allSongs, news: newsItem, showLocale: {
                                            if case .locale = filter { false } else { true }
                                        }(), showDetails: true, showImages: true)
                                    }
                                })
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                        .frame(maxWidth: infoContentMaxWidth)
                        Spacer(minLength: 0)
                    }
                }
            } else {
                ExtendedConstraints {
                    ProgressView()
                }
            }
        }
        .withSystemBackground()
        .navigationTitle("Home.news")
        #if !os(visionOS)
        .wrapIf(filter != nil && !isMACOS, in: { content in
            if #available(iOS 26.0, *) {
                content
                    .navigationSubtitle(filterLocalizedString[filter]!)
            } else {
                content
            }
        })
        #endif
        .task {
            DoriCache.withCache(id: "News_\(filter)", trait: .realTime) {
                await DoriFrontend.News.list(filter: filter)
            } .onUpdate {
                newsList = $0
            }
            await withTaskGroup { group in
                group.addTask {
                    let events = await Event.all()
                    await MainActor.run {
                        allEvents = events
                    }
                }
                group.addTask {
                    let gacha = await Gacha.all()
                    await MainActor.run {
                        allGacha = gacha
                    }
                }
                group.addTask {
                    let songs = await Song.all()
                    await MainActor.run {
                        allSongs = songs
                    }
                }
            }
        }
        .onChange(of: filter) {
            Task {
                newsList = nil
                withDoriCache(id: "News_\(filter)", trait: .realTime) {
                    await DoriFrontend.News.list(filter: filter)
                } .onUpdate {
                    newsList = $0
                }
            }
        }
        .toolbar {
#if os(iOS)
            ToolbarItem {
                Menu {
                    Picker("", selection: $filter) {
                        ForEach(0..<filterOptions.count, id: \.self) { filterIndex in
                            //                                Button(action: {
                            //                                    filter = filterOptions[filterIndex]
                            //                                }, label: {
                            //                                    HStack {
                            //                                        if filter == filterOptions[filterIndex] {
                            //                                            Image(systemName: "checkmark")
                            //                                        }
                            Text(filterLocalizedString[filterOptions[filterIndex]]!)
                                .tag(filterOptions[filterIndex])
                            //                                    }
                            //                                })
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                } label: {
                    if filter != nil {
                        Image(systemName: .line3HorizontalDecrease)
                            .foregroundStyle(.white)
                            .background {
                                Capsule().foregroundStyle(Color.accentColor).scaledToFill().scaleEffect(1.3)
                            }
                    } else {
                        Image(systemName: .line3HorizontalDecrease)
                    }
                }
            }
#else
            ToolbarItem {
                Picker(selection: $filter, content: {
                    ForEach(0..<filterOptions.count, id: \.self) { filterIndex in
                        //                                Button(action: {
                        //                                    filter = filterOptions[filterIndex]
                        //                                }, label: {
                        //                                    HStack {
                        //                                        if filter == filterOptions[filterIndex] {
                        //                                            Image(systemName: "checkmark")
                        //                                        }
                        Text(filterLocalizedString[filterOptions[filterIndex]]!)
                            .tag(filterOptions[filterIndex])
                        //                                    }
                        //                                })
                    }
                }, label: {
                    if filter != nil {
                        Image(systemName: .line3HorizontalDecrease)
                            .foregroundStyle(colorScheme == .dark ? .white : .black)
                            .background {
                                Capsule().foregroundStyle(Color.accentColor).scaledToFill().scaleEffect(1.3)
                            }
                    } else {
                        Image(systemName: .line3HorizontalDecrease)
                    }
                })
                .pickerStyle(.menu)
            }
#endif
        }
    }
}

//MARK: NewsPreview
struct NewsPreview: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    var news: DoriFrontend.News.ListItem
    var showLocale: Bool = true
    var showDetails: Bool = false
    var showImages: Bool = false
    var dateFormatter = DateFormatter()
    
    var allEvents: [PreviewEvent]?
    var allGacha: [PreviewGacha]?
    var allSongs: [PreviewSong]?
    init(
        allEvents: [PreviewEvent]?,
        allGacha: [PreviewGacha]?,
        allSongs: [PreviewSong]?,
        news: DoriFrontend.News.ListItem,
        showLocale: Bool = true,
        showDetails: Bool = false,
        showImages: Bool = false
    ) {
        self.allEvents = allEvents
        self.allGacha = allGacha
        self.allSongs = allSongs
        self.news = news
        self.showLocale = showLocale
        self.showDetails = showDetails
        self.showImages = showImages
        dateFormatter.setLocalizedDateFormatFromTemplate(showDetails ? "YMdjm" : "Mdjm")
    }
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Group {
                        Image(systemName: newsItemTypeIcon[news.type]!)
                        Group {
                            Text(newsItemTypeLocalizedString[news.type]!) + Text((showLocale && news.locale != nil) ? "Typography.brackets.with-space.\(news.locale!.rawValue.uppercased())" : "")
                        }
                        .offset(x: -3)
                    }
                    .foregroundStyle(newsItemTypeColor[news.type]!)
                    Text(dateFormatter.string(from: news.timestamp))
                        .foregroundStyle(.secondary)
                }
                .font(.footnote)
                .bold()
                Text(news.subject)
                    .lineLimit(2)
                    .foregroundStyle(.primary)
                    .font(.body)
                    .bold()
                    .typesettingLanguage(news.locale?.nsLocale().language ?? Locale.current.language, isEnabled: news.locale != nil)
                
                Text(getTimeMarkString(news.timeMark) ?? "")
                    .foregroundStyle(.primary)
                    .font(.body)
                    .fontWeight(.light)
                
                if showDetails {
                    getDetailsLineString(author: news.author, tags: news.tags)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            Spacer()
            
            if showImages {
                if sizeClass == .regular {
                    NewsImageView(news: news, allEvents: allEvents, allGacha: allGacha, allSongs: allSongs)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(getAccessibilityLabel(news))
        .accessibilityCustomContent("News.release-date", dateFormatter.string(from: news.timestamp), importance: .high)
        .accessibilityCustomContent("News.type", newsItemTypeLocalizedString[news.type]!)
        .accessibilityCustomContent("News.type", news.locale?.rawValue.uppercased() ?? "")
        .accessibilityCustomContent("News.tags", news.tags.joined(separator: ", "))
        .accessibilityCustomContent("News.author", news.author)
    }
    func getDetailsLineString(author: String, tags: [String], separator: String = "  ") -> SwiftUI.Text {
        let tagsCombined = news.tags.map { "#\($0)" }.joined(separator: separator)
        return Text(author).bold() + Text(separator) + Text(tagsCombined)
    }
    func getAccessibilityLabel(_ news: DoriFrontend.News.ListItem) -> Text {
        return Text(news.subject) + Text(verbatim: " ") + Text(getTimeMarkString(news.timeMark) ?? "") + Text(verbatim: ", \(news.locale?.rawValue ?? "")")
    }
}

struct NewsImageView: View {
    var news: DoriFrontend.News.ListItem
    var allEvents: [PreviewEvent]?
    var allGacha: [PreviewGacha]?
    var allSongs: [PreviewSong]?
    
    @State var imageURL: URL? = nil
    var body: some View {
        Group {
            if let imageURL {
                WebImage(url: imageURL)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: news.type == .song ? 100 : 75)
                    .cornerRadius(5)
            } else {
                Rectangle()
                    .frame(width: 0, height: 0)
                    .opacity(0)
            }
        }
        Rectangle()
            .frame(width: 0, height: 0)
            .opacity(0)
            .wrapIf({ if case .event = news.type { true } else { false } }()) { content in
                content
                    .onAppear {
                        if let allEvents {
                            imageURL = allEvents.first { $0.id == news.relatedID }?.logoImageURL(in: news.locale ?? .jp) ?? nil
                        }
                    }
                    .onChange(of: allEvents) {
                        if imageURL == nil, let allEvents {
                            imageURL = allEvents.first { $0.id == news.relatedID }?.logoImageURL(in: news.locale ?? .jp) ?? nil
                        }
                    }
            }
            .wrapIf({ if case .gacha = news.type { true } else { false } }()) { content in
                content
                    .onAppear {
                        if let allGacha {
                            imageURL = allGacha.first { $0.id == news.relatedID }?.logoImageURL(in: news.locale ?? .jp) ?? nil
                        }
                    }
                    .onChange(of: allEvents) {
                        if imageURL == nil, let allGacha {
                            imageURL = allGacha.first { $0.id == news.relatedID }?.logoImageURL(in: news.locale ?? .jp) ?? nil
                        }
                    }
            }
            .wrapIf({ if case .song = news.type { true } else { false } }()) { content in
                content
                    .onAppear {
                        if let allSongs {
                            imageURL = allSongs.first { $0.id == news.relatedID }?.jacketImageURL(in: news.locale ?? .jp) ?? nil
                        }
                    }
                    .onChange(of: allEvents) {
                        if imageURL == nil, let allSongs {
                            imageURL = allSongs.first { $0.id == news.relatedID }?.jacketImageURL(in: news.locale ?? .jp) ?? nil
                        }
                    }
            }
    }
}

func getTimeMarkString(_ timeMark: DoriFrontend.News.ListItem.TimeMark) -> LocalizedStringResource? {
    switch timeMark {
    case .willStartAfter(let interval):
        return "News.time-mark.will-start-after.\(interval)"
    case .willEndAfter(let interval):
        return "News.time-mark.will-end-after.\(interval)"
    case .willEndToday:
        return "News.time-mark.will-end-today"
    case .hasEnded:
        return "News.time-mark.has-ended"
    case .hasPublished:
        return "News.time-mark.has-published"
    case .willStartToday:
        return "News.time-mark.will-start-today"
    @unknown default:
        return nil
    }
}

let newsItemTypeIcon: [DoriFrontend.News.ListItem.ItemType: String] = [.article: "text.page", .event: "star.hexagon", .gacha: "dice", .loginCampaign: "calendar", .song: "music.microphone"]
let newsItemTypeColor: [DoriFrontend.News.ListItem.ItemType: Color] = [.article: .yellow, .event: .green, .gacha: .blue, .loginCampaign: .red, .song: .purple]
let newsItemTypeLocalizedString: [DoriFrontend.News.ListItem.ItemType: LocalizedStringResource] = [.article: "News.type.article", .event: "News.type.event", .gacha: "News.type.gacha", .loginCampaign: "News.type.login-campaign", .song: "News.type.song"]
//let newsTimeMarkTypeLocalizedString: [Dori]


/*

Item(
    id: 8537,
    title: "Asset Patch Note: CN 9.1.0.4",
    authors: ["Bestdori! Patch Note Bot"],
    timestamp: 2025-10-09 11:53:48 +0000,
    tags: ["Patch Note", "Asset", "GBP", "CN"],
    content: [
        DoriKit.DoriAPI.News.Item.Content.content(
            [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.localizedText("text.introAssetPatchNote[0]"),
             DoriKit.DoriAPI.News.Item.Content.ContentDataSection.textLiteral("9.1.0.4"),
             DoriKit.DoriAPI.News.Item.Content.ContentDataSection.localizedText("text.introAssetPatchNote[1]"),
             DoriKit.DoriAPI.News.Item.Content.ContentDataSection.textLiteral("9.1.0.3"),
             DoriKit.DoriAPI.News.Item.Content.ContentDataSection.localizedText("text.introAssetPatchNote[2]")]
        ),
        DoriKit.DoriAPI.News.Item.Content.heading("header.assets"),
        DoriKit.DoriAPI.News.Item.Content.content([
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.localizedText("text.addedAssets"),
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.ul([
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "musicjacket/musicjacket740", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/bgm740", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "event/loginbonus/bandori_chan_anime", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "event/loginbonus/bandori_chan_stamp_2510", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "musicscore/musicscore740", rich: false)]
            ]),
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.localizedText("text.changedContent"), DoriKit.DoriAPI.News.Item.Content.ContentDataSection.ul([
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "ingameskin/stagelight", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "stamp/01", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "stampatlas", rich: false)]
            ])
        ])
    ]
)


Item(
    id: 8540,
    title: "Asset Patch Note: JP 9.2.0.180",
    authors: ["Bestdori! Patch Note Bot"],
    timestamp: 2025-10-09 13:51:56 +0000,
    tags: ["Patch Note", "Asset", "GBP", "JP"],
    content: [
        DoriKit.DoriAPI.News.Item.Content.content([
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.localizedText("text.introAssetPatchNote[0]"),
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.textLiteral("9.2.0.180"),
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.localizedText("text.introAssetPatchNote[1]"),
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.textLiteral("9.2.0.170"),
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.localizedText("text.introAssetPatchNote[2]")]),
        DoriKit.DoriAPI.News.Item.Content.heading("header.assets"),
        DoriKit.DoriAPI.News.Item.Content.content([
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.localizedText("text.addedAssets"),
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.ul([
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "characters/resourceset/res001093", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "characters/resourceset/res002078", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "characters/resourceset/res003077", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "characters/resourceset/res004076", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "characters/resourceset/res005088", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "event/rimi_fly_high/images", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "event/rimi_fly_high/slide", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "gacha/screen/gacha1680", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "gacha/screen/gacha1681", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "gacha/screen/gacha1682", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "gacha/screen/gacha1684", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "gacha/screen/gacha1685", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "musicjacket/musicjacket750", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/bgm741", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "birthday/rinko_2025/openingimages", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "characters/ingameresourceset/res001093", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "characters/ingameresourceset/res002078", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "characters/ingameresourceset/res003077", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "characters/ingameresourceset/res004076", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "characters/ingameresourceset/res005088", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "characters/livesd/sd001093", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "characters/livesd/sd002078", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "characters/livesd/sd003077", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "characters/livesd/sd004076", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "characters/livesd/sd005088", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "comic/comic_fourframe_thumbnail/comic_fourframe_436", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "comic/comic_fourframe_thumbnail/comic_fourframe_437", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "comic/comic_fourframe_thumbnail/comic_fourframe_438", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "comic/comic_fourframe/comic_fourframe_436", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "comic/comic_fourframe/comic_fourframe_437", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "comic/comic_fourframe/comic_fourframe_438", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "event/loginbonus/cover10_release", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "event/loginbonus/helloween_2025", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "event/rimi_fly_high/topscreen", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "live2d/chara/001_live_event_309_ssr", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "live2d/chara/002_live_event_309_ur", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "live2d/chara/003_live_event_309_ur", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "live2d/chara/004_live_event_309_r", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "live2d/chara/005_live_event_309_sr", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "musicscore/musicscore750", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "pickupsituation/2299", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "pickupsituation/2300", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "pickupsituation/2301", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "pickupsituation/2302", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "pickupsituation/2303", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "scenario/effects/bgchange_contrail_sky", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "scenario/effects/bgchange_inside_bus", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "scenario/eventstory/event309", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/scenario/bgm/poppin_32_scenario", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/se/event309", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/voice/scenario/birthdaystory255", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/voice/scenario/eventstory309_0", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/voice/scenario/eventstory309_1", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/voice/scenario/eventstory309_2", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/voice/scenario/eventstory309_3", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/voice/scenario/eventstory309_4", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/voice/scenario/eventstory309_5", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/voice/scenario/eventstory309_6", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/voice/scenario/resourceset/res001093", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/voice/scenario/resourceset/res002078", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/voice/scenario/resourceset/res003077", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "star3d/character/costume/002_cos_live_event_309_ur", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "star3d/character/costume/003_cos_live_event_309_ur", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "star3d/character/head/002_cos_live_event_309_ur", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "star3d/character/head/003_cos_live_event_309_ur", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "story/bg/event/eventstory309_0", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "story/bg/event/eventstory309_1", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "story/bg/event/eventstory309_2", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "story/bg/event/eventstory309_3", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "story/bg/event/eventstory309_4", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "story/bg/event/eventstory309_5", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "story/bg/event/eventstory309_6", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "thumb/chara/card00046", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "title/event_309", rich: false)]
            ]),
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.localizedText("text.changedContent"),
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.ul([
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "musicjacket/musicjacket690", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "bg/scenario120", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "homebanner", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "scenario/birthdaystory", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/voice_stamp", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "sound/voice/gacha/operationspin", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "stamp/01", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "stampatlas", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "starshop/itemset_star/039", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "story/banner/memorial", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "story/bg/background120", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "thumb/chara/card00045", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "thumb/costume/group44", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "thumb/costume3ddress/group40", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "thumb/costume3dhairstyle/group40", rich: false)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "asset-single", data: "thumb/degree", rich: false)]
            ])
        ])
    ]
)



Item(
    id: 8534,
    title: "Patch Note: JP 9.2.0.170",
    authors: ["Bestdori! Patch Note Bot"],
    timestamp: 2025-10-02 13:25:38 +0000,
    tags: ["Patch Note", "GBP", "JP"],
    content: [
        DoriKit.DoriAPI.News.Item.Content.content([
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.localizedText("text.introPatchNote[0]"),
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.textLiteral("9.2.0.170"),
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.localizedText("text.introPatchNote[1]"),
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.textLiteral("9.2.0.161"),
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.localizedText("text.introPatchNote[2]")]),
        DoriKit.DoriAPI.News.Item.Content.heading("header.songs"),
        DoriKit.DoriAPI.News.Item.Content.content([
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.localizedText("text.addedSongs"),
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.ul([
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "song-single", data: "740", rich: true)]
            ])
        ]),
        DoriKit.DoriAPI.News.Item.Content.heading("header.logins"),
        DoriKit.DoriAPI.News.Item.Content.content([
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.localizedText("text.addedLogins"),
            DoriKit.DoriAPI.News.Item.Content.ContentDataSection.ul([
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "logincampaign-single", data: "1265", rich: true)],
                [DoriKit.DoriAPI.News.Item.Content.ContentDataSection.link(target: "logincampaign-single", data: "1271", rich: true)]
            ])
        ])
    ]
)

*/
