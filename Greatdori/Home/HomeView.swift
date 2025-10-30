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
import Combine
import SDWebImageSwiftUI

let loadingAnimationDuration = 0.1
let localeFromStringDict: [String: _DoriAPI.Locale] = ["jp": .jp, "cn": .cn, "tw": .tw, "en": .en, "kr": .kr]
//let localeToStringDict: [DoriAPI.Locale: String] = [.jp: "JP", .en: "EN", .tw: "TW", .cn: "CN", .kr: "KR"]

private let _homeNavigationSubject = PassthroughSubject<NavigationPage?, Never>()
@_transparent
private func homeNavigate(to page: NavigationPage?) {
    _homeNavigationSubject.send(page)
}
enum NavigationPage: Hashable {
    case news
    case characterDetail(Int)
    case eventDetail(Int)
}

struct HomeView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.platform) var platform
    @Environment(\.colorScheme) var colorScheme
    @State var useCompactVariant = true
    @State var showSettingsSheet = false
    @State var currentNavigationPage: NavigationPage?
    @AppStorage("homeEventServer1") var homeEventServer1 = "jp"
    @AppStorage("homeEventServer2") var homeEventServer2 = "cn"
    @AppStorage("homeEventServer3") var homeEventServer3 = "tw"
    @AppStorage("homeEventServer4") var homeEventServer4 = "en"
    var body: some View {
        NavigationStack {
            ScrollView {
                ZStack {
                    VStack {
                        HomeBannersView()
                        HStack {
                            VStack {
                                HomeNewsView()
                                CustomGroupBox { HomeBirthdayView() }
                                HomeEventsView(locale: localeFromStringDict[homeEventServer4] ?? .jp)
                                Spacer()
                            }
                            VStack {
                                HomeEventsView(locale: localeFromStringDict[homeEventServer1] ?? .jp)
                                HomeEventsView(locale: localeFromStringDict[homeEventServer2] ?? .jp)
                                HomeEventsView(locale: localeFromStringDict[homeEventServer3] ?? .jp)
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal)
                    .opacity(useCompactVariant ? 0 : 1)
                    .frame(width: useCompactVariant ? 0 : nil, height: useCompactVariant ? 0 : nil)
                    VStack {
                        HomeBannersView()
                        HomeNewsView()
                        CustomGroupBox { HomeBirthdayView() }
                        HomeEventsView(locale: localeFromStringDict[homeEventServer1] ?? .jp)
                        HomeEventsView(locale: localeFromStringDict[homeEventServer2] ?? .jp)
                        HomeEventsView(locale: localeFromStringDict[homeEventServer3] ?? .jp)
                        HomeEventsView(locale: localeFromStringDict[homeEventServer4] ?? .jp)
                    }
                    .padding(.horizontal)
                    .opacity(!useCompactVariant ? 0 : 1)
                    .frame(width: !useCompactVariant ? 0 : nil, height: !useCompactVariant ? 0 : nil)
                }
            }
            .withSystemBackground()
            .navigationTitle("App.home")
            .navigationDestination(item: $currentNavigationPage) { page in
                switch page {
                case .news:
                    NewsView() // FIXME: [NAVI785]
                case .characterDetail(let id):
                    CharacterDetailView(id: id)
                case .eventDetail(let id):
                    EventDetailView(id: id)
                }
            }
            .toolbar {
                if platform != .mac && sizeClass == .compact {
                    ToolbarItem(placement: .automatic, content: {
                        Button(action: {
                            showSettingsSheet = true
                        }, label: {
                            Image(systemName: "gear")
                        })
                    })
                }
            }
            .sheet(isPresented: $showSettingsSheet, content: {
                SettingsView(usedAsSheet: true)
            })
            .handlesExternalView()
        }
        .onFrameChange { geometry in
            if useCompactVariant && geometry.size.width > 675 {
                useCompactVariant = false
            } else if !useCompactVariant && geometry.size.width <= 675 {
                useCompactVariant = true
            }
        }
        .onReceive(_homeNavigationSubject) { page in
            currentNavigationPage = page
        }
    }
}

struct HomeNewsView: View {
    @State var news: [_DoriFrontend.News.ListItem]?
    @State var allEvents: [PreviewEvent]?
    @State var allGacha: [PreviewGacha]?
    @State var allSongs: [PreviewSong]?
    var dateFormatter = DateFormatter()
    init() {
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
    }
    let totalNewsNumber = 4
    var body: some View {
        Button(action: {
            homeNavigate(to: .news)
        }, label: {
            CustomGroupBox {
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            if news != nil {
                                Text("Home.news")
                                    .font(.title2)
                                    .bold()
                            } else {
                                Text("Home.news")
                                    .font(.title2)
                                    .bold()
                                    .foregroundStyle(getPlaceholderColor())
                                    .redacted(reason: .placeholder)
                            }
                            Spacer()
                        }
                        Rectangle()
                            .frame(height: 1)
                            .opacity(0)
                            .accessibilityHidden(true)
                        if let news {
                            ForEach(0..<news.prefix(totalNewsNumber).count, id: \.self) { newsIndex in
                                NewsPreview(allEvents: allEvents, allGacha: allGacha, allSongs: allSongs, news: news[newsIndex])
                                if newsIndex != (totalNewsNumber - 1) {
                                    Rectangle()
                                        .frame(height: 1)
                                        .opacity(0)
                                }
                            }
                        } else {
                            ForEach(0..<5, id: \.self) { newsIndex in
                                VStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.15))
//                                        .fill(Color.placeholderText)
                                        .frame(height: 40)
                                        .cornerRadius(5)
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
            }
        })
        .animation(.easeInOut(duration: loadingAnimationDuration), value: news?.count)
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .task {
            DoriCache.withCache(id: "Home_News", trait: .realTime) {
                await _DoriFrontend.News.list()
            } .onUpdate {
                news = $0
            }
            await withTaskGroup { group in
                group.addTask {
                    let events = await _DoriAPI.Events.all()
                    await MainActor.run {
                        allEvents = events
                    }
                }
                group.addTask {
                    let gacha = await _DoriAPI.Gachas.all()
                    await MainActor.run {
                        allGacha = gacha
                    }
                }
                group.addTask {
                    let songs = await _DoriAPI.Songs.all()
                    await MainActor.run {
                        allSongs = songs
                    }
                }
            }
        }
    }
}

