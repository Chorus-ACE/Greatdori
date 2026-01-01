//===---*- Greatdori! -*---------------------------------------------------===//
//
// EventCalculator.swift
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

struct EventCalculatorView: View {
    @State var eventType: DoriAPI.Events.EventType = .vsLive
    @State var currentEventPoint: Int = 0
    @State var currentChallengePoint: Int = 0
    @State var targetEventPoint: Int? = nil
    
    @State var result: DoriFrontend.Calculator.EventCalculatorResult? = nil
    var body: some View {
        CustomScrollView {
            LazyVStack(spacing: 35, pinnedViews: .sectionHeaders) {
                Section(content: {
                    CustomGroupBox(cornerRadius: 20) {
                        VStack {
                            ListItem(title: {
                                Text("Event-calc.event.type")
                            }, value: {
                                Picker("", selection: $eventType, content: {
                                    ForEach([DoriAPI.Events.EventType.normal, .challengeLive, .vsLive, .liveGoals, .missionLive], id: \.self) { item in
                                        Text(item.localizedString)
                                            .tag(item)
                                    }
                                })
                            })
                            ListItem(title: {
                                Text("Event-calc.event.current-ep")
                            }, value: {
                                HStack {
                                    TextField("", value: $currentEventPoint, formatter: IntFormatter())
                                        .labelsHidden()
                                        .frame(maxWidth: 100)
                                    Stepper("", value: $currentEventPoint, in: 0...Int.max)
                                        .labelsHidden()
                                }
                            })
                            if eventType == .challengeLive {
                                ListItem(title: {
                                    Text("Event-calc.event.current-cp")
                                }, value: {
                                    HStack {
                                        TextField("", value: $currentChallengePoint, formatter: IntFormatter())
                                            .labelsHidden()
                                            .frame(maxWidth: 100)
                                        Stepper("", value: $currentChallengePoint, in: 0...Int.max)
                                            .labelsHidden()
                                    }
                                })
                            }
                            ListItem(title: {
                                VStack(alignment: .leading) {
                                    Text("Event-calc.event.target-ep")
                                    Text("Event-calc.event.target-ep.optional")
                                }
                            }, value: {
                                HStack {
                                    TextField("", value: $targetEventPoint, formatter: IntOptionalFormatter())
                                        .labelsHidden()
                                        .frame(maxWidth: 100)
                                    Stepper("", value: .init(get: { targetEventPoint ?? 0 }, set: { targetEventPoint = $0 }), in: 0...Int.max)
                                        .labelsHidden()
                                }
                            })
                        }
                    }
                    .frame(maxWidth: infoContentMaxWidth)
                }, header: {
                    HStack {
                        Text("Event-calc.event")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    .frame(maxWidth: 615)
                })
            }
        }
    }
}

final class IntOptionalFormatter: Formatter {
    // Int? -> String
    override func string(for obj: Any?) -> String? {
        guard let value = obj as? Int else {
            return ""
        }
        return String(value)
    }
    
    // String -> Int?
    override func getObjectValue(
        _ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
        for string: String,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        
        // 允许空字符串 -> nil
        if string.isEmpty {
            obj?.pointee = nil
            return true
        }
        
        // 只允许 0-9
        guard string.allSatisfy(\.isNumber),
              let value = Int(string) else {
            return false
        }
        
        obj?.pointee = value as NSNumber
        return true
    }
    
    // 输入过程校验（关键：防止输入非法字符）
    override func isPartialStringValid(
        _ partialString: String,
        newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        // 允许清空
        if partialString.isEmpty {
            return true
        }
        
        // 只允许数字
        return partialString.allSatisfy(\.isNumber)
    }
}

final class IntFormatter: Formatter {
    // Int -> String
    override func string(for obj: Any?) -> String? {
        guard let value = obj as? Int else {
            return "0"
        }
        return String(value)
    }
    
    // String -> Int
    override func getObjectValue(
        _ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
        for string: String,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        
        // 不允许空
        guard !string.isEmpty else {
            return false
        }
        
        // 只允许数字
        guard string.allSatisfy(\.isNumber),
              let value = Int(string) else {
            return false
        }
        
        obj?.pointee = value as NSNumber
        return true
    }
    
    // 输入过程校验
    override func isPartialStringValid(
        _ partialString: String,
        newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        
        // 禁止清空
        guard !partialString.isEmpty else {
            return false
        }
        
        // 只允许数字
        return partialString.allSatisfy(\.isNumber)
    }
}
