//===---*- Greatdori! -*---------------------------------------------------===//
//
// SongDetailView.swift
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

struct SongDetailView: View {
    var id: Int
    @State var information: ExtendedSong?
    @State var availability = true
    @State var selectedDifficulty: _DoriAPI.Songs.DifficultyType?
    var body: some View {
        List {
            if let information {
                Section {
                    HStack {
                        Spacer()
                        WebImage(url: information.song.jacketImageURL)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                            .frame(width: 100, height: 100)
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                    .listRowInsets(.init())
                }
                Section {
                    InfoTextView("标题", text: information.song.musicTitle)
                    InfoTextView("种类", text: information.song.tag.localizedString)
                    InfoTextView("歌词", text: information.song.lyricist)
                    InfoTextView("作曲", text: information.song.composer)
                    InfoTextView("编曲", text: information.song.arranger)
                }
                .listRowBackground(Color.clear)
                Section {
                    if let band = information.band {
                        VStack(alignment: .leading) {
                            Text("乐团")
                                .font(.system(size: 16, weight: .medium))
                            HStack {
                                WebImage(url: band.iconImageURL)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                                Text(band.bandName.forPreferredLocale() ?? "")
                                    .font(.system(size: 14))
                                    .opacity(0.6)
                            }
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("难度")
                            .font(.system(size: 16, weight: .medium))
                        HStack {
                            let keys = information.song.difficulty.keys.sorted { $0.rawValue < $1.rawValue }
                            ForEach(keys, id: \.rawValue) { key in
                                Text(String(information.song.difficulty[key]!.playLevel))
                                    .foregroundStyle(.black)
                                    .frame(width: 20, height: 20)
                                    .background {
                                        Circle()
                                            .fill(key.color)
                                    }
                            }
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("歌曲长度")
                            .font(.system(size: 16, weight: .medium))
                        Text({
                            let minutes = Int(information.song.length) / 60
                            let remainingSeconds = Int(information.song.length) % 60
                            let tenths = Int((information.song.length - floor(information.song.length)) * 10)
                            return unsafe String(format: "%d:%02d.%d", minutes, remainingSeconds, tenths)
                        }())
                        .font(.system(size: 14))
                        .opacity(0.6)
                    }
                    if let publishDate = information.song.publishedAt.forPreferredLocale() {
                        VStack(alignment: .leading) {
                            Text("倒计时")
                                .font(.system(size: 16, weight: .medium))
                            Group {
                                if publishDate > .now {
                                    Text("\(Text(publishDate, style: .relative))后发布")
                                } else {
                                    Text("已发布")
                                }
                            }
                            .font(.system(size: 14))
                            .opacity(0.6)
                        }
                    }
                    if let date = information.song.publishedAt.forPreferredLocale() {
                        VStack(alignment: .leading) {
                            Text("发布日期")
                                .font(.system(size: 16, weight: .medium))
                            Text({
                                let df = DateFormatter()
                                df.dateStyle = .medium
                                df.timeStyle = .short
                                return df.string(from: date)
                            }())
                            .font(.system(size: 14))
                            .opacity(0.6)
                        }
                    }
                    VStack(alignment: .leading) {
                        Text("歌曲获取")
                            .font(.system(size: 16, weight: .medium))
                        Text(information.song.howToGet.forPreferredLocale() ?? "")
                            .font(.system(size: 14))
                            .opacity(0.6)
                    }
                } header: {
                    Text("资讯")
                }
                .listRowBackground(Color.clear)
                if let events = information.events.forPreferredLocale(),
                   !events.isEmpty {
                    Section {
                        FoldableList(events.reversed()) { event in
                            NavigationLink(destination: { EventDetailView(id: event.id) }) {
                                EventCardView(event, inLocale: nil)
                            }
                            .listRowBackground(Color.clear)
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        }
                    } header: {
                        Text("活动")
                    }
                }
                if let selectedDifficulty {
                    Section {
                        VStack(alignment: .leading) {
                            Text("音符")
                                .font(.system(size: 16, weight: .medium))
                            Text(String(information.meta[selectedDifficulty]!.notes))
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                        VStack(alignment: .leading) {
                            Text("BPM")
                                .font(.system(size: 16, weight: .medium))
                            Text(String(information.song.bpm[selectedDifficulty]!.reduce(into: 0) { $0 += $1.bpm } / information.song.bpm[selectedDifficulty]!.count))
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                        VStack(alignment: .leading) {
                            Text("分数")
                                .font(.system(size: 16, weight: .medium))
                            Text(verbatim: "\(Int(information.meta[selectedDifficulty]!.score * 100))%")
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                        VStack(alignment: .leading) {
                            Text("分数 (Fever)")
                                .font(.system(size: 16, weight: .medium))
                            Text(verbatim: "\(Int(information.metaFever[selectedDifficulty]!.score * 100))%")
                                .font(.system(size: 14))
                                .opacity(0.6)
                        }
                    } header: {
                        HStack {
                            Text("Meta")
                            Spacer()
                            Button(action: {
                                let sortedKeys = information.song.difficulty.keys.sorted { $0.rawValue < $1.rawValue }
                                let index = sortedKeys.firstIndex(of: selectedDifficulty)! + 1
                                if index < sortedKeys.count {
                                    self.selectedDifficulty = sortedKeys[index]
                                } else {
                                    self.selectedDifficulty = sortedKeys.first!
                                }
                            }, label: {
                                Text(String(information.song.difficulty[selectedDifficulty]!.playLevel))
                                    .foregroundStyle(.black)
                                    .frame(width: 20, height: 20)
                                    .background {
                                        Circle()
                                            .fill(selectedDifficulty.color)
                                    }
                            })
                            .buttonStyle(.borderless)
                        }
                    }
                    .listRowBackground(Color.clear)
                }
            } else {
                if availability {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                } else {
                    UnavailableView("载入歌曲时出错", systemImage: "_music", retryHandler: getInformation)
                }
            }
        }
        .navigationTitle(information?.song.musicTitle.forPreferredLocale() ?? String(localized: "正在载入歌曲..."))
        .task {
            await getInformation()
        }
    }
    
    func getInformation() async {
        availability = true
        withDoriCache(id: "SongDetail_\(id)") {
            await ExtendedSong(id: id)
        }.onUpdate {
            if let information = $0 {
                self.information = information
                selectedDifficulty = information.song.difficulty.keys.sorted { $0.rawValue < $1.rawValue }.first
                prefetchImages(
                    information.events.compactMap { $0 }.flatMap { $0 }.map(\.bannerImageURL)
                )
            } else {
                availability = false
            }
        }
    }
}
