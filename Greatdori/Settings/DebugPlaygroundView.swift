//===---*- Greatdori! -*---------------------------------------------------===//
//
// DebugPlaygroundView.swift
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
import UserNotifications

struct DebugPlaygroundView: View {
    var body: some View {
        WrappingHStack(alignment: .trailing) {
            ForEach(1...6, id: \.self) { i in
                Text("\(i)")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(.blue.opacity(0.2)))
            }
        }
        .padding()
        .border(.gray)
    }
}

//extension DoriAPI.Songs.Song.MusicVideoMetadata: Sequence {}

func scheduleLocalNotification() {
    let content = UNMutableNotificationContent()
    content.title = "交差点、ふたつ星が笑って"
    content.body = "Is Starting Today"
    content.sound = .default
    content.interruptionLevel = .active

    // 5 秒后触发
    let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

    let request = UNNotificationRequest(
        identifier: "local_5s_notification",
        content: content,
        trigger: trigger
    )

    UNUserNotificationCenter.current().add(request) { error in
        if let error = error {
            print("Schedule error: \(error)")
        }
    }
}
