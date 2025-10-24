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
    
    var components: DateComponents {
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
    func components(in timezone: TimeZone) -> DateComponents {
        var calendar = Calendar.current
        calendar.timeZone = timezone
        return calendar.dateComponents(
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
