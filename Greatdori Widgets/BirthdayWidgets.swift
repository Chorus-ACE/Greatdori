//===---*- Greatdori! -*---------------------------------------------------===//
//
// BirthdayWidgets.swift
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

#if os(macOS)
typealias PlatformImage = NSImage
#else
typealias PlatformImage = UIImage
#endif

struct BirthdayWidgets: Widget {
    let kind: String = "com.memz233.Greatdori.Widgets.Birthday"
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            BirthdayWidgetsEntryView(entry: entry)
                .containerBackground(.background, for: .widget)
        }
        .supportedFamilies([
            .systemSmall,
            .systemMedium
        ])
        .configurationDisplayName("Widget.birthday")
        .description("Widget.birthday.description")
    }
}

private struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> BirthdayEntry {
        .init(date: .now)
    }
    
    func getSnapshot(in context: Context, completion: @escaping @Sendable (BirthdayEntry) -> Void) {
        if context.isPreview {
            Task {
                if let entry = await getEntry(
                    at: .init(timeIntervalSince1970: 1768561200)
                ) {
                    completion(entry)
                }
            }
            return
        }
        Task {
            if let entry = await getEntry(at: .now) {
                completion(entry)
            }
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<Entry>) -> Void) {
        let calendar = Calendar.current
        let now = Date.now
        let nextUpdateDate = calendar.date(byAdding: .hour, value: 1, to: now)!.componentsRewritten(minute: 0, second: 1)
        Task {
            var entries: [BirthdayEntry] = []
            if let entry = await getEntry(at: now) {
                entries.append(entry)
            }
            completion(.init(entries: entries, policy: .after(nextUpdateDate)))
        }
    }
    
    func getEntry(at date: Date) async -> BirthdayEntry? {
        var entry = BirthdayEntry(date: date)
        
        guard let birthdays = await DoriFrontend.Characters.recentBirthdayCharacters(
            aroundDate: date,
            timeZone: birthdayTimeZone()
        ) else { return nil }
        entry.birthdays = birthdays
        if birthdayTimeZone() != TimeZone.autoupdatingCurrent {
            guard let birthdays = await DoriFrontend.Characters.recentBirthdayCharacters(
                aroundDate: date,
                timeZone: birthdayTimeZone(from: .adaptive)
            ) else { return nil }
            entry.systemBirthdays = birthdays
        }
        
        for birthday in birthdays {
            if let data = try? Data(contentsOf: birthday.iconImageURL) {
                entry.avatarImageData.updateValue(data, forKey: birthday.id)
            } else {
                return nil
            }
        }
        if let birthdays = entry.systemBirthdays {
            for birthday in birthdays where !entry.avatarImageData.keys.contains(birthday.id) {
                if let data = try? Data(contentsOf: birthday.iconImageURL) {
                    entry.avatarImageData.updateValue(data, forKey: birthday.id)
                } else {
                    return nil
                }
            }
        }
        
        return entry
    }
}

private struct BirthdayEntry: TimelineEntry {
    let date: Date
    
    var birthdays: [DoriFrontend.Characters.BirthdayCharacter]?
    var systemBirthdays: [DoriFrontend.Characters.BirthdayCharacter]?
    var avatarImageData: [Int /* Character ID */: Data] = [:]
}

