//===---*- Greatdori! -*---------------------------------------------------===//
//
// Date+.swift
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

import Foundation

extension Date {
    private var calendar: Calendar {
        Calendar.autoupdatingCurrent
    }
    
    internal func assertSameDay(to date: Date) -> Date {
        let components = calendar.dateComponents([.hour, .minute, .second], from: self)
        var resultComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        resultComponents.hour = components.hour!
        resultComponents.minute = components.minute!
        resultComponents.second = components.second!
        return calendar.date(from: resultComponents)!
    }
    
    internal func interval(to date: Date) -> DateComponents {
        if self <= date {
            calendar.dateComponents([
                .era,
                .year,
                .month,
                .day,
                .hour,
                .minute,
                .second,
                .weekday,
                .weekdayOrdinal,
                .quarter,
                .weekOfMonth,
                .weekOfYear,
                .yearForWeekOfYear,
                .nanosecond,
                .calendar,
                .timeZone
            ], from: self, to: date)
        } else {
            calendar.dateComponents([
                .era,
                .year,
                .month,
                .day,
                .hour,
                .minute,
                .second,
                .weekday,
                .weekdayOrdinal,
                .quarter,
                .weekOfMonth,
                .weekOfYear,
                .yearForWeekOfYear,
                .nanosecond,
                .calendar,
                .timeZone
            ], from: date, to: self)
        }
    }
    
    internal func componentsRewritten(
        calendar: Calendar = .autoupdatingCurrent,
        year: Int? = nil,
        month: Int? = nil,
        day: Int? = nil,
        hour: Int? = nil,
        minute: Int? = nil,
        second: Int? = nil
    ) -> Date {
        var result = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: self)
        if let year {
            result.year = year
        }
        if let month {
            result.month = month
        }
        if let day {
            result.day = day
        }
        if let hour {
            result.hour = hour
        }
        if let minute {
            result.minute = minute
        }
        if let second {
            result.second = second
        }
        return calendar.date(from: result)!
    }
    
    internal var components: DateComponents {
        calendar.dateComponents(
            [
                .era,
                .year,
                .month,
                .day,
                .hour,
                .minute,
                .second,
                .weekday,
                .weekdayOrdinal,
                .quarter,
                .weekOfMonth,
                .weekOfYear,
                .yearForWeekOfYear,
                .nanosecond,
                .calendar,
                .timeZone
            ],
            from: self
        )
    }
}
