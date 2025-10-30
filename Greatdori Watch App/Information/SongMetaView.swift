//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongMetaView.swift
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

struct SongMetaView: View {
    @State var meta: [_DoriFrontend.Songs.SongWithMeta]?
    @State var allSkills: [Skill]?
    @State var selectedSkill: Skill?
    @State var sort = _DoriFrontend.Songs.MetaSort.efficiency
    @State var locale = DoriLocale.primaryLocale
    @State var skillLevel = 4
    @State var perfectRate = 100.0
    @State var downtime = 30.0
    @State var fever = true
    @State var availability = true
    var body: some View {
        List {
            if let meta {
                Section {
                    ForEach(Array(meta.enumerated()), id: \.element.self) { (index, meta) in
                        NavigationLink(destination: { SongMetaDetailView(meta: meta) }) {
                            HStack {
                                Text(verbatim: "#\(index + 1)")
                                    .bold()
                                Text(meta.song.musicTitle.forPreferredLocale() ?? "")
                                Spacer(minLength: 0)
                                Text(String(meta.meta.playLevel))
                                    .foregroundStyle(.black)
                                    .frame(width: 20, height: 20)
                                    .background {
                                        Circle()
                                            .fill(meta.meta.difficulty.color)
                                    }
                            }
                        }
                    }
                }
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入歌曲 Meta 时出错", systemImage: "music.pages.fill", retryHandler: getMeta)
                }
            }
        }
        .navigationTitle("歌曲 Meta")
        .task {
            await getMeta()
        }
    }
    
    func getMeta() async {
        availability = true
        withDoriCache(id: "SkillList") {
            await Skill.all()
        }.onUpdate {
            if let skills = $0 {
                self.allSkills = skills
                if selectedSkill == nil {
                    selectedSkill = skills.first
                }
                if let selectedSkill {
                    Task {
                        await _getMeta(skill: selectedSkill)
                    }
                }
            } else {
                availability = false
            }
        }
    }
    func _getMeta(skill: _DoriAPI.Skills.Skill) async {
        availability = true
        withDoriCache(id: "MetaList_\(sort.rawValue)") {
            await _DoriFrontend.Songs.allMeta(
                with: skill,
                in: locale,
                skillLevel: skillLevel,
                perfectRate: perfectRate,
                downtime: downtime,
                fever: fever,
                sort: sort
            )
        }.onUpdate {
            if let meta = $0 {
                self.meta = meta
            } else {
                availability = false
            }
        }
    }
}

private struct SongMetaDetailView: View {
    var meta: _DoriFrontend.Songs.SongWithMeta
    var body: some View {
        List {
            Section {
                NavigationLink(destination: { SongDetailView(id: meta.song.id) }) {
                    SongCardView(meta.song)
                }
            }
            Section {
                InfoTextView("时长", text: {
                    let minutes = Int(meta.meta.length) / 60
                    let remainingSeconds = Int(meta.meta.length) % 60
                    let tenths = Int((meta.meta.length - floor(meta.meta.length)) * 10)
                    return unsafe String(format: "%d:%02d.%d", minutes, remainingSeconds, tenths)
                }())
                InfoTextView("分数", text: "\(Int(meta.meta.score * 100))%")
                InfoTextView("效率", text: "\(Int(meta.meta.efficiency * 100))%")
                InfoTextView(verbatim: "BPM", text: String(meta.meta.bpm))
                InfoTextView("音符总数", text: String(meta.meta.notes))
                InfoTextView("每秒音符总数", text: unsafe String(format: "%.1f", meta.meta.notesPerSecond))
                InfoTextView("技能依赖度", text: "\(Int(meta.meta.sr * 100))%")
            } header: {
                HStack {
                    Text("Meta")
                    Spacer()
                    Text(String(meta.meta.playLevel))
                        .foregroundStyle(.black)
                        .frame(width: 20, height: 20)
                        .background {
                            Circle()
                                .fill(meta.meta.difficulty.color)
                        }
                }
            }
            .listRowBackground(Color.clear)
        }
        .navigationTitle(meta.song.musicTitle.forPreferredLocale() ?? "")
    }
}
