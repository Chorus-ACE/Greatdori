//===---*- Greatdori! -*---------------------------------------------------===//
//
// HomeView.swift
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
import DoriKit
import SDWebImageSwiftUI

struct HomeView: View {
    @State var news: [NewsListItem]?
    @State var birthdays: [BirthdayCharacter]?
    @State var latestEvents: LocalizedData<PreviewEvent>?
    @State var availability = [true, true, true]
    var body: some View {
        Form {
            Section {
                if let news {
                    ForEach(news.prefix(5), id: \.title) { item in
                        NavigationLink(destination: { NewsDetailView(item: item) }) {
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .font(.system(size: 14, weight: .semibold))
                                Text({
                                    let df = DateFormatter()
                                    df.dateStyle = .medium
                                    df.timeStyle = .short
                                    return df.string(from: item.timestamp)
                                }())
                                .font(.system(size: 12))
                                .opacity(0.6)
                            }
                        }
                    }
                    NavigationLink(destination: { NewsListView() }) {
                        Label("显示所有", systemImage: "list.bullet")
                    }
                } else {
                    if availability[0] {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        UnavailableView("载入资讯时出错", systemImage: "newspaper.fill", retryHandler: getNews)
                    }
                }
            } header: {
                Text("资讯")
            }
            Section {
                if let birthdays {
                    ForEach(birthdays) { character in
                        NavigationLink(destination: { CharacterDetailView(id: character.id) }) {
                            HStack {
                                WebImage(url: character.iconImageURL)
                                    .resizable()
                                    .clipShape(Circle())
                                    .frame(width: 30, height: 30)
                                if !isTodayBirthday(of: character) {
                                    Text(birthdayDateFormatter.string(from: character.birthday))
                                        .accessibilityLabel(Text(verbatim: "\(character.characterName.forPreferredLocale() ?? ""), \(birthdayDateFormatter.string(from: character.birthday))"))
                                } else {
                                    Text(character.characterName.forPreferredLocale() ?? birthdayDateFormatter.string(from: character.birthday))
                                        .accessibilityLabel(Text("\(character.characterName.forPreferredLocale() ?? "")，今天生日", comment: "Accessibility"))
                                }
                            }
                        }
                    }
                } else {
                    if availability[1] {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        UnavailableView("载入生日时出错", systemImage: "birthday.cake.fill", retryHandler: getBirthdays)
                    }
                }
            } header: {
                if let firstBirthday = birthdays?.first,
                   isTodayBirthday(of: firstBirthday) {
                    Text("生日快乐 🎉")
                } else {
                    Text("生日")
                }
            }
            Section {
                if let latestEvents {
                    ForEach(_DoriAPI.Locale.allCases, id: \.rawValue) { locale in
                        NavigationLink(destination: { EventDetailView(id: latestEvents.forLocale(locale)!.id) }) {
                            if locale != .kr {
                                EventCardView(latestEvents.forLocale(locale)!, inLocale: locale, showsCountdown: true)
                            } else {
                                EventCardView(latestEvents.forLocale(locale)!, inLocale: locale, showsCountdown: true)
                                    .grayscale(1)
                            }
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    }
                } else {
                    if availability[2] {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                    } else {
                        UnavailableView("载入活动时出错", systemImage: "star.hexagon.fill", retryHandler: getEvents)
                    }
                }
            } header: {
                Text("活动")
            }
        }
        .navigationTitle("主页")
        .task {
            await getNews()
        }
        .task {
            await getBirthdays()
        }
        .task {
            await getEvents()
        }
    }
    
    var birthdayDateFormatter: DateFormatter {
        let result = DateFormatter()
        result.locale = Locale.current
        result.setLocalizedDateFormatFromTemplate("MMMd")
        result.timeZone = .init(identifier: "Asia/Tokyo")
        return result
    }
    func isTodayBirthday(of character: _DoriAPI.Characters.BirthdayCharacter) -> Bool {
        let timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let componments = character.birthday.components(in: timeZone)
        let nowComponments = Date.now.components
        return componments.month == nowComponments.month && componments.day == nowComponments.day
    }
    
    func getNews() async {
        availability[0] = true
        withDoriCache(id: "Home_News", trait: .realTime) {
            await NewsListItem.all()
        }.onUpdate {
            if let news = $0 {
                self.news = news
            } else {
                availability[0] = false
            }
        }
    }
    func getBirthdays() async {
        availability[1] = true
        withDoriCache(id: "Home_Birthdays", trait: .realTime) {
            await BirthdayCharacter.recent()
        }.onUpdate {
            if let birthdays = $0 {
                self.birthdays = birthdays
            } else {
                availability[1] = false
            }
        }
    }
    func getEvents() async {
        availability[2] = true
        withDoriCache(id: "Home_LatestEvents", trait: .realTime) {
            await PreviewEvent.localizedLatest()
        }.onUpdate {
            if let latestEvents = $0 {
                self.latestEvents = latestEvents
            } else {
                availability[2] = false
            }
        }
    }
}
