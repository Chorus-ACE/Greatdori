//===---*- Greatdori! -*---------------------------------------------------===//
//
// CalendarEvents.swift
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
import EventKit
import Foundation

func updateBirthdayCalendar() async throws {
    guard let characters = await DoriAPI.Characters.allBirthday() else { return }
    
    let store = EKEventStore()
    
    if let id = UserDefaults.standard.string(forKey: "BirthdaysCalendarID"),
       let calendar = store.calendar(withIdentifier: id) {
        try? store.removeCalendar(calendar, commit: false)
    }
    
    let calendar = EKCalendar(for: .event, eventStore: store)
    calendar.title = String(localized: "Birthday-calendar.title")
    calendar.source = store.sources.first(where: { $0.sourceType == .local || $0.sourceType == .calDAV })
    calendar.cgColor = Color.accentColor.resolve(in: .init()).cgColor
    UserDefaults.standard.set(calendar.calendarIdentifier, forKey: "BirthdaysCalendarID")
    try store.saveCalendar(calendar, commit: false)
    
    var birthdaySourceCalendar = Calendar(identifier: .gregorian)
    birthdaySourceCalendar.timeZone = getBirthdayTimeZone(from: BirthdayTimeZone(rawValue: UserDefaults.standard.string(forKey: "BirthdayTimeZone") ?? "JST") ?? .JST)
//    birthdaySourceCalendar.timeZone = .init(identifier: "Asia/Tokyo")!
    let userCalendar = Calendar.current
    
    for character in characters {
        let birthdayComponents = birthdaySourceCalendar.dateComponents([.month, .day], from: character.birthday)
        
        let event = EKEvent(eventStore: store)
        event.title = String(localized: "Birthday-calendar.birthday.\(character.characterName.forPreferredLocale()!.replacingOccurrences(of: " ", with: ""))")
        event.calendar = calendar
        event.isAllDay = true
        event.startDate = userCalendar.date(
            from: .init(
                year: 2015,
                month: birthdayComponents.month,
                day: birthdayComponents.day,
                hour: 0,
                minute: 0,
                second: 0
            )
        )!
        event.endDate = userCalendar.date(
            from: .init(
                year: 2015,
                month: birthdayComponents.month,
                day: birthdayComponents.day,
                hour: 23,
                minute: 59,
                second: 59
            )
        )!
        event.alarms = [
            .init(relativeOffset: -1.0 * 60 * 60 * 15), // the previous day, 9 AM
            .init(relativeOffset: 60.0 * 60 * 9)
        ]
        event.recurrenceRules = [.init(recurrenceWith: .yearly, interval: 1, end: nil)]
        try store.save(event, span: .futureEvents, commit: false)
    }
    
    try store.commit()
}

func removeBirthdayCalendar() throws {
    let store = EKEventStore()
    
    if let id = UserDefaults.standard.string(forKey: "BirthdaysCalendarID"),
       let calendar = store.calendar(withIdentifier: id) {
        try store.removeCalendar(calendar, commit: true)
        UserDefaults.standard.removeObject(forKey: "BirthdaysCalendarID")
    }
}
