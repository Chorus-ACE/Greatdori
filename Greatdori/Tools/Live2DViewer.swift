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
        "Tools.live2d-viewer.type.card",
        "Tools.live2d-viewer.type.costume",
        "Tools.live2d-viewer.type.seasonal-costume"
    ]
    @State private var selectedItemTypeIndex = 0
    @State private var selectedCard: PreviewCard?
    @State private var selectedCharacter: PreviewCharacter?
    @State private var costume: PreviewCostume?
    @State private var informationIsLoading = false
    @State private var seasonalCostumes: [SeasonCostume]?
    var body: some View {
        ScrollView {
            HStack {
                Spacer(minLength: 0)
                VStack {
                    CustomGroupBox {
                        VStack {
                            ListItemView(title: {
                                Text("Tools.live2d-viewer.type")
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
                                ListItemView {
                                    Text("Tools.live2d-viewer.card")
                                        .bold()
                                } value: {
                                    ItemSelectorButton(selection: $selectedCard)
                                        .onChange(of: selectedCard) {
                                            updateDestination()
                                        }
                                }
                            } else if selectedItemTypeIndex == 1 {
                                ListItemView {
                                    Text("Tools.live2d-viewer.costume")
                                        .bold()
                                } value: {
                                    ItemSelectorButton(selection: $costume)
                                }
                            } else if selectedItemTypeIndex == 2 {
                                ListItemView {
                                    Text("Tools.live2d-viewer.character")
                                        .bold()
                                } value: {
                                    CharacterSelectorButton(selection: $selectedCharacter)
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
                        if let costume, [0, 1].contains(selectedItemTypeIndex) {
                            NavigationLink(destination: {
                                Live2DDetailView(costume: costume)
                            }, label: {
                                CostumeInfo(costume)
                            })
                            .buttonStyle(.plain)
                        } else if let seasonalCostumes {
                            ForEach(seasonalCostumes, id: \.self) { costume in
                                NavigationLink(destination: {
                                    Live2DDetailView(seasonalCostume: costume)
                                }, label: {
                                    CustomGroupBox {
                                        ExtendedConstraints {
                                            Text("第\(costume.seasonType.components(separatedBy: "_").last ?? "")年 \(costume.seasonCostumeType.localizedString)")
                                        }
                                        .padding()
                                    }
                                })
                                .buttonStyle(.plain)
                            }
                        } else {
                            CustomGroupBox {
                                HStack {
                                    Spacer()
                                    Text("Tools.live2d-viewer.unavailable")
                                        .bold()
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: 600)
                Spacer(minLength: 0)
            }
        }
        .withSystemBackground()
        .navigationTitle("Tools.live2d-viewer")
        .onChange(of: selectedItemTypeIndex) {
            updateDestination()
        }
    }
    func updateDestination() {
        Task {
            informationIsLoading = true
            if selectedItemTypeIndex != 1 {
                costume = nil
            }
            if selectedItemTypeIndex == 0 {
                if let card = selectedCard,
                   let fullCard = await Card(preview: card),
                   let costume = await Costume(id: fullCard.costumeID) {
                    self.costume = .init(costume)
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
                    } else if let seasonalCostume {
                        Live2DView(costume: seasonalCostume) {
                            ProgressView()
                        }
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
                    Picker("动作", selection: $currentMotion) {
                        Text("(无)").tag(Optional<Live2DMotion>.none)
                        ForEach(motions, id: \.self) { motion in
                            Text(motion.name).tag(motion)
                        }
                    }
                    .onAppear {
                        isInspectorVisible = true
                    }
                    .onDisappear {
                        isInspectorVisible = false
                    }
                    Picker("表情", selection: $currentExpression) {
                        Text("(无)").tag(Optional<Live2DExpression>.none)
                        ForEach(expressions, id: \.self) { expression in
                            Text(expression.name).tag(expression)
                        }
                    }
                    Toggle("摇摆", isOn: $isSwayEnabled)
                    Toggle("呼吸", isOn: $isBreathEnabled)
                    Toggle("眨眼", isOn: $isEyeBlinkEnabled)
                }
                Section {
                    Toggle("跟踪参数", isOn: $isTrackingParameters)
                    Toggle("暂停动画", isOn: $isPaused)
                    Group {
                        ForEach(Array(parameters.enumerated()), id: \.element.id) { index, parameter in
                            VStack(alignment: .leading) {
                                Text("\(parameter.id)\(Text("Typography.bold-dot-seperater"))\(unsafe String(format: "%.2f", parameter.value))")
                                    .foregroundStyle(.gray)
                                Slider(value: $parameters[index].value, in: parameter.minimumValue...parameter.maximumValue)
                            }
                        }
                    }
                    .disabled(!isPaused)
                } header: {
                    Text("参数")
                }
            }
            .formStyle(.grouped)
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationBackgroundInteraction(.enabled)
        }
        .toolbar {
            ToolbarItem {
                Button("检查器", systemImage: "sidebar.right") {
                    isInspectorPresented.toggle()
                }
            }
        }
    }
}
