//===---*- Greatdori! -*---------------------------------------------------===//
//
// SettingsLocaleView.swift
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

struct SettingsLocaleView: View {
    var body: some View {
//#if os(iOS)
//        Section(content: {
//            Group {
//                SettingsPrimaryAndSecondaryLocalePicker()
//                SettingsBirthdayTimeZonePicker()
//            }
//        }, header: {
//            Text("Settings.locale")
//        })
//#else
        Group {
            Section {
                SettingsPrimaryAndSecondaryLocalePicker()
            }
            Section {
                SettingsBirthdayTimeZonePicker()
            }
        }
        .navigationTitle("Settings.locale")
//#endif
    }
    
    
    struct SettingsPrimaryAndSecondaryLocalePicker: View {
        @State var primaryLocale = DoriLocale.jp
        @State var secondaryLocale = DoriLocale.en
        var body: some View {
            Group {
                LocalePicker($primaryLocale) {
                    Text("Settings.locale.primary-locale")
                }
                .onChange(of: primaryLocale, { oldValue, newValue in
                    if newValue == DoriLocale.secondaryLocale {
                        DoriLocale.secondaryLocale = oldValue
                        secondaryLocale = DoriLocale.secondaryLocale
                    }
                    DoriLocale.primaryLocale = newValue
                })
                
                LocalePicker($secondaryLocale) {
                    Text("Settings.locale.secondary-locale")
                }
                .onChange(of: secondaryLocale, { oldValue, newValue in
                    if newValue == DoriLocale.primaryLocale {
                        DoriLocale.primaryLocale = oldValue
                        primaryLocale = DoriLocale.primaryLocale
                    }
                    DoriLocale.secondaryLocale = newValue
                })
            }
            .onAppear {
                primaryLocale = DoriLocale.primaryLocale
                secondaryLocale = DoriLocale.secondaryLocale
            }
        }
    }
    
    struct SettingsBirthdayTimeZonePicker: View {
        @State var birthdayTimeZone: BirthdayTimeZone = .JST
        var body: some View {
            Picker(selection: $birthdayTimeZone, content: {
                VStack(alignment: .leading) {
                    Text("Settings.birthday-time-zone.selection.adaptive")
                    Text(verbatim: "\(TimeZone.current.localizedName(for: .generic, locale: Locale.current) ?? "") (\(timeZoneUTCOffsetDescription(for: TimeZone.current)))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(BirthdayTimeZone.adaptive)
                
                VStack(alignment: .leading) {
                    Text("Settings.birthday-time-zone.selection.JST")
                    Text(timeZoneDifference(to: getBirthdayTimeZone(from: .JST)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(BirthdayTimeZone.JST)
                
                VStack(alignment: .leading) {
                    Text("Settings.birthday-time-zone.selection.UTC")
                    Text(timeZoneDifference(to: getBirthdayTimeZone(from: .UTC)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(BirthdayTimeZone.UTC)
                
                VStack(alignment: .leading) {
                    Text("Settings.birthday-time-zone.selection.CST")
                    Text(timeZoneDifference(to: getBirthdayTimeZone(from: .CST)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(BirthdayTimeZone.CST)
                
                VStack(alignment: .leading) {
                    Text(getBirthdayTimeZone(from: .PT).isDaylightSavingTime() ? "Settings.birthday-time-zone.selection.PT.PDT" : "Settings.birthday-time-zone.selection.PT.PST")
                    Text(timeZoneDifference(to: getBirthdayTimeZone(from: .PT)))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .tag(BirthdayTimeZone.PT)
            }, label: {
                VStack(alignment: .leading) {
                    Text("Settings.birthday-time-zone")
                    Text("Settings.birthday-time-zone.description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }, optionalCurrentValueLabel: {
                switch birthdayTimeZone {
                case .adaptive:
                    Text("Settings.birthday-time-zone.selection.adaptive.abbr")
                case .JST:
                    Text("Settings.birthday-time-zone.selection.JST.abbr")
                case .UTC:
                    Text("Settings.birthday-time-zone.selection.UTC.abbr")
                case .CST:
                    Text("Settings.birthday-time-zone.selection.CST.abbr")
                case .PT:
                    Text("Settings.birthday-time-zone.selection.PT.abbr")
                }
            })
            .wrapIf(true, in: { content in
#if os(iOS)
                content
                    .pickerStyle(.navigationLink)
#else
                content
#endif
            })
            .onAppear {
                birthdayTimeZone = BirthdayTimeZone(rawValue: UserDefaults.standard.string(forKey: "BirthdayTimeZone") ?? "JST") ?? .JST
            }
            .onChange(of: birthdayTimeZone) {
                UserDefaults.standard.setValue(birthdayTimeZone.rawValue, forKey: "BirthdayTimeZone")
            }
        }
    }
}



enum BirthdayTimeZone: String, CaseIterable {
    case adaptive
    case JST
    case UTC
    case CST
    case PT
}