private struct BirthdayWidgetsEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) private var widgetFamily
    @AppStorage("showBirthdayDate") private var showBirthdayDate = 1
    private var formatter = DateFormatter()
    private var todaysDateFormatter = DateFormatter()
    private var calendar = Calendar(identifier: .gregorian)
    private var todaysDateCalendar = Calendar(identifier: .gregorian)
    
    init(entry: Provider.Entry) {
        self.entry = entry
        
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        formatter.timeZone = .init(identifier: "Asia/Tokyo")
        
        todaysDateCalendar.timeZone = birthdayTimeZone()
        todaysDateFormatter.locale = Locale.current
        todaysDateFormatter.setLocalizedDateFormatFromTemplate("MMMd")
        todaysDateFormatter.timeZone = birthdayTimeZone()
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    if entry.birthdays != nil && todaysHerBirthday(entry.birthdays!.first!.birthday) {
                        Text("Widget.birthday.happy-birthday")
                            .font(.title2)
                            .bold()
                    } else if entry.birthdays != nil {
                        Text("Widget.birthday")
                            .font(.title2)
                            .bold()
                    } else {
                        Text("Widget.birthday")
                            .foregroundStyle(.gray)
                            .font(.title2)
                            .bold()
                            .redacted(reason: .placeholder)
                    }
                    Spacer()
                    if widgetFamily != .systemSmall {
                        Group {
                            if showBirthdayDate == 3 {
                                Text(todaysDateFormatter.string(from: .now))
                            } else if showBirthdayDate == 2 {
                                // If today's someone's birthday
                                if (entry.birthdays != nil && todaysHerBirthday(entry.birthdays!.first!.birthday)) {
                                    Text(todaysDateFormatter.string(from: .now))
                                }
                            } else if showBirthdayDate == 1 {
                                if entry.systemBirthdays != nil
                                    && entry.birthdays != nil
                                    && (entry.systemBirthdays != entry.birthdays) {
                                    Text(todaysDateFormatter.string(from: .now))
                                }
                            }
                        }
                        .foregroundStyle(.secondary)
                        .fontWeight(.light)
                        .font(.title3)
                        .wrapIf(entry.birthdays == nil) { content in
                            content
                                .redacted(reason: .placeholder)
                        }
                    }
                }
                if let birthdays = entry.birthdays {
                    ForEach(0..<birthdays.count, id: \.self) { i in
                        HStack {
                            if (i != birthdays.count - 1)
                                && (birthdays[i].birthday == birthdays[i + 1].birthday)
                                && (!todaysHerBirthday(birthdays[i].birthday)) {
                                // If she is not the last person & the person next have the same birthday & today's not her birthday.
                                // (Cond. 3 is because labels should be expanded to show their full name during their birthday.)
                                Group {
                                    if let _data = entry.avatarImageData[birthdays[i].id],
                                       let image = PlatformImage(data: _data) {
                                        Group {
                                            #if os(macOS)
                                            Image(nsImage: image)
                                                .resizable()
                                            #else
                                            Image(uiImage: image)
                                                .resizable()
                                            #endif
                                        }
                                        .zIndex(2)
                                    }
                                    if let _data = entry.avatarImageData[birthdays[i + 1].id],
                                       let image = PlatformImage(data: _data) {
                                        Group {
                                            #if os(macOS)
                                            Image(nsImage: image)
                                                .resizable()
                                            #else
                                            Image(uiImage: image)
                                                .resizable()
                                            #endif
                                        }
                                        .padding(.leading, -15)
                                        .zIndex(1)
                                    }
                                }
                                .clipShape(Circle())
                                #if os(macOS)
                                .frame(width: 30, height: 30)
                                #else
                                .frame(width: 35, height: 35)
                                #endif
                                Text(formatter.string(from: birthdays[i].birthday))
                                Rectangle()
                                    .opacity(0)
                                    .frame(width: 2, height: 2)
                            } else if (i != 0)
                                        && (birthdays[i].birthday == birthdays[i - 1].birthday)
                                        && (!todaysHerBirthday(birthdays[i].birthday)) {
                                // If she is not the first person & the person in front have the same birthday & today's not her birthday.
                                EmptyView()
                            } else {
                                if let _data = entry.avatarImageData[birthdays[i].id],
                                   let image = PlatformImage(data: _data) {
                                    Group {
                                        #if os(macOS)
                                        Image(nsImage: image)
                                            .resizable()
                                        #else
                                        Image(uiImage: image)
                                            .resizable()
                                        #endif
                                    }
                                    .clipShape(Circle())
                                    #if os(macOS)
                                    .frame(width: 30, height: 30)
                                    #else
                                    .frame(width: 35, height: 35)
                                    #endif
                                }
                                if todaysHerBirthday(birthdays[i].birthday) {
                                    Text(birthdays[i].characterName.forPreferredLocale() ?? "")
                                } else {
                                    Text(formatter.string(from: birthdays[i].birthday))
                                }
                                Rectangle()
                                    .opacity(0)
                                    .frame(width: 2, height: 2)
                            }
                        }
                    }
                    .wrapIf(widgetFamily == .systemSmall) { content in
                        VStack(alignment: .leading) {
                            content
                        }
                    } else: { content in
                        HStack {
                            content
                        }
                    }

                } else {
                    HStack {
                        Text(verbatim: "Lorem ipsum")
                            .foregroundStyle(.gray)
                            .redacted(reason: .placeholder)
                        Rectangle()
                            .opacity(0)
                            .frame(width: 2, height: 2)
                        Text(verbatim: "dolor sit")
                            .foregroundStyle(.gray)
                            .redacted(reason: .placeholder)
                        Spacer()
                    }
                }
            }
            Spacer()
        }
    }
    
    func todaysHerBirthday(_ birthday: Date) -> Bool {
        let today = Date.now
        var calendar = Calendar(identifier: .gregorian)
        var jstCalendar = calendar
        calendar.timeZone = birthdayTimeZone()
        jstCalendar.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        
        let birthdaysMonth: Int = jstCalendar.component(.month, from: birthday)
        let birthdaysDay: Int = jstCalendar.component(.day, from: birthday)
        
        let todaysMonth: Int = calendar.component(.month, from: today)
        let todaysDay: Int = calendar.component(.day, from: today)
        
        return (birthdaysMonth == todaysMonth && birthdaysDay == todaysDay)
    }
    func birthdayTimeIsInSameDayWithSystemTime() -> Bool {
        var birthdayCalendar = Calendar(identifier: .gregorian)
        birthdayCalendar.timeZone = birthdayTimeZone()
        let systemCalendar = Calendar(identifier: .gregorian)
        
        let birthdayMonth: Int = birthdayCalendar.component(.month, from: Date.now)
        let birthdayDay: Int = birthdayCalendar.component(.day, from: Date.now)
        
        let systemMonth: Int = systemCalendar.component(.month, from: Date.now)
        let systemDay: Int = systemCalendar.component(.day, from: Date.now)
        
        return (birthdayMonth == systemMonth && birthdayDay == systemDay)
    }
}

private func birthdayTimeZone(from input: BirthdayTimeZone? = nil) -> TimeZone {
    switch (input != nil ? input! : BirthdayTimeZone(rawValue: UserDefaults(suiteName: "group.memz233.Greatdori.Widgets")!.string(forKey: "BirthdayTimeZone") ?? "JST"))! {
    case .adaptive:
        return TimeZone.autoupdatingCurrent
    case .JST:
        return TimeZone(identifier: "Asia/Tokyo")!
    case .UTC:
        return TimeZone.gmt
    case .CST:
        return TimeZone(identifier: "Asia/Shanghai")!
    case .PT:
        return TimeZone(identifier: "America/Los_Angeles")!
    }
}

private enum BirthdayTimeZone: String, CaseIterable {
    case adaptive
    case JST
    case UTC
    case CST
    case PT
}
