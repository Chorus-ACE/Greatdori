//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardDetailStatsView.swift
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
import SDWebImageSwiftUI


// MARK: CardDetailStatsView
struct CardDetailStatsView: View {
    var card: Card
    @State var tab: Int = 0
    @State var level: Float = 1
    @State var masterRank: Float = 4
    @State var episodes: Float = 2
    @State var trained: Bool = false
    @State var stat: CardStatValue = .zero
    
    @State private var allSkills: [Skill] = []
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                //                CustomGroupBox {
                Group {
                    if tab != 3 {
                        if tab == 2 {
                            CustomGroupBox(cornerRadius: 20) {
                                VStack {
                                    Group {
                                        ListItem(title: {
                                            Text("Card.stats.level")
                                                .bold()
                                        }, value: {
                                            Text(tab == 0 ? "\(card.stat.minimumLevel ?? 1)" : tab == 1 ? "\(card.stat.maximumLevel ?? 60)" : ("\(Int(level))"))
                                                .contentTransition(.numericText())
                                                .animation(.default, value: stat)
                                            Stepper("", value: $level, in: Float(card.stat.minimumLevel ?? 1)...Float(card.stat.maximumLevel ?? 60), step: 1)
                                                .labelsHidden()
                                        })
                                        .accessibilityElement()
                                        .accessibilityLabel(Text("Card.stats.level"))
                                        .accessibilityValue("\(Int(level))")
                                        Slider(value: $level, in: Float(card.stat.minimumLevel ?? 1)...Float(card.stat.maximumLevel ?? 60), step: 1, label: {
                                            Text("")
                                        })
                                        .labelsHidden()
                                        Divider()
                                    }
                                    
                                    Group {
                                        ListItem(title: {
                                            Text("Card.stats.master-rank")
                                                .bold()
                                        }, value: {
                                            Text("\(Int(masterRank))")
                                                .contentTransition(.numericText())
                                                .animation(.default, value: stat)
                                            Stepper("", value: $masterRank, in: 0...4, step: 1)
                                                .labelsHidden()
                                        })
                                        Divider()
                                    }
                                    
                                    if !card.episodes.isEmpty {
                                        Group {
                                            ListItem(title: {
                                                Text("Card.stats.episode")
                                                    .bold()
                                            }, value: {
                                                Text("\(Int(episodes))")
                                                Stepper("", value: $episodes, in: 0...Float(card.episodes.count), step: 1)
                                                    .labelsHidden()
                                            })
                                            Divider()
                                        }
                                    }
                                    
                                    Group {
                                        ListItem(title: {
                                            Text("Card.stats.trained")
                                                .bold()
                                        }, value: {
                                            Toggle(isOn: $trained, label: {
                                                Text("")
                                            })
                                            .labelsHidden()
                                            .toggleStyle(.switch)
                                        })
                                    }
                                }
                            }
                        }
                        CustomGroupBox(cornerRadius: 20) {
                            VStack {
                                Group {
                                    if tab != 2 {
                                        Group {
                                            ListItem(title: {
                                                Text("Card.stats.level")
                                                    .bold()
                                            }, value: {
                                                Text(tab == 0 ? "\(card.stat.minimumLevel ?? 1)" : tab == 1 ? "\(card.stat.maximumLevel ?? 60)" : ("\(Int(level))"))
                                                    .contentTransition(.numericText())
                                                    .animation(.default, value: stat)
                                            })
                                            Divider()
                                        }
                                    }
                                    
                                    Group {
                                        ListItem(title: {
                                            Text("Card.stats.performance")
                                                .bold()
                                        }, value: {
                                            Text("\(stat.performance)")
                                        })
                                        Divider()
                                    }
                                    
                                    Group {
                                        ListItem(title: {
                                            Text("Card.stats.technique")
                                                .bold()
                                        }, value: {
                                            Text("\(stat.technique)")
                                        })
                                        Divider()
                                    }
                                    
                                    Group {
                                        ListItem(title: {
                                            Text("Card.stats.visual")
                                                .bold()
                                        }, value: {
                                            Text("\(stat.visual)")
                                        })
                                        Divider()
                                    }
                                    
                                    Group {
                                        ListItem(title: {
                                            Text("Card.stats.total")
                                                .bold()
                                        }, value: {
                                            Text("\(stat.total)")
                                        })
                                    }
                                }
                            }
                            .contentTransition(.numericText())
                            .animation(.default, value: stat)
                        }
                    } else {
                        CustomGroupBox(cornerRadius: 20) {
                            VStack {
                                Group {
                                    ListItem(title: {
                                        Text("Card.stats.name")
                                            .bold()
                                    }, value: {
                                        //                                        Text("\(card.name)")
                                        MultilingualText(card.skillName)
                                    })
                                }
                                
                                // MARK: Skill
                                if let skill = allSkills.first(where: { $0.id == card.skillID }) {
                                    Divider()
                                    
                                    Group {
                                        ListItem(title: {
                                            Text("Card.stats.effect")
                                                .bold()
                                        }, value: {
                                            //                                        Text("\(card.name)")
                                            MultilingualText(skill.simpleDescription)
                                            //                                            skill.description
                                        })
                                        Divider()
                                    }
                                    //
                                    Group {
                                        ListItem(title: {
                                            Text("Card.stats.full-effect")
                                                .bold()
                                        }, value: {
                                            //                                        Text("\(card.name)")
                                            MultilingualText(skill.description)
                                            //                                            skill.description
                                        })
                                        Divider()
                                    }
                                    
                                    Group {
                                        ListItem(title: {
                                            Text("Card.stats.duration")
                                                .bold()
                                        }, value: {
                                            Text((skill.duration).map{String($0)}.joined(separator: ", "))
                                            //                                            Text((skill.duration).map(String($0)).joined(separator: ", "))
                                        })
                                    }
                                }
                                
                            }
                        }
                    }
                }
                .frame(maxWidth: infoContentMaxWidth)
                .onAppear {
                    level = Float(card.stat.maximumLevel ?? 60)
                    episodes = Float(card.episodes.count)
                    updateStatsData()
                }
                .onChange(of: tab) {
                    updateStatsData()
                }
                .onChange(of: level) {
                    updateStatsData()
                }
                .onChange(of: episodes) {
                    updateStatsData()
                }
                .onChange(of: masterRank) {
                    updateStatsData()
                }
                .onChange(of: trained) {
                    updateStatsData()
                }
            }, header: {
                HStack {
                    Text("Card.stats")
                        .font(.title2)
                        .bold()
                    DetailSectionOptionPicker(selection: $tab, options: [0, 1, 2, 3], labels: [0: String(localized: "Card.stats.min"), 1: String(localized: "Card.stats.max"), 2: String(localized: "Card.stats.custom"), 3: String(localized: "Card.stats.skill")])
                    Spacer()
                }
                .frame(maxWidth: 615)
            })
        }
        .task {
            // Load skills asynchronously once when the view appears
            if allSkills.isEmpty {
                if let fetched = await Skill.all() {
                    allSkills = fetched
                }
            }
        }
    }
    
    func updateStatsData() {
        stat = switch tab {
        case 0: card.stat.forMinimumLevel() ?? .zero
        case 1: card.stat.maximumValue(rarity: card.rarity) ?? .zero
        default: card.stat.calculated(
            level: Int(level),
            rarity: card.rarity,
            masterRank: Int(masterRank),
            viewedStoryCount: Int(episodes),
            trained: trained
        ) ?? .zero
        }
    }
}
