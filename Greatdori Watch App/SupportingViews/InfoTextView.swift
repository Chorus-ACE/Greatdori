//===---*- Greatdori! -*---------------------------------------------------===//
//
// InfoTextView.swift
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

struct InfoTextView<Content: View> {
    fileprivate var title: String
    fileprivate var content: () -> Content
    
    init(_ titleKey: LocalizedStringResource, content: @escaping () -> Content) {
        self.title = .init(localized: titleKey)
        self.content = content
    }
    @_disfavoredOverload
    init<S: StringProtocol>(_ title: S, content: @escaping () -> Content) {
        self.title = String(title)
        self.content = content
    }
    init<S: StringProtocol>(verbatim title: S, content: @escaping () -> Content) {
        self.init(title, content: content)
    }
}

extension InfoTextView where Content == ModifiedContent<Text, _OpacityEffect> {
    init<S: StringProtocol>(_ titleKey: LocalizedStringResource, text: S?) {
        self.init(String(localized: titleKey), text: text)
    }
    @_disfavoredOverload
    init<S1: StringProtocol, S2: StringProtocol>(_ title: S1, text: S2?) {
        if let text {
            self.init(title) {
                Text(text).modifier(_OpacityEffect(opacity: 0.6))
            }
        } else {
            self.init(verbatim: "__EmptyView__", text: "")
        }
    }
    init<S1: StringProtocol, S2: StringProtocol>(verbatim title: S1, text: S2?) {
        self.init(title, text: text)
    }
    
    init<S: StringProtocol>(_ titleKey: LocalizedStringResource, text: LocalizedData<S>?) {
        self.init(String(localized: titleKey), text: text)
    }
    @_disfavoredOverload
    init<S1: StringProtocol, S2: StringProtocol>(_ title: S1, text: LocalizedData<S2>?) {
        if let text = text?.forPreferredLocale() {
            self.init(title, text: text)
        } else {
            self.init(verbatim: "__EmptyView__", text: "")
        }
    }
    init<S1: StringProtocol, S2: StringProtocol>(verbatim title: S1, text: LocalizedData<S2>?) {
        self.init(title, text: text)
    }
}

extension InfoTextView where Content == ModifiedContent<Text, _OpacityEffect> {
    init(_ titleKey: LocalizedStringResource, date: Date) {
        self.init(String(localized: titleKey), date: date)
    }
    @_disfavoredOverload
    init<S: StringProtocol>(_ title: S, date: Date) {
        self.init(title) {
            Text({
                let df = DateFormatter()
                df.dateStyle = .medium
                df.timeStyle = .short
                return df.string(from: date)
            }())
            .modifier(_OpacityEffect(opacity: 0.6))
        }
    }
    init<S: StringProtocol>(verbatim title: S, date: Date) {
        self.init(title, date: date)
    }
    
    init(_ titleKey: LocalizedStringResource, date: LocalizedData<Date>) {
        self.init(String(localized: titleKey), date: date)
    }
    @_disfavoredOverload
    init<S: StringProtocol>(_ title: S, date: LocalizedData<Date>) {
        if let date = date.forPreferredLocale() {
            self.init(title, date: date)
        } else {
            self.init(verbatim: "__EmptyView__", text: "")
        }
    }
    init<S: StringProtocol>(verbatim title: S, date: LocalizedData<Date>) {
        self.init(title, date: date)
    }
}

extension InfoTextView: View {
    var body: some View {
        if _fastPath(title != "__EmptyView__") {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                content()
                    .font(.system(size: 14))
            }
            .accessibilityElement(children: .combine)
        } else {
            EmptyView()
        }
    }
}
