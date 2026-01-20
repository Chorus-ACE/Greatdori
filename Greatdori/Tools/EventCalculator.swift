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
import SymbolAvailability

struct EventCalculatorView: View {
    @State var isChallengeLive: Bool = false
    @State var currentEventPoint: Int = 0
    @State var currentChallengePoint: Int = 0
    @State var targetEventPoint: Int? = nil
    
    @State var epGainPerFlame: Int = 5
    @State var epGainPerCP: Int = 30
    
    @State var automaticCalculateNaturalFlames: Bool = true
    @State var naturalFlamesRemainingHours: Double = 198
    @State var naturalFlamesEfficiency: Double = 87.5
    @State var naturalFlames: Int = 347
    @State var currentLocaleRemainingHours: Int = 198
    
    @State var zeroFlames: Int = 0
    @State var flamesFromAds: Int = 0
    @State var flamesFromDrinks: Int = 0
    @State var flamesFromOther: Int = 0
    
    @State var flameUse: Int = 1
    @State var cpUse: Int = 200
    @State var gameplayTime: Double = 2
        
    @State var result: DoriFrontend.Calculator.EventCalculatorResult? = nil
    
    let durationFormatStyle: Duration.UnitsFormatStyle = .units(allowed: [.days, .hours, .minutes], width: .wide)
    var body: some View {
        CustomScrollView {
            LazyVStack(pinnedViews: .sectionHeaders) {
                // MARK: Event
                Section(content: {
                    CustomGroupBox(cornerRadius: 20) {
                        VStack {
                            Group {
                                ListItem(title: {
                                    Text("Event-calc.event.is-challenge-live")
                                }, value: {
                                    Toggle("", isOn: $isChallengeLive)
                                        .toggleStyle(.switch)
                                        .labelsHidden()
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
                                if isChallengeLive {
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
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                            .bold(false)
                                    }
                                }, value: {
                                    HStack {
                                        TextField("", value: $targetEventPoint, formatter: IntOptionalFormatter(), prompt: Text("Event-calc.event.target-ep.prompt"))
                                            .labelsHidden()
                                            .frame(maxWidth: 100)
                                        Stepper("", value: .init(get: { targetEventPoint ?? 0 }, set: { targetEventPoint = $0 }), in: 0...Int.max)
                                            .labelsHidden()
                                    }
                                })
                            }
                            .insert { Divider() }
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
                
                DetailSectionsSpacer(height: 20)
                
                // MARK: EP Gain
                Section(content: {
                    CustomGroupBox(cornerRadius: 20) {
                        VStack {
                            Group {
                                ListItem(title: {
                                    VStack(alignment: .leading) {
                                        Text("Event-calc.ep-gain.by-flames")
                                        Group {
                                            Text("Event-calc.ep-gain.by-flames.description")
                                            Text("Event-calc.zero-flames-equivalent")
                                        }
                                        .foregroundStyle(.secondary)
                                        .font(.caption)
                                        .bold(false)
                                    }
                                }, value: {
                                    HStack {
                                        TextField("", value: $epGainPerFlame, formatter: NumberFormatter())
                                            .labelsHidden()
                                            .frame(maxWidth: 100)
                                        Stepper("", value: $epGainPerFlame, in: 0...Int.max)
                                            .labelsHidden()
                                    }
                                })
                                if isChallengeLive {
                                    ListItem(title: {
                                        VStack(alignment: .leading) {
                                            Text("Event-calc.ep-gain.by-cp")
                                            Group {
                                                Text("Event-calc.ep-gain.by-cp.description")
                                                Text("Event-calc.ep-gain.by-cp.description.devision")
                                            }
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                            .bold(false)
                                        }
                                    }, value: {
                                        HStack {
                                            TextField("", value: $epGainPerCP, formatter: NumberFormatter())
                                                .labelsHidden()
                                                .frame(maxWidth: 100)
                                            Stepper("", value: $epGainPerCP, in: 0...Int.max)
                                                .labelsHidden()
                                        }
                                    })
                                }
                            }
                            .insert { Divider() }
                        }
                    }
                    .frame(maxWidth: infoContentMaxWidth)
                }, header: {
                    HStack {
                        Text("Event-calc.ep-gain")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    .frame(maxWidth: 615)
                })
                
                DetailSectionsSpacer(height: 20)
                
                // MARK: Flames
                Section(content: {
                    CustomGroupBox(cornerRadius: 20) {
                        VStack {
                            Group {
                                ListItem(title: {
                                    Text("Event-calc.flames.calculation")
                                }, value: {
                                    Picker("", selection: $automaticCalculateNaturalFlames, content: {
                                        Text("Event-calc.flames.calculation.automatic")
                                            .tag(true)
                                        Text("Event-calc.flames.calculation.manual")
                                            .tag(false)
                                    })
                                    .labelsHidden()
                                })
                                if automaticCalculateNaturalFlames {
                                    ListItem(title: {
                                        HStack {
                                            Text("Event-calc.flames.hours-remain")
                                            Button(action: {
                                                naturalFlamesRemainingHours = Double(currentLocaleRemainingHours)
                                            }, label: {
                                                Image(systemName: .clock)
                                                    .bold(false)
                                            })
                                            .buttonStyle(.plain)
                                        }
                                    }, value: {
                                        HStack {
                                            TextField("", value: $naturalFlamesRemainingHours, formatter: DoubleFormatter())
                                                .labelsHidden()
                                                .frame(maxWidth: 100)
                                            Stepper("", value: $naturalFlamesRemainingHours, in: 0...Double(Int.max))
                                                .labelsHidden()
                                        }
                                    })
                                    ListItem(title: {
                                        HStack {
                                            Text("Event-calc.flames.efficiency")
                                            SettingsDocumentButton(document: "EventCalcEfficiency", label: {
                                                Image(systemName: .questionmarkCircle)
                                            })
                                            .bold(false)
                                            .buttonStyle(.plain)
                                        }
                                    }, value: {
                                        HStack {
                                            TextField("", value: $naturalFlamesEfficiency, formatter: DoubleFormatter())
                                                .labelsHidden()
                                                .frame(maxWidth: 100)
                                            
                                            Stepper("", value: $naturalFlamesEfficiency, in: 0...Double(Int.max), step: 1)
                                                .labelsHidden()
                                        }
                                    })
                                    HStack {
                                        Text("Event-calc.flames.natural-flames.\(naturalFlames)")
                                        Spacer()
                                    }
                                } else {
                                    ListItem(title: {
                                        Text("Event-calc.flames.natural-flames")
                                    }, value: {
                                        HStack {
                                            TextField("", value: $naturalFlames, formatter: NumberFormatter())
                                                .labelsHidden()
                                                .frame(maxWidth: 100)
                                            Stepper("", value: $naturalFlames, in: 0...Int.max)
                                                .labelsHidden()
                                        }
                                    })
                                }
                            }
                            .insert { Divider() }
                        }
                    }
                    .frame(maxWidth: infoContentMaxWidth)
                    
                    CustomGroupBox(cornerRadius: 20) {
                        VStack {
                            Group {
                                ListItem(title: {
                                    VStack(alignment: .leading) {
                                        Text("Event-calc.flames.zero-flame")
                                        Group {
                                            Text("Event-calc.flames.zero-flame.description")
                                            Text("Event-calc.zero-flames-equivalent")
                                        }
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .bold(false)
                                    }
                                }, value: {
                                    HStack {
                                        TextField("", value: $zeroFlames, formatter: NumberFormatter())
                                            .labelsHidden()
                                            .frame(maxWidth: 100)
                                        Stepper("", value: $zeroFlames, in: 0...Int.max)
                                            .labelsHidden()
                                    }
                                })
                                ListItem(title: {
                                    VStack(alignment: .leading) {
                                        Text("Event-calc.flames.ads")
                                        Text("Event-calc.flames.ads.description")
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                            .bold(false)
                                    }
                                }, value: {
                                    HStack {
                                        TextField("", value: $flamesFromAds, formatter: IntFormatter())
                                            .labelsHidden()
                                            .frame(maxWidth: 100)
                                        Stepper("", value: $flamesFromAds, in: 0...Int.max)
                                            .labelsHidden()
                                    }
                                })
                                ListItem(title: {
                                    VStack(alignment: .leading) {
                                        Text("Event-calc.flames.drinks")
                                        Text("Event-calc.flames.drinks.description")
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                            .bold(false)
                                    }
                                }, value: {
                                    HStack {
                                        TextField("", value: $flamesFromDrinks, formatter: IntFormatter())
                                            .labelsHidden()
                                            .frame(maxWidth: 100)
                                        Stepper("", value: $flamesFromDrinks, in: 0...Int.max)
                                            .labelsHidden()
                                    }
                                })
                                ListItem(title: {
                                    VStack(alignment: .leading) {
                                        Text("Event-calc.flames.other")
                                        Text("Event-calc.flames.other.description")
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                            .bold(false)
                                    }
                                }, value: {
                                    HStack {
                                        TextField("", value: $flamesFromOther, formatter: IntFormatter())
                                            .labelsHidden()
                                            .frame(maxWidth: 100)
                                        Stepper("", value: $flamesFromOther, in: 0...Int.max)
                                            .labelsHidden()
                                    }
                                })
                                
                            }
                            .insert { Divider() }
                        }
                    }
                    .frame(maxWidth: infoContentMaxWidth)
                }, header: {
                    HStack {
                        Text("Event-calc.flames")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    .frame(maxWidth: 615)
                })
                
                DetailSectionsSpacer(height: 20)
                
                // MARK: Gameplay
                Section(content: {
                    CustomGroupBox(cornerRadius: 20) {
                        VStack {
                            Group {
                                ListItem(title: {
                                    VStack(alignment: .leading) {
                                        Text("Event-calc.gameplay.flame")
                                        Text("Event-calc.gameplay.flame.description")
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                            .bold(false)
                                    }
                                }, value: {
                                    Picker("", selection: $flameUse, content: {
                                        ForEach([1, 2, 3], id: \.self) { item in
                                            Text("\(item)")
                                                .tag(item)
                                        }
                                    })
                                    .labelsHidden()
                                })
                                
                                if isChallengeLive {
                                    ListItem(title: {
                                        VStack(alignment: .leading) {
                                            Text("Event-calc.gameplay.cp")
                                            Text("Event-calc.gameplay.cp.description")
                                                .foregroundStyle(.secondary)
                                                .font(.caption)
                                                .bold(false)
                                        }
                                    }, value: {
                                        Picker("", selection: $cpUse, content: {
                                            ForEach([200, 400, 800], id: \.self) { item in
                                                Text("\(item)")
                                                    .tag(item)
                                            }
                                        })
                                        .labelsHidden()
                                    })
                                }
                                
                                ListItem(title: {
                                    VStack(alignment: .leading) {
                                        Text("Event-calc.gameplay.time")
                                        Text("Event-calc.gameplay.time.description")
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                            .bold(false)
                                    }
                                }, value: {
                                    HStack {
                                        TextField("", value: $gameplayTime, formatter: DoubleFormatter())
                                            .labelsHidden()
                                            .frame(maxWidth: 100)
                                        
                                        Stepper("", value: $gameplayTime, in: 0...Double(Int.max), step: 1)
                                            .labelsHidden()
                                    }
                                })
                            }
                            .insert { Divider() }
                        }
                    }
                    .frame(maxWidth: infoContentMaxWidth)
                }, header: {
                    HStack {
                        Text("Event-calc.gameplay")
                            .font(.title2)
                            .bold()
                        Spacer()
                    }
                    .frame(maxWidth: 615)
                })
                
                if let result {
                    DetailSectionsSpacer(height: 20)
                    
                    // MARK: Result
                    Section(content: {
                        // Final Result
                        CustomGroupBox(cornerRadius: 20) {
                            VStack {
                                Group {
                                    ListItem(title: {
                                        Text("Event-calc.result.final.ep")
                                    }, value: {
                                        Text("\(result.totalEventPoints)")
                                    })
                                    if let totalChallengePoints = result.totalChallengePoints {
                                        ListItem(title: {
                                            Text("Event-calc.result.final.cp")
                                        }, value: {
                                            Text("\(totalChallengePoints)")
                                        })
                                    }
                                }
                                .insert { Divider() }
                            }
                        }
                        .frame(maxWidth: infoContentMaxWidth)
                        
                        // Goal
                        if let goal = result.goal {
                            CustomGroupBox(cornerRadius: 20) {
                                VStack {
                                    Group {
                                        ListItem(title: {
                                            Text("Event-calc.result.goal")
                                        }, value: {
                                            Text(goal == .reached ? "Event-calc.result.goal.reached" : "Event-calc.result.goal.not-reached")
                                        })
                                        if case .notReached(let difference) = goal {
                                            ListItem(title: {
                                                Text("Event-calc.result.goal.ep")
                                            }, value: {
                                                Text("\(difference.eventPoint)")
                                            })
                                            ListItem(title: {
                                                Text("Event-calc.result.goal.flames")
                                            }, value: {
                                                Text("\(difference.eventPoint)")
                                            })
                                            ListItem(title: {
                                                Text("Event-calc.result.goal.gameplay.flame")
                                            }, value: {
                                                Text("\(difference.gameplayWithFlame)")
                                            })
                                            ListItem(title: {
                                                Text("Event-calc.result.goal.gametime.flame")
                                            }, value: {
                                                Text(difference.gameTimeWithFlame.formatted(durationFormatStyle))
                                            })
                                            ListItem(title: {
                                                Text("Event-calc.result.goal.gameplay.flameless")
                                            }, value: {
                                                Text("\(difference.gameplayWithoutFlame)")
                                            })
                                            ListItem(title: {
                                                Text("Event-calc.result.goal.gametime.flameless")
                                            }, value: {
                                                Text(difference.gameTimeWithoutFlame.formatted(durationFormatStyle))
                                            })
                                        }
                                    }
                                    .insert { Divider() }
                                }
                            }
                            .frame(maxWidth: infoContentMaxWidth)
                        }
                        
                        
                        // Details
                        CustomGroupBox(cornerRadius: 20) {
                            VStack {
                                Group {
                                    ListItem(title: {
                                        Text("Event-calc.result.details.flames")
                                    }, value: {
                                        Text("\(result.consumedFlames)")
                                    })
                                    ListItem(title: {
                                        Text("Event-calc.result.details.eq-flames")
                                    }, value: {
                                        Text("\(result.equivalentFlames)")
                                    })
                                    ListItem(title: {
                                        if result.eventPointsGainFromChallengePoints != nil {
                                            Text("Event-calc.result.details.ep-gain.flames")
                                        } else {
                                            Text("Event-calc.result.details.ep-gain")
                                        }
                                    }, value: {
                                        Text("\(result.eventPointsGainFromFlame)")
                                    })
                                    if let eventPointsGainFromChallengePoints = result.eventPointsGainFromChallengePoints {
                                        ListItem(title: {
                                            Text("Event-calc.result.details.ep-gain.cp")
                                        }, value: {
                                            Text("\(eventPointsGainFromChallengePoints)")
                                        })
                                    }
                                }
                                .insert { Divider() }
                            }
                        }
                        .frame(maxWidth: infoContentMaxWidth)
                        
                        // Gameplay
                        CustomGroupBox(cornerRadius: 20) {
                            VStack {
                                Group {
                                    if result.gameplayByChallengePointsCount != nil {
                                        ListItem(title: {
                                            Text("Event-calc.result.gameplay.games.flames")
                                        }, value: {
                                            Text("\(result.gameplayByFlamesCount)")
                                        })
                                        ListItem(title: {
                                            Text("Event-calc.result.gameplay.gametime.flames")
                                        }, value: {
                                            Text("\(result.gameplayByFlamesDuration.formatted(durationFormatStyle))")
                                        })
                                        if let gameplayByChallengePointsCount = result.gameplayByChallengePointsCount {
                                            ListItem(title: {
                                                Text("Event-calc.result.gameplay.games.cp")
                                            }, value: {
                                                Text("\(gameplayByChallengePointsCount)")
                                            })
                                        }
                                        if let gameplayByChallengePointsDuration = result.gameplayByChallengePointsDuration {
                                            ListItem(title: {
                                                Text("Event-calc.result.gameplay.gametime.cp")
                                            }, value: {
                                                Text("\(gameplayByChallengePointsDuration.formatted(durationFormatStyle))")
                                            })
                                        }
                                    }
                                    ListItem(title: {
                                        if result.gameplayByChallengePointsCount != nil {
                                            Text("Event-calc.result.gameplay.games.total")
                                        } else {
                                            Text("Event-calc.result.gameplay.games")
                                        }
                                    }, value: {
                                        Text("\(result.totalGameplayCount)")
                                    })
                                    ListItem(title: {
                                        if result.gameplayByChallengePointsCount != nil {
                                            Text("Event-calc.result.gameplay.gametime.total")
                                        } else {
                                            Text("Event-calc.result.gameplay.gametime")
                                        }
                                    }, value: {
                                        Text("\(result.totalGameplayDuration.formatted(durationFormatStyle))")
                                    })

                                }
                                .insert { Divider() }
                            }
                        }
                        .frame(maxWidth: infoContentMaxWidth)
                    }, header: {
                        HStack {
                            Text("Event-calc.result")
                                .font(.title2)
                                .bold()
                            Spacer()
                        }
                        .frame(maxWidth: 615)
                    })
                }
            }
            .navigationTitle("Event-calc")
            .onAppear {
                if DoriLocale.primaryLocale == .cn {
                    naturalFlamesEfficiency = 100
                }
                
                DoriCache.withCache(id: "Home_LatestEvents", trait: .realTime) {
                    await DoriFrontend.Events.localizedLatestEvent()
                } .onUpdate {
                    if let localCurrentEvent = $0?.forPreferredLocale(allowsFallback: false) {
                        let startDate = localCurrentEvent.startAt.forPreferredLocale(allowsFallback: false)
                        let endDate = localCurrentEvent.endAt.forPreferredLocale(allowsFallback: false)
                        let current = Date.now
                        
                        if let startDate, let endDate {
                            if current > startDate && current < endDate {
                                currentLocaleRemainingHours = Int(endDate.timeIntervalSince(current) / 3600)
                                naturalFlamesRemainingHours = Double(currentLocaleRemainingHours)
                            }
                        }
                    }
                }
            }
            .onChange(of: automaticCalculateNaturalFlames, naturalFlamesRemainingHours, naturalFlamesEfficiency) {
                naturalFlames = Int(naturalFlamesRemainingHours * 2 * naturalFlamesEfficiency / 100)
            }
            .onChange(of: isChallengeLive, currentEventPoint, currentChallengePoint, targetEventPoint, epGainPerFlame, epGainPerCP, naturalFlames, zeroFlames, flamesFromAds, flamesFromDrinks, flamesFromOther, flameUse, cpUse, gameplayTime, initial: true) {
                let flamesFromBroadSenseOthers = flamesFromAds + flamesFromDrinks + flamesFromOther
                let eventType: DoriAPI.Events.EventType = isChallengeLive ? .challengeLive : .normal
                let duration = Duration.seconds(gameplayTime*60)
                
                result = DoriFrontend.Calculator.calculateEvent(.init(eventType: eventType, currentEventPoint: currentEventPoint, currentChallengePoint: currentChallengePoint, targetEventPoint: targetEventPoint, eventPointsGainPerFlame: epGainPerFlame, eventPointsGainPerChallengePoint: epGainPerCP, naturalFlamesCount: naturalFlames, otherFlamesCount: flamesFromBroadSenseOthers, zeroFlamesGameplayCount: zeroFlames, flameCostPerGameplay: flameUse, challengePointCostPerGameplay: cpUse, gameplayDuration: duration))
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

final class DoubleFormatter: Formatter {
    
    // Double -> String（关键修改在这里）
    override func string(for obj: Any?) -> String? {
        guard let value = obj as? Double else {
            return "0"
        }
        
        // 小数部分为 0 时，显示为整数
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        }
        
        return String(value)
    }
    
    // String -> Double
    override func getObjectValue(
        _ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?,
        for string: String,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        
        guard !string.isEmpty else { return false }
        guard string != "." else { return false }
        
        guard let value = Double(string) else {
            return false
        }
        
        obj?.pointee = value as NSNumber
        return true
    }
    
    // 输入中间态校验
    override func isPartialStringValid(
        _ partialString: String,
        newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?,
        errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?
    ) -> Bool {
        
        guard !partialString.isEmpty else { return false }
        
        let allowed = CharacterSet(charactersIn: "0123456789.")
        guard partialString.unicodeScalars.allSatisfy(allowed.contains) else {
            return false
        }
        
        // 只允许一个小数点
        return partialString.filter { $0 == "." }.count <= 1
    }
}