struct HomeBirthdayView: View {
    @Environment(\.scenePhase) var scenePhase
    #if os(macOS)
    @Environment(\.appearsActive) var appearsActive
    #endif
    @AppStorage("showBirthdayDate") var showBirthdayDate = showBirthdayDateDefaultValue
    @State var birthdays: [_DoriFrontend.Characters.BirthdayCharacter]?
    @State var systemBirthdays: [_DoriFrontend.Characters.BirthdayCharacter]?
    var formatter = DateFormatter()
    var todaysDateFormatter = DateFormatter()
    var calendar = Calendar(identifier: .gregorian)
    var todaysDateCalendar = Calendar(identifier: .gregorian)
    init() {
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        formatter.timeZone = .init(identifier: "Asia/Tokyo")
        
        todaysDateCalendar.timeZone = getBirthdayTimeZone()
        todaysDateFormatter.locale = Locale.current
        todaysDateFormatter.setLocalizedDateFormatFromTemplate("MMMd")
        todaysDateFormatter.timeZone = getBirthdayTimeZone()
    }
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    if birthdays != nil && todaysHerBirthday(birthdays!.first!.birthday) {
                        Text("Home.birthday.happy-birthday")
                            .font(.title2)
                            .bold()
                    } else if birthdays != nil {
                        Text("Home.birthday")
                            .font(.title2)
                            .bold()
                    } else {
                        Text("Home.birthday")
                            .foregroundStyle(getPlaceholderColor())
                            .font(.title2)
                            .bold()
                            .redacted(reason: .placeholder)
                    }
                    Spacer()
                    Group {
                        if showBirthdayDate == 3 {
                            Text(todaysDateFormatter.string(from: .now))
                        } else if showBirthdayDate == 2 {
                            // If today's someone's birthday
                            if (birthdays != nil && todaysHerBirthday(birthdays!.first!.birthday)) {
                                Text(todaysDateFormatter.string(from: .now))
                            }
                        } else if showBirthdayDate == 1 {
                            if systemBirthdays != nil && birthdays != nil && (systemBirthdays != birthdays) {
                                Text(todaysDateFormatter.string(from: .now))
                            }
                        }
                    }
                    .foregroundStyle(.secondary)
                    .fontWeight(.light)
                    .font(.title3)
                    .wrapIf(birthdays == nil) { content in
                        content
                            .redacted(reason: .placeholder)
                    }
                }
                if let birthdays {
                    HStack {
                        ForEach(0..<birthdays.count, id: \.self) { i in
                            if (i != birthdays.count - 1)
                                && (birthdays[i].birthday == birthdays[i + 1].birthday)
                                && (!todaysHerBirthday(birthdays[i].birthday)) {
                                // If she is not the last person & the person next have the same birthday & today's not her birthday.
                                // (Cond. 3 is because labels should be expanded to show their full name during their birthday.)
                                Menu(content: {
                                    Button(action: {
                                        homeNavigate(to: .characterDetail(birthdays[i].id))
                                    }, label: {
                                        HStack {
                                            #if os(iOS)
                                            WebImage(url: birthdays[i].iconImageURL)
                                                .resizable()
                                                .clipShape(Circle())
                                                .frame(width: 30, height: 30)
                                            #endif
                                            Text(birthdays[i].characterName.forPreferredLocale() ?? "")
                                        }
                                    })
                                    Button(action: {
                                        homeNavigate(to: .characterDetail(birthdays[i + 1].id))
                                    }, label: {
                                        HStack {
                                            #if os(iOS)
                                            WebImage(url: birthdays[i+1].iconImageURL)
                                                .resizable()
                                                .clipShape(Circle())
                                                .frame(width: imageButtonSize, height: imageButtonSize)
                                            #endif
                                            Text(birthdays[i+1].characterName.forPreferredLocale() ?? "")
                                        }
                                    })
                                }, label: {
                                    WebImage(url: birthdays[i].iconImageURL)
                                        .resizable()
                                        .clipShape(Circle())
                                        .frame(width: imageButtonSize, height: imageButtonSize)
                                        .zIndex(2)
                                    WebImage(url: birthdays[i+1].iconImageURL)
                                        .resizable()
                                        .clipShape(Circle())
                                        .frame(width: imageButtonSize, height: imageButtonSize)
                                        .padding(.leading, -15)
                                        .zIndex(1)
                                    Text(formatter.string(from: birthdays[i].birthday))
                                })
                                Rectangle()
                                    .opacity(0)
                                    .frame(width: 2, height: 2)
                            } else if (i != 0)
                                        && (birthdays[i].birthday == birthdays[i - 1].birthday)
                                        && (!todaysHerBirthday(birthdays[i].birthday)) {
                                // If she is not the first person & the person in front have the same birthday & today's not her birthday.
                                EmptyView()
                            } else {
                                Button(action: {
                                    homeNavigate(to: .characterDetail(birthdays[i].id))
                                }, label: {
                                    WebImage(url: birthdays[i].iconImageURL)
                                        .resizable()
                                        .clipShape(Circle())
                                        .frame(width: imageButtonSize, height: imageButtonSize)
                                    if todaysHerBirthday(birthdays[i].birthday) {
                                        Text(birthdays[i].characterName.forPreferredLocale() ?? "")
                                    } else {
                                        Text(formatter.string(from: birthdays[i].birthday))
                                    }
                                })
                                .buttonStyle(.plain)
                                Rectangle()
                                    .opacity(0)
                                    .frame(width: 2, height: 2)
                            }
                        }
                    }
                } else {
                    HStack {
                        Text(verbatim: "Lorem ipsum")
                            .foregroundStyle(getPlaceholderColor())
                            .redacted(reason: .placeholder)
                        Rectangle()
                            .opacity(0)
                            .frame(width: 2, height: 2)
                        Text(verbatim: "dolor sit")
                            .foregroundStyle(getPlaceholderColor())
                            .redacted(reason: .placeholder)
                        Spacer()
                    }
                }
            }
            Spacer()
        }
        .animation(.easeInOut(duration: loadingAnimationDuration), value: birthdays?.count)
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .onAppear {
            updateBirthday()
        }
        #if os(macOS)
        .onChange(of: appearsActive) {
            if appearsActive {
                updateBirthday()
            }
        }
        #else
        .onChange(of: scenePhase) {
            if case .active = scenePhase {
                updateBirthday()
            }
        }
        #endif
    }
    func todaysHerBirthday(_ birthday: Date) -> Bool {
        let today = Date.now
        var calendar = Calendar(identifier: .gregorian)
        var jstCalendar = calendar
        calendar.timeZone = getBirthdayTimeZone()
        jstCalendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        
        let birthdaysMonth: Int = jstCalendar.component(.month, from: birthday)
        let birthdaysDay: Int = jstCalendar.component(.day, from: birthday)
        
        let todaysMonth: Int = calendar.component(.month, from: today)
        let todaysDay: Int = calendar.component(.day, from: today)
        
        return (birthdaysMonth == todaysMonth && birthdaysDay == todaysDay)
    }
    func birthdayTimeIsInSameDayWithSystemTime() -> Bool {
        var birthdayCalendar = Calendar(identifier: .gregorian)
        birthdayCalendar.timeZone = getBirthdayTimeZone()
        let systemCalendar = Calendar(identifier: .gregorian)
        
        let birthdayMonth: Int = birthdayCalendar.component(.month, from: Date.now)
        let birthdayDay: Int = birthdayCalendar.component(.day, from: Date.now)
        
        let systemMonth: Int = systemCalendar.component(.month, from: Date.now)
        let systemDay: Int = systemCalendar.component(.day, from: Date.now)
        
        return (birthdayMonth == systemMonth && birthdayDay == systemDay)
    }
    
    func updateBirthday() {
        Task {
            birthdays = await _DoriFrontend.Characters.recentBirthdayCharacters(timeZone: getBirthdayTimeZone())
            if getBirthdayTimeZone() != TimeZone.autoupdatingCurrent {
                systemBirthdays = await _DoriFrontend.Characters.recentBirthdayCharacters(timeZone: getBirthdayTimeZone(from: .adaptive))
            } else {
                systemBirthdays = nil
            }
        }
    }
}

