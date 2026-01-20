//===---*- Greatdori! -*---------------------------------------------------===//
//
// ISVBacklogView.swift
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

import AVKit
import DoriKit
import SwiftUI
import SDWebImageSwiftUI
import SymbolAvailability

struct ISVBacklogView: View {
    var ir: StoryIR
    var currentTalk: TalkData
    var locale: DoriLocale
    var audios: [String: Data]
    @State var currentAudioPlayer: AVAudioPlayer? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
//#if os(macOS)
//                HStack {
//                    Spacer()
//                    Button(action: {
//                        dismiss()
//                    }, label: {
//                        Image(systemName: "xmark")
//                            .fontWeight(.semibold)
//                            .padding(8)
//                    })
//                    .buttonBorderShape(.circle)
//                    .wrapIf(true) { content in
//                        if #available(macOS 26.0, *) {
//                            content
//                                .buttonStyle(.glass)
//                        } else {
//                            content
//                                .buttonStyle(.bordered)
//                        }
//                    }
//                    .padding([.top, .trailing], 10)
//                }
//                .padding(.bottom, 5)
//                Divider()
//                    .padding(.horizontal, -15)
//#endif
                ScrollView {
                    contentView
                }
            }
        }
        .navigationTitle("Story-viewer.backlog")
//        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(action: {
                    dismiss()
                }, label: {
                    Label("Story-viewer.backlog.dismiss", systemImage: "xmark")
                        .wrapIf(isMACOS, in: {
                            $0.labelStyle(.titleOnly)
                        }, else: {
                            $0.labelStyle(.iconOnly)
                        })
                })
            }
        }
//        #endif
    }
    
    @ViewBuilder
    var contentView: some View {
        HStack {
            VStack(alignment: .leading) {
                let talks = ir.actions.compactMap {
                    if case let .talk(text, characterIDs: ids, characterNames: names, voicePath: vp) = $0 {
                        return TalkData(text: text, characterIDs: ids, characterNames: names, voicePath: vp)
                    }
                    return nil
                }
                ForEach(talks[talks.startIndex...talks.firstIndex(of: currentTalk)!], id: \.self) { talk in
                    HStack(alignment: .top) {
                        Button(action: {
                            currentAudioPlayer?.stop()
                            if let voice = talk.voicePath, let audioData = audios[voice] {
                                if let player = try? AVAudioPlayer(data: audioData) {
                                    currentAudioPlayer = player
                                    currentAudioPlayer?.play()
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                                        _fixLifetime(player)
                                    }
                                }
                            }
                        }, label: {
                            ZStack(alignment: .bottomTrailing) {
                                WebImage(url: URL(string: "https://bestdori.com/res/icon/chara_icon_\(talk.characterIDs.first ?? -1).png"))
                                    .resizable()
                                    .frame(width: 40, height: 40)
                                if let voice = talk.voicePath, let audioData = audios[voice] {
                                    Image(systemName: .speakerWave3Fill)
                                        .modifier(StrokeTextModifier(width: 1, color: .white))
                                        .foregroundStyle(Color(red: 255 / 255, green: 59 / 255, blue: 114 / 255))
                                        .shadow(radius: 1)
                                        .offset(x: 5, y: 5)
                                }
                            }
                        })
                        .buttonStyle(.plain)
                        VStack(alignment: .leading) {
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color(red: 255 / 255, green: 59 / 255, blue: 114 / 255))
                                    .frame(width: 200, height: 20)
                                Text(talk.characterNames.joined(separator: " & "))
                                    .font(.custom(fontName(in: locale), size: 15))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                            }
                            Text(talk.text)
                                .font(.custom(fontName(in: locale), size: 16))
                                .textSelection(.enabled)
                                .foregroundStyle(colorScheme == .light ? Color(red: 80 / 255, green: 80 / 255, blue: 80 / 255) : .init(red: 238 / 255, green: 238 / 255, blue: 238 / 255))
                                .padding(.leading, 20)
                        }
                    }
                    .padding(.bottom)
                }
            }
            Spacer()
        }
        .padding()
    }
}

