//===---*- Greatdori! -*---------------------------------------------------===//
//
// Live2DViewer.swift
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

struct Live2DViewerView: View {
    private let itemType: [LocalizedStringKey] = [
        "Live2d-viewer.type.card",
        "Live2d-viewer.type.costume",
        "Live2d-viewer.type.seasonal-costume"
    ]
    @State private var selectedItemTypeIndex = 0
    @State private var selectedCard: PreviewCard?
    @State private var selectedCharacter: PreviewCharacter?
    @State private var selectedCostume: PreviewCostume?
    @State private var informationIsLoading = false
    @State private var seasonalCostumes: [SeasonCostume]?
    var body: some View {
        ScrollView {
            HStack {
                Spacer(minLength: 0)
                VStack {
                    CustomGroupBox {
                        VStack {
                            ListItem(title: {
                                Text("Live2d-viewer.type")
                                    .bold()
                            }, value: {
                                Picker("", selection: $selectedItemTypeIndex, content: {
                                    ForEach(itemType.indices, id: \.self) { itemIndex in
                                        Text(itemType[itemIndex])
                                            .tag(itemIndex)
                                    }
                                })
                                .labelsHidden()
                            })
                            Divider()
                            if selectedItemTypeIndex == 0 {
                                ListItem {
                                    Text("Live2d-viewer.card")
                                        .bold()
                                } value: {
                                    ItemSelectorButton(selection: $selectedCard)
                                        .onChange(of: selectedCard) {
                                            updateDestination()
                                        }
                                }
                            } else if selectedItemTypeIndex == 1 {
                                ListItem {
                                    Text("Live2d-viewer.costume")
                                        .bold()
                                } value: {
                                    ItemSelectorButton(selection: $selectedCostume)
                                }
                            } else if selectedItemTypeIndex == 2 {
                                ListItem {
                                    Text("Live2d-viewer.character")
                                        .bold()
                                } value: {
                                    ItemSelectorButton(selection: $selectedCharacter)
                                        .onChange(of: selectedCharacter) {
                                            updateDestination()
                                        }
                                }
                            }
                        }
                    }
                    DetailSectionsSpacer()
                    
                    
                    if informationIsLoading {
                        CustomGroupBox {
                            HStack {
                                Spacer()
                                ProgressView()
                                Spacer()
                            }
                        }
                    } else {
                        if let selectedCostume, [0, 1].contains(selectedItemTypeIndex) {
                            NavigationLink(destination: {
                                Live2DDetailView(costume: selectedCostume)
                            }, label: {
                                CostumeInfo(selectedCostume)
                            })
                            .buttonStyle(.plain)
                        } else if let seasonalCostumes {
                            ForEach(seasonalCostumes, id: \.self) { costume in
                                NavigationLink(destination: {
                                    Live2DDetailView(seasonalCostume: costume)
                                }, label: {
                                    CustomGroupBox {
                                        ExtendedConstraints {
                                            Text("Live2d-viewer.year.\(costume.seasonType.components(separatedBy: "_").last ?? "").\(costume.seasonCostumeType.localizedString)")
                                        }
                                        .padding()
                                    }
                                })
                                .buttonStyle(.plain)
                            }
                        } else if selectionIsMeaningful() {
                            CustomGroupBox {
                                HStack {
                                    Spacer()
                                    Text("Live2d-viewer.unavailable")
                                        .bold()
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: infoContentMaxWidth)
                Spacer(minLength: 0)
            }
        }
        .withSystemBackground()
        .navigationTitle("Live2d-viewer")
        .onChange(of: selectedItemTypeIndex) {
            updateDestination()
        }
    }
    func updateDestination() {
        Task {
            informationIsLoading = true
            if selectedItemTypeIndex != 1 {
                selectedCostume = nil
            }
            if selectedItemTypeIndex == 0 {
                if let card = selectedCard,
                   let fullCard = await Card(preview: card),
                   let costume = await Costume(id: fullCard.costumeID) {
                    self.selectedCostume = .init(costume)
                }
                informationIsLoading = false
            } else if selectedItemTypeIndex == 2 {
                if let character = selectedCharacter {
                    let character = await Character(preview: character)
                    seasonalCostumes = character?.seasonCostumeList?.flatMap { $0 }
                }
            }
            informationIsLoading = false
        }
    }
    
    func selectionIsMeaningful() -> Bool {
        switch selectedItemTypeIndex {
        case 0:
            return selectedCard != nil
        case 1:
            return selectedCostume != nil
        case 2:
            return selectedCharacter != nil
        default:
            return false
        }
    }
}

struct Live2DDetailView: View {
    var costume: PreviewCostume?
    var seasonalCostume: SeasonCostume?
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @State var isInspectorPresented = false
    @State var isSwayEnabled = true
    @State var isBreathEnabled = true
    @State var isEyeBlinkEnabled = true
    @State var motions = [Live2DMotion]()
    @State var expressions = [Live2DExpression]()
    @State var currentMotion: Live2DMotion?
    @State var currentExpression: Live2DExpression?
    @State var isTrackingParameters = false
    @State var isPaused = false
    @State var parameters = [Live2DParameter]()
    @State var isInspectorVisible = false
    var body: some View {
        HStack {
            Spacer(minLength: 0)
            VStack {
                Group {
                    if let costume {
                        Live2DView(costume: costume) {
                            ProgressView()
                        }
//                        .accessibilityElement()
//                        .accessibilityLabel("""
//                        Live2D of character \(PreCache.current.characters.first { $0.id == costume.characterID }?.characterName.forPreferredLocale() ?? ""). \
//                        Wearing costume named "\(costume.description.forPreferredLocale() ?? "")". \
//                        Acting as the \(currentMotion != nil ? "motion named \"\(currentMotion!.name)\"" : "default motion"). \
//                        Emoting as the \(currentExpression != nil ? "expression named \"\(currentExpression!.name)\"" : "default expression").
//                        """)
                    } else if let seasonalCostume {
                        Live2DView(costume: seasonalCostume) {
                            ProgressView()
                        }
//                        .accessibilityElement()
//                        .accessibilityLabel("""
//                        Live2D of character \(PreCache.current.characters.first { $0.id == seasonalCostume.characterID }?.characterName.forPreferredLocale() ?? ""). \
//                        Wearing \(seasonalCostume.seasonCostumeType.localizedString). \
//                        Acting as the \(currentMotion != nil ? "motion named \"\(currentMotion!.name)\"" : "default motion"). \
//                        Emoting as the \(currentExpression != nil ? "expression named \"\(currentExpression!.name)\"" : "default expression").
//                        """)
                    }
                }
                .scaledToFit()
                .live2dSwayDisabled(!isSwayEnabled)
                .live2dBreathDisabled(!isBreathEnabled)
                .live2dEyeBlinkDisabled(!isEyeBlinkEnabled)
                .live2dMotion(currentMotion)
                .live2dExpression(currentExpression)
                .live2dPauseAnimations(isPaused)
                .live2dParameters($parameters, tracking: isTrackingParameters)
                .onLive2DMotionsUpdate { motions in
                    self.motions = motions
                }
                .onLive2DExpressionsUpdate { expressions in
                    self.expressions = expressions
                }
                if horizontalSizeClass == .compact && isInspectorVisible {
                    Spacer()
                }
            }
            .animation(.spring(duration: 0.3, bounce: 0.3), value: isInspectorVisible)
            Spacer(minLength: 0)
        }
        .navigationTitle(costume?.description.forPreferredLocale() ?? seasonalCostume?.seasonCostumeType.localizedString ?? "")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(horizontalSizeClass == .compact && isInspectorVisible ? .hidden : .visible, for: .navigationBar)
        #endif
        .animation(.spring(duration: 0.3, bounce: 0.3), value: isInspectorVisible)
        .inspector(isPresented: $isInspectorPresented) {
            Form {
                Section {
                    Picker(selection: $currentMotion, content: {
                        ForEach(motions, id: \.self) { motion in
                            Text(motion.name).tag(motion)
                        }
                    }, label: {
                        Text("Live2D.detail.motion")
                    }, optionalCurrentValueLabel: {
                        Text(currentMotion?.name ?? String(localized: "Live2D.detail.motion.none"))
                    })
//                    .onChange(of: motions, initial: true, {
//                        if !motions.isEmpty {
//                            currentMotion = motions.first(where: { $0.name == "idle01" })
//                        }
//                    })
                    .onAppear {
                        isInspectorVisible = true
                    }
                    .onDisappear {
                        isInspectorVisible = false
                    }
                    Picker(selection: $currentExpression, content: {
                        ForEach(expressions, id: \.self) { expression in
                            Text(expression.name).tag(expression)
                        }
                    }, label: {
                        Text("Live2D.detail.expression")
                    }, optionalCurrentValueLabel: {
                        Text(currentExpression?.name ?? String(localized: "Live2D.detail.expression.none"))
                    })
                    .onChange(of: expressions, initial: true, {
                        if !expressions.isEmpty {
                            currentExpression = expressions.first(where: { $0.name == "default" })
                        }
                    })
                    Toggle("Live2D.detail.sway", isOn: $isSwayEnabled)
                    Toggle("Live2D.detail.breath", isOn: $isBreathEnabled)
                    Toggle("Live2D.detail.blink", isOn: $isEyeBlinkEnabled)
                }
                Section {
                    Toggle("Live2D.detail.track-parameters", isOn: $isTrackingParameters)
                    Toggle("Live2D.detail.freeze-animation", isOn: $isPaused)
                    Group {
                        ForEach(Array(parameters.enumerated()), id: \.element.id) { index, parameter in
                            VStack(alignment: .leading) {
                                Text("\(parameter.id)\(Text("Typography.bold-dot-seperater"))\(unsafe String(format: "%.2f", parameter.value))")
                                    .foregroundStyle(.gray)
                                Slider(value: $parameters[index].value, in: parameter.minimumValue...parameter.maximumValue)
                            }
                            .accessibilityAddTraits(isTrackingParameters && !isPaused ? .updatesFrequently : [])
                        }
                    }
                    .disabled(!isPaused)
                } header: {
                    Text("Live2D.parameters")
                }
            }
            .formStyle(.grouped)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
        }
        .toolbar {
            ToolbarItem {
                Button("Live2D.inspector", systemImage: "slider.horizontal.3") {
                    isInspectorPresented.toggle()
                }
            }
        }
    }
}
