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
    @State var itemType: [LocalizedStringKey] = ["Tools.live2d-viewer.type.card", "Tools.live2d-viewer.type.costume", "Tools.live2d-viewer.type.seasonal-costume"]
    @State var selectedItemTypeIndex = 0
    @State var id: Int = 1
    @State var costume: Costume?
    @State var informationIsLoading = true
    @State var seasonalCostumes: [PreviewCostume]?
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
                            ListItemView(title: {
                                Text("Tools.live2d-viewer.id")
                                    .bold()
                            }, value: {
                                TextField("Tools.live2d-viewer.id", value: $id, format: .number)
                            })
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
                                Live2DDetailView(costume: .init(costume))
                            }, label: {
                                CostumeInfo(costume)
                            })
                            .buttonStyle(.plain)
                        } else if let seasonalCostumes, !seasonalCostumes.isEmpty {
                            ForEach(seasonalCostumes.indices, id: \.self) { index in
                                NavigationLink(destination: {
                                    Live2DDetailView(costume: seasonalCostumes[index])
                                }, label: {
                                    CostumeInfo(seasonalCostumes[index])
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
                .frame(maxWidth: 600)
                Spacer(minLength: 0)
            }
        }
        .navigationTitle("Tools.live2d-viewer")
        .onAppear {
            updateDestination()
        }
        .onChange(of: id) {
            updateDestination()
        }
    }
    func updateDestination() {
        informationIsLoading = true
        costume = nil
        if selectedItemTypeIndex == 0 {
            Task {
                let card = await Card(id: id)
                if let card {
                    costume = await Costume(id: card.costumeID)
                }
                informationIsLoading = false
            }
        } else if selectedItemTypeIndex == 1 {
            Task {
                costume = await Costume(id: id)
                informationIsLoading = false
            }
        } else if selectedItemTypeIndex == 2 {
            Task {
                let character = await ExtendedCharacter(id: id)
                seasonalCostumes = character?.costumes
                informationIsLoading = false
            }
        }
    }
}

struct Live2DDetailView: View {
    var costume: PreviewCostume
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
                Live2DView(costume: costume) {
                    ProgressView()
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
        .navigationTitle(costume.description.forPreferredLocale() ?? "")
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