struct HomeEventsView: View {
    @State var latestEvents: _DoriAPI.LocalizedData<_DoriFrontend.Events.PreviewEvent>?
    @State var imageOpacity: Double = 0
    @State var placeholderOpacity: Double = 1
    var locale: _DoriAPI.Locale = .jp
    var dateFormatter = DateFormatter()
    init(locale: _DoriAPI.Locale = .jp) {
        self.locale = locale
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
    }
    
    var body: some View {
        Button(action: {
            if let latestEvents {
                homeNavigate(to: .eventDetail(latestEvents.forLocale(locale)!.id))
//                homeNavigate(to: .eventDetail(180))
            }
        }, label: {
            CustomGroupBox {
                ZStack {
                    Group {
                        if let latestEvents {
                            EventInfoForHome(latestEvents.forLocale(locale)!, inLocale: locale, showsCountdown: true)
                        }
                    }
                    .opacity(imageOpacity)
                    .zIndex(2)
                    Group {
                        if latestEvents == nil {
                            VStack {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.15))
                                    .aspectRatio(3.0, contentMode: .fit)
                                Text(verbatim: "Lorem ipsum dolor sit amet consectetur")
                                    .bold()
                                    .font(.title3)
                                    .foregroundStyle(getPlaceholderColor())
                                    .redacted(reason: .placeholder)
                                Text(verbatim: "Lorem ipsum dolor")
                                    .foregroundStyle(getPlaceholderColor())
                                    .redacted(reason: .placeholder)
                            }
                        }
                    }
                    .opacity(placeholderOpacity)
                    .zIndex(1)
                }
            }
        })
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .task {
            DoriCache.withCache(id: "Home_LatestEvents", trait: .realTime) {
                await _DoriFrontend.Events.localizedLatestEvent()
            } .onUpdate {
                latestEvents = $0
                withAnimation(.easeInOut(duration: loadingAnimationDuration), {
//                    placeholderOpacity = 0
                    imageOpacity = 1
                })
            }
        }
    }
}

struct HomeBannersView: View {
    @AppStorage("AdvancedSettingsHaveReset") var advSettingsHaveReset = false
    var body: some View {
        #if !(DORIKIT_ENABLE_PRECACHE)
        Banner(color: .red) {
            Image(systemName: "exclamationmark.circle")
                .font(.title3)
                .bold()
            VStack(alignment: .leading) {
                Text("Home.banner.no-pre-cahce.title")
                    .bold()
                Text("Home.banner.no-pre-cahce.subtitle")
                    .font(isMACOS ? .body : .footnote)
            }
        }
        #endif
        Banner(isPresented: $advSettingsHaveReset, dismissable: true) {
            Image(systemName: "exclamationmark.circle")
                .font(.title3)
                .bold()
            VStack(alignment: .leading) {
                Text("Home.banner.crash.title")
                    .bold()
                Text("Home.banner.crash.subtitle")
                    .font(isMACOS ? .body : .footnote)
            }
        }
    }
}

extension PassthroughSubject: @retroactive @unchecked Sendable where Output: Sendable, Failure: Sendable {}
