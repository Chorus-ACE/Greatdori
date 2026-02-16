//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongMetaView.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2026 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.com/LICENSE.txt for license information
// See https://greatdori.com/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import DoriKit
import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct SongMetaView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("SongMetaSkillLevel") private var skillLevel = 4
    @AppStorage("SongMetaPerfectRate") private var perfectRate = 100.0
    @AppStorage("SongMetaDowntime") private var downtime = 30.0
    @AppStorage("SongMetaFever") private var fever = true
    @State private var allSkills: [Skill]?
    @State private var selectedSkill: Skill?
    @State private var locale = DoriLocale.primaryLocale
    @State private var meta: [DoriFrontend.Songs.SongWithMeta]?
    @State private var isFailedToLoad = false
    @State private var isConfigurationPresented = false
    @State private var compactBaseHeight: CGFloat = 30
    var body: some View {
        Group {
            if let meta, let allSkills {
                Group {
                    if sizeClass == .regular {
                        regularTable(meta)
                    } else {
                        compactTable(meta)
                    }
                }
                .toolbar {
                    ToolbarItem {
                        Button("song-meta.configuration", systemImage: "gearshape") {
                            isConfigurationPresented = true
                        }
                        .sheet(isPresented: $isConfigurationPresented) {
                            NavigationStack {
                                configurationView(skills: allSkills)
                            }
                            .onDisappear {
                                isConfigurationPresented = false
                                self.meta = nil
                                Task {
                                    await updateMeta()
                                }
                            }
                            .presentationDetents([.medium, .large])
                        }
                    }
                }
            } else {
                if !isFailedToLoad {
                    ExtendedConstraints {
                        ProgressView()
                            .controlSize(.large)
                            .onAppear {
                                Task {
                                    await updateMeta()
                                }
                            }
                    }
                } else {
                    ExtendedConstraints {
                        ContentUnavailableView("song-meta.unavailable", systemImage: "music.note.list", description: Text("Search.unavailable.description"))
                    }
                    .onTapGesture {
                        Task {
                            await updateMeta()
                        }
                    }
                }
            }
        }
        .navigationTitle("song-meta")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
    
    @ViewBuilder
    private func regularTable(_ meta: [DoriFrontend.Songs.SongWithMeta]) -> some View {
        Table(meta._enumerated()) {
            TableColumn("song-meta.table.rank") { meta in
                Text("#\(meta.offset + 1)")
            }
            .width(min: 25, ideal: 50)
            TableColumn("song-meta.table.title") { meta in
                if let l = meta.element.song.musicTitle.availableLocale(prefer: locale) {
                    Text(meta.element.song.musicTitle[l]!)
                } else {
                    Text(verbatim: "")
                }
            }
            TableColumn("song-meta.table.difficulty") { meta in
                SongDifficultyIndicator(difficulty: meta.element.meta.difficulty, level: meta.element.meta.playLevel)
                    .foregroundStyle(.primary)
            }
            .width(min: SongDifficultyIndicator.diameter, ideal: SongDifficultyIndicator.diameter)
            TableColumn("song-meta.table.song-length") { meta in
                let length = meta.element.meta.length
                let minute = Int(length / 60)
                let second = round((length - Double(minute) * 60) * 10) / 10
                Text(unsafe String(format: "%i:%.1f", minute, second))
            }
            .width(min: 25, ideal: 40)
            TableColumn("song-meta.table.score") { meta in
                Text(verbatim: "\(Int(meta.element.meta.score * 100))%")
            }
            .width(min: 25, ideal: 35)
            TableColumn("song-meta.table.efficiency") { meta in
                Text(verbatim: "\(Int(meta.element.meta.efficiency * 100))%")
            }
            .width(min: 25, ideal: 35)
            TableColumn("song-meta.table.bpm") { meta in
                Text("\(meta.element.meta.bpm)")
            }
            .width(min: 25, ideal: 25)
            TableColumn("song-meta.table.total-notes") { meta in
                Text("\(meta.element.meta.notes)")
            }
            .width(min: 25, ideal: 25)
            TableColumn("song-meta.table.notes-per-second") { meta in
                Text(unsafe String(format: "%.1f", round(meta.element.meta.notesPerSecond * 10) / 10))
            }
            .width(min: 20, ideal: 25)
            TableColumn("song-meta.table.skill-reliance") { meta in
                Text(verbatim: "\(Int(meta.element.meta.sr * 100))%")
            }
            .width(min: 20, ideal: 30)
        }
    }
    
    @ViewBuilder
    private func compactTable(_ meta: [DoriFrontend.Songs.SongWithMeta]) -> some View {
        ScrollView([.horizontal, .vertical]) {
            LazyVGrid(columns: [
                .init(.flexible(minimum: 30)),
                .init(.flexible(minimum: 200)),
                .init(.flexible(minimum: 80)),
                .init(.flexible(minimum: 50)),
                .init(.flexible(minimum: 50)),
                .init(.flexible(minimum: 70)),
                .init(.flexible(minimum: 50)),
                .init(.flexible(minimum: 50)),
                .init(.flexible(minimum: 80)),
                .init(.flexible(minimum: 100)),
            ], alignment: .leading) {
                Group {
                    Text("song-meta.table.rank")
                    Text("song-meta.table.title")
                    Text("song-meta.table.difficulty")
                    Text("song-meta.table.song-length")
                    Text("song-meta.table.score")
                    Text("song-meta.table.efficiency")
                    Text("song-meta.table.bpm")
                    Text("song-meta.table.total-notes")
                    Text("song-meta.table.notes-per-second")
                    Text("song-meta.table.skill-reliance")
                }
                .font(.callout)
                
                ForEach(meta._enumerated()) { meta in
                    // Rank
                    Text("#\(meta.offset + 1)")
                        .onGeometryChange(for: CGFloat.self) { proxy in
                            proxy.size.height
                        } action: { value in
                            compactBaseHeight = value
                        }
                    
                    // Title
                    if let l = meta.element.song.musicTitle.availableLocale(prefer: locale) {
                        Text(meta.element.song.musicTitle[l]!)
                    } else {
                        Text(verbatim: "")
                    }
                    
                    // Difficulty
                    SongDifficultyIndicator(difficulty: meta.element.meta.difficulty, level: meta.element.meta.playLevel)
                        .foregroundStyle(.primary)
                    
                    // Length
                    let length = meta.element.meta.length
                    let minute = Int(length / 60)
                    let second = round((length - Double(minute) * 60) * 10) / 10
                    Text(unsafe String(format: "%i:%.1f", minute, second))
                    
                    // Score
                    Text(verbatim: "\(Int(meta.element.meta.score * 100))%")
                    
                    // Efficiency
                    Text(verbatim: "\(Int(meta.element.meta.efficiency * 100))%")
                    
                    // BPM
                    Text("\(meta.element.meta.bpm)")
                    
                    // Notes
                    Text("\(meta.element.meta.notes)")
                    
                    // Notes Per Second
                    Text(unsafe String(format: "%.1f", round(meta.element.meta.notesPerSecond * 10) / 10))
                    
                    // Skill Reliance
                    Text(verbatim: "\(Int(meta.element.meta.sr * 100))%")
                }
                ._variadic { views in
                    ForEach(views) { view in
                        VStack(alignment: .leading) {
                            view
                                .frame(height: compactBaseHeight)
                            Rectangle()
                                .fill(colorScheme == .light ? Color(red: 0.8, green: 0.8, blue: 0.8) : Color(red: 0.2, green: 0.2, blue: 0.2))
                                .frame(height: 1)
                                .padding(.horizontal, -10)
                        }
                    }
                }
                .lineLimit(1)
            }
            .padding(.horizontal)
        }
        #if os(iOS)
        .introspect(.scrollView, on: .iOS(.v17...)) { scrollView in
            scrollView.bounces = false
        }
        #endif
    }
    
    @ViewBuilder
    private func configurationView(skills: [Skill]) -> some View {
        Form {
            Picker("song-meta.config.skill", selection: $selectedSkill) {
                ForEach(skills) { skill in
                    Text(skill.simpleDescription.forPreferredLocale() ?? "")
                        .tag(skill)
                }
            }
            .onChange(of: selectedSkill) {
                if let selectedSkill {
                    UserDefaults.standard.set(selectedSkill.id, forKey: "SongMetaSelectedSkill")
                }
            }
            Picker("song-meta.config.skill-level", selection: $skillLevel) {
                ForEach(0..<5) { level in
                    Text(String(level + 1))
                        .tag(level)
                }
            }
            HStack {
                Text("song-meta.config.perfect-rate")
                Spacer()
                TextField("", value: $perfectRate, formatter: DoubleFormatter())
                    .labelsHidden()
                    .frame(maxWidth: 100)
                Stepper("", value: $perfectRate, in: 0...100)
                    .labelsHidden()
            }
            HStack {
                Text("song-meta.config.downtime")
                Spacer()
                TextField("", value: $downtime, formatter: DoubleFormatter())
                    .labelsHidden()
                    .frame(maxWidth: 100)
                Stepper("", value: $downtime, in: 0...Double(Int.max))
                    .labelsHidden()
            }
            Toggle("song-meta.config.fever", isOn: $fever)
        }
        .formStyle(.grouped)
        .toolbar {
            #if os(macOS)
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    isConfigurationPresented = false
                }
            }
            #endif
        }
    }
    
    private func updateMeta() async {
        isFailedToLoad = false
        if allSkills == nil {
            allSkills = await Skill.all()
            if allSkills == nil {
                isFailedToLoad = true
                return
            }
        }
        if selectedSkill == nil {
            let storedID = UserDefaults.standard.integer(forKey: "SongMetaSelectedSkill")
            if storedID > 0 {
                selectedSkill = allSkills!.first { $0.id == storedID } ?? allSkills!.first
            } else {
                selectedSkill = allSkills!.first
            }
        }
        
        guard let selectedSkill else {
            isFailedToLoad = true
            return
        }
        meta = await DoriFrontend.Songs.allMeta(
            with: selectedSkill,
            in: locale,
            skillLevel: skillLevel,
            perfectRate: perfectRate,
            downtime: downtime,
            fever: fever
        )
    }
}

struct EnumeratedSongWithMeta: Identifiable {
    var offset: Int
    var element: DoriFrontend.Songs.SongWithMeta
    
    var id: Int { element.hashValue }
}
extension Array<DoriFrontend.Songs.SongWithMeta> {
    func _enumerated() -> [EnumeratedSongWithMeta] {
        enumerated().map { .init(offset: $0.offset, element: $0.element) }
    }
}
