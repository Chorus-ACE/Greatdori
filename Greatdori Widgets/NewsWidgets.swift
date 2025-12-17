//===---*- Greatdori! -*---------------------------------------------------===//
//
// NewsWidgets.swift
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
import WidgetKit

struct NewsWidgets: Widget {
    let kind: String = "com.memz233.Greatdori.Widgets.News"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CardWidgetsEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .supportedFamilies([
            .systemMedium,
            .systemLarge,
            .systemExtraLarge,
            .init(rawValue: 4) // systemExtraLargePortrait
                               // We're receiving crash reports here
                               // on iOS 18.x, so we can't force unwrap it
        ].compactMap { $0 })
        .configurationDisplayName("Widget.news")
        .description("Widget.news.description")
    }
}

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> NewsEntry {
        .init(date: .now, news: nil)
    }
    
    func getSnapshot(in context: Context, completion: @escaping @Sendable (NewsEntry) -> Void) {
        if context.isPreview {
            completion(.init(date: .now))
            return
        }
        getNewsList { news in
            completion(.init(date: .now, news: news))
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<Entry>) -> Void) {
        let calendar = Calendar.current
        let now = Date.now
        let nextUpdateDate: Date
        if now.components.minute! < 30 {
            nextUpdateDate = calendar.date(byAdding: .hour, value: 1, to: now)!.componentsRewritten(minute: 1, second: 30)
        } else {
            nextUpdateDate = calendar.date(byAdding: .hour, value: 2, to: now)!.componentsRewritten(minute: 1, second: 30)
        }
        getNewsList { news in
            completion(.init(entries: [.init(date: .now, news: news)], policy: .after(nextUpdateDate)))
        }
    }
    
    func getNewsList(completion: sending @escaping ([_DoriFrontend.News.ListItem]?) -> Void) {
        Task {
            let cacheURL = URL(filePath: NSHomeDirectory() + "/Library/Caches/Greatdori_Widget_News.cache")
            
            for _ in 0..<5 {
                if let news = await _DoriFrontend.News.list() {
                    completion(news)
                    try? news.dataForCache.write(to: cacheURL)
                    return
                }
            }
            
            if let cachedData = try? Data(contentsOf: cacheURL) {
                completion(.init(fromCache: cachedData))
                return
            }
            
            completion(nil)
        }
    }
}

private struct NewsEntry: TimelineEntry {
    let date: Date
    var news: [_DoriFrontend.News.ListItem]?
}

private struct CardWidgetsEntryView : View {
    var entry: Provider.Entry
    let dateFormatter = {
        let result = DateFormatter()
        result.dateStyle = .medium
        result.timeStyle = .short
        return result
    }()
    
    @Environment(\.widgetFamily) var widgetFamily
    var capacity: Int {
        switch widgetFamily {
        case .systemMedium: 1
        case .systemLarge: 3
        case .systemExtraLarge: 4
        case let f where f.rawValue == 4: 6
        default: 3
        }
    }
    var titleFont: Font {
        switch widgetFamily {
        case .systemMedium: .subheadline
        case .systemLarge: .subheadline
        case .systemExtraLarge: .body
        default: .body
        }
    }
    var dateFont: Font {
        switch widgetFamily {
        case .systemMedium: .caption2
        case .systemLarge: .caption
        case .systemExtraLarge: .caption
        default: .caption
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text("News")
                        .font(.title)
                        .bold()
                    Spacer()
                }
                Spacer()
                    .frame(height: 10)
                if let news = entry.news {
                    ForEach(0..<news.prefix(capacity).count, id: \.self) { newsIndex in
                        NewsPreview(news: news[newsIndex])
                        if newsIndex != capacity-1 {
                            Divider()
                        }
                    }
                } else {
                    ForEach(0..<5, id: \.self) { newsIndex in
                        VStack(alignment: .leading) {
                            Text(verbatim: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
                                .lineLimit(3)
                                .foregroundStyle(.secondary)
                                .redacted(reason: .placeholder)
                        }
                        
                        if newsIndex != 4 {
                            Rectangle()
                                .frame(height: 1)
                                .opacity(0)
                        }
                    }
                }
            }
            Spacer()
        }
        .animation(.easeInOut(duration: 0.1), value: entry.news?.count)
    }
}

struct NewsPreview: View {
    var news: _DoriFrontend.News.ListItem
    var showLocale: Bool = true
    var titleFont: Font = .body
    var dateFont: Font = .footnote
    var dateFormatter = DateFormatter()
    init(news: _DoriFrontend.News.ListItem, showLocale: Bool = true, titleFont: Font = .body, dateFont: Font = .footnote) {
        self.news = news
        self.showLocale = showLocale
        self.titleFont = titleFont
        self.dateFont = dateFont
        //        dateFormatter.dateStyle = .short
        //        dateFormatter.timeStyle = .short
        dateFormatter.setLocalizedDateFormatFromTemplate("Mdjm")
    }
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Group {
                    Image(systemName: newsItemTypeIcon[news.type]!)
                    Group {
                        Text(newsItemTypeLocalizedString[news.type]!) + Text((showLocale && news.locale != nil) ? "(\(news.locale!.rawValue.uppercased()))" : "")
                    }
                    .offset(x: -3)
                }
                .foregroundStyle(newsItemTypeColor[news.type]!)
                Text(dateFormatter.string(from: news.timestamp))
                    .foregroundStyle(.secondary)
            }
            .font(dateFont)
            .bold()
            //            .font(.caption)
            Text(news.subject)
                .lineLimit(2)
                .foregroundStyle(.primary)
                .font(titleFont)
                .bold()
            
            Group {
                switch news.timeMark {
                case .willStartAfter(let interval):
                    Text("News.time-mark.will-start-after.\(interval)")
                case .willEndAfter(let interval):
                    Text("News.time-mark.will-end-after.\(interval)")
                case .willEndToday:
                    Text("News.time-mark.will-end-today")
                case .hasEnded:
                    Text("News.time-mark.has-ended")
                case .hasPublished:
                    Text("News.time-mark.has-published")
                @unknown default:
                    //                    Text("")
                    EmptyView()
                }
            }
            .foregroundStyle(.primary)
            .font(titleFont)
            .fontWeight(.light)
        }
    }
}

let newsItemTypeIcon: [_DoriFrontend.News.ListItem.ItemType: String] = [.article: "text.page", .event: "star.hexagon", .gacha: "dice", .loginCampaign: "calendar", .song: "music.microphone"]
let newsItemTypeColor: [_DoriFrontend.News.ListItem.ItemType: Color] = [.article: .gray, .event: .green, .gacha: .blue, .loginCampaign: .red, .song: .purple]
let newsItemTypeLocalizedString: [_DoriFrontend.News.ListItem.ItemType: LocalizedStringResource] = [.article: "News.type.article", .event: "News.type.event", .gacha: "News.type.gacha", .loginCampaign: "News.type.login-campaign", .song: "News.type.song"]
//let newsTimeMarkTypeLocalizedString: [Dori]
