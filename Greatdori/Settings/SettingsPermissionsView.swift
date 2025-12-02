//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsPermissionsView.swift
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
import UserNotifications


struct SettingsPermissionsView: View {
    @Environment(\.openURL) var openURL
    @State var permissionNotGiven: Bool = false
    @State var permissionRejected: Bool = false
    var body: some View {
        Group {
#if os(iOS)
            Section(content: {
                SettingsPermissionsNotificationNews()
//                SettingsPermissionsCalendarBirthdays()
            }, header: {
                Text("Settings.permissions")
            }, footer: {
                if permissionNotGiven || permissionRejected {
                    VStack(alignment: .leading) {
                        if permissionNotGiven {
                            Text("Settings.notifications.authorization-required.open-settings")
                                .multilineTextAlignment(.leading)
                                .onTapGesture {
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        openURL(url)
                                    }
                                }
                        }
                        if permissionRejected {
                            Text("Settings.notifications.access-denied")
                                .multilineTextAlignment(.leading)
                        }
                    }
                }
            })
#else
            Group {
                Section {
                    SettingsPermissionsNotificationNews()
//                    SettingsPermissionsCalendarBirthdays()
                }
                Section(content: {
                    Button(action: {
                        openURL(.init(string: "x-apple.systempreferences:com.apple.preference.general")!)
                    }, label: {
                        Label("Settings.notifications.open-settings", systemImage: "arrow.up.right.square")
                    })
                    .buttonStyle(.plain)
                }, footer: {
                    if permissionNotGiven {
                        Text("Settings.notifications.authorization-required")
                    }
                    if permissionRejected {
                        Text("Settings.notifications.access-denied")
                    }
                })
            }
            .navigationTitle("Settings.permissions")
#endif
        }
        .task {
            let notificationStatus = await UNUserNotificationCenter.current().notificationSettings()
            let notificationIsAuthorized = notificationStatus.authorizationStatus == .authorized
            let notificationIsRejected = notificationStatus.authorizationStatus == .denied
            
//            let calendarStatus = EKEventStore.authorizationStatus(for: .event)
//            let calendarIsAuthorized = calendarStatus == .fullAccess
//            let calendarIsRejected = calendarStatus == .denied
            
            permissionNotGiven = !notificationIsAuthorized
            permissionRejected = notificationIsRejected
        }
        
    }
    
    struct SettingsPermissionsNotificationNews: View {
        @Environment(\.openURL) var openURL
        @AppStorage("IsNewsNotifEnabled") var isNewsNotificationEnabled = false
        @State var birthdayCalendarIsEnabled = false
        @State var notificationIsAuthorized = false
        @State var notificationIsRejected = false
        @State var showErrorAlert = false
        @State var errorCode = 0
        @State var shouldRespondToggleChange = true
        var body: some View {
            Group {
                    Toggle(isOn: $isNewsNotificationEnabled, label: {
                        VStack(alignment: .leading) {
                            Text("Settings.notifications.news")
                                .foregroundStyle((!notificationIsAuthorized && notificationIsRejected) ? .secondary : .primary)
                                .onTapGesture {
                                    if (!notificationIsAuthorized && notificationIsRejected) {
#if os(iOS)
                                        if let url = URL(string: UIApplication.openSettingsURLString) {
                                            openURL(url)
                                        }
#else
                                        openURL(.init(string: "x-apple.systempreferences:com.apple.preference.notifications")!)
#endif
                                    }
                                }
//                            if notificationIsRejected {
//                                Text("Settings.notifications.rejected")
//                                    .foregroundStyle(.secondary)
//                                    .font(.caption)
//                            }
                        }
                    })
                    .onChange(of: isNewsNotificationEnabled) {
                        guard shouldRespondToggleChange else {
                            shouldRespondToggleChange = true
                            return
                        }
                        
                        if isNewsNotificationEnabled {
                            Task {
                                if !notificationIsAuthorized && !notificationIsRejected {
                                    do {
                                        let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
                                        notificationIsAuthorized = granted
                                        notificationIsRejected = true
                                        if let token = UserDefaults.standard.data(forKey: "RemoteNotifDeviceToken") {
                                            isNewsNotificationEnabled = true
                                            Task {
                                                if let id = await DoriNotification.registerRemoteNewsNotification(deviceToken: token) {
                                                    UserDefaults.standard.set(id.uuidString, forKey: "NewsNotifID")
                                                } else {
                                                    isNewsNotificationEnabled = false
                                                }
                                            }
                                        }
                                    } catch {
                                        errorCode = -404
                                        showErrorAlert = true
                                        isNewsNotificationEnabled = false
                                    }
                                }
                                
                                if let token = UserDefaults.standard.data(forKey: "RemoteNotifDeviceToken") {
                                    Task {
                                        if let id = await DoriNotification.registerRemoteNewsNotification(deviceToken: token) {
                                            UserDefaults.standard.set(id.uuidString, forKey: "NewsNotifID")
                                        } else {
                                            shouldRespondToggleChange = false
                                            isNewsNotificationEnabled = false
                                            errorCode = -401
                                            showErrorAlert = true
                                        }
                                    }
                                } else {
                                    shouldRespondToggleChange = false
                                    isNewsNotificationEnabled = false
                                    errorCode = -402
                                    showErrorAlert = true
                                }
                            }
                            
                            
                        } else {
                            if let id = UserDefaults.standard.string(forKey: "NewsNotifID"),
                               let uuid = UUID(uuidString: id) {
                                Task {
                                    let success = await DoriNotification.unregisterRemoteNewsNotification(id: uuid)
                                    if !success {
                                        shouldRespondToggleChange = false
                                        isNewsNotificationEnabled = true
                                        errorCode = -403
                                        showErrorAlert = true
                                    }
                                }
                            }
                        }
                    }
                    .disabled(!notificationIsAuthorized && notificationIsRejected)
                    .alert("Settings.notifications.news.error-alert.title", isPresented: $showErrorAlert, actions: {}, message: {
                        Text("Settings.notifications.news.error-alert.message.\(errorCode)")
                    })
            }
            .task {
                let notificationStatus = await UNUserNotificationCenter.current().notificationSettings()
                notificationIsAuthorized = notificationStatus.authorizationStatus == .authorized
                notificationIsRejected = notificationStatus.authorizationStatus == .denied
                
                if notificationIsRejected {
                    isNewsNotificationEnabled = false
                }
            }
        }
    }
    
    struct SettingsPermissionsCalendarBirthdays: View {
        @Environment(\.openURL) var openURL
        @AppStorage("BirthdaysCalendarID") var birthdaysCalendarID = ""
        @State var birthdayCalendarIsEnabled = false
        @State var calendarIsAuthorized = false
        @State var calendarIsRejected = false
        @State var errorCode = 0
        @State var showErrorAlert = false
        var body: some View {
            Group {
                    Toggle(isOn: $birthdayCalendarIsEnabled, label: {
                        Text("Settings.notifications.birthday-calendar")
                            .foregroundStyle((!calendarIsAuthorized && calendarIsRejected) ? .secondary : .primary)
                            .onTapGesture {
                                if (!calendarIsAuthorized && calendarIsRejected) {
#if os(iOS)
                                    if let url = URL(string: UIApplication.openSettingsURLString) {
                                        openURL(url)
                                    }
#else
                                    openURL(.init(string: "x-apple.systempreferences:com.apple.preference.general")!)
#endif
                                }
                            }
                    })
                    .onChange(of: birthdayCalendarIsEnabled) {
                        if birthdayCalendarIsEnabled {
                            guard calendarIsAuthorized else {
                                Task {
                                    do {
                                        let granted = try await EKEventStore().requestFullAccessToEvents()
                                        calendarIsAuthorized = granted
                                        if granted {
                                            try await updateBirthdayCalendar()
                                        }
                                    } catch {
                                        print(error)
                                        errorCode = -501
                                        showErrorAlert = true
                                        birthdayCalendarIsEnabled = false
                                    }
                                }
                                return
                            }
                            Task {
                                do {
                                    try await updateBirthdayCalendar()
                                } catch {
                                    print(error)
                                    errorCode = -502
                                    showErrorAlert = true
                                    birthdayCalendarIsEnabled = false
                                }
                            }
                        } else {
                            try? removeBirthdayCalendar()
                        }
                    }
                    .disabled(calendarIsRejected)
            }
            .task {
                let calendarStatus = EKEventStore.authorizationStatus(for: .event)
                calendarIsAuthorized = calendarStatus == .fullAccess
                calendarIsRejected = calendarStatus == .denied
                
                if calendarIsRejected {
                    birthdayCalendarIsEnabled = false
                }
                birthdayCalendarIsEnabled = !birthdaysCalendarID.isEmpty
            }
            .alert("Settings.notifications.calendar.error-alert.title", isPresented: $showErrorAlert, actions: {}, message: {
                Text("Settings.notifications.calendar.error-alert.message.\(errorCode)")
            })
        }
    }
}
