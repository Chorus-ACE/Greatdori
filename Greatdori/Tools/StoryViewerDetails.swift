//===---*- Greatdori! -*---------------------------------------------------===//
//
// StoryViewerDetails.swift
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

struct StoryDetailView: View {
    var title: String
    var scenarioID: String
    var voiceAssetBundleName: String?
    var type: StoryType
    var locale: _DoriAPI.Locale
    var unsafeAssociatedID: String // WTF --@WindowsMEMZ
    var unsafeSecondaryAssociatedID: String?
    @State var asset: _DoriAPI.Misc.StoryAsset?
    @State var transcript: [_DoriAPI.Misc.StoryAsset.Transcript]?
    @State var audioPlayer = AVPlayer()
    @State var interactivePlayerIsInFullScreen = false
    @State var screenWidth: CGFloat = 0
    @State var screenHeight: CGFloat = 0
    
    var body: some View {
        Group {
            if let transcript {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
                            Section {
                                StoryDetailInteractiveStoryEntryView(title: title, scenarioID: scenarioID, type: type, locale: locale, unsafeAssociatedID: unsafeAssociatedID, unsafeSecondaryAssociatedID: unsafeSecondaryAssociatedID, asset: $asset)
//                                    .border(.secondary, width: interactivePlayerIsInFullScreen ? 0 : 1)
                                    .aspectRatio(interactivePlayerIsInFullScreen ? screenWidth/screenHeight : 16/10, contentMode: .fill)
                                    .clipped()
//                                    .cornerRadius(interactivePlayerIsInFullScreen ? 0 : 10)
                            }
                            .frame(maxWidth: interactivePlayerIsInFullScreen ? nil : infoContentMaxWidth)
//                            .frame(width: interactivePlayerIsInFullScreen ? UIScreen.main.bounds.height : nil)
                            if !interactivePlayerIsInFullScreen {
                                DetailSectionsSpacer(height: 15)
                                
                                // Dialog
                                Section {
                                    ForEach(transcript, id: \.self) { transcript in
                                        switch transcript {
                                        case .notation(let content):
                                            HStack {
                                                Spacer()
                                                Text(content)
                                                    .underline()
                                                    .multilineTextAlignment(.center)
                                                Spacer()
                                            }
                                            .padding(.vertical)
                                        case .talk(let talk):
                                            CustomGroupBox {
                                                Button(action: {
                                                    if let voiceID = talk.voiceID {
                                                        let url = switch type {
                                                        case .event:
                                                            "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/eventstory\(unsafeAssociatedID)_\(unsafeSecondaryAssociatedID!)_rip/\(voiceID).mp3"
                                                        case .main:
                                                            "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/mainstory\(unsafeAssociatedID)_rip/\(voiceID).mp3"
                                                        case .band:
                                                            "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/\(voiceAssetBundleName!)_rip/\(voiceID).mp3"
                                                        case .card:
                                                            "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/resourceset/\(unsafeAssociatedID)_rip/\(voiceID).mp3"
                                                        case .actionSet:
                                                            "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/actionset/actionset\(Int(floor(Double(unsafeAssociatedID)! / 200) * 10))_rip/\(voiceID).mp3"
                                                        case .afterLive:
                                                            "https://bestdori.com/assets/\(locale.rawValue)/sound/voice/scenario/afterlivetalk/group\(Int(floor(Double(unsafeAssociatedID)! / 100)))_rip/\(voiceID).mp3"
                                                        }
                                                        audioPlayer.replaceCurrentItem(with: .init(url: .init(string: url)!))
                                                        audioPlayer.play()
                                                    }
                                                }, label: {
                                                    HStack {
                                                        VStack(alignment: .leading) {
                                                            HStack {
                                                                WebImage(url: talk.characterIconImageURL)
                                                                    .resizable()
                                                                    .frame(width: 20, height: 20)
                                                                Text(talk.characterName)
                                                                    .font(.headline)
                                                            }
                                                            Text(talk.text)
                                                                .font(.body)
                                                                .multilineTextAlignment(.leading)
                                                                .lineLimit(nil)
                                                        }
                                                        Spacer()
                                                    }
                                                    .foregroundStyle(Color.primary)
                                                })
                                                .buttonStyle(.borderless)
                                            }
#if os(macOS)
                                            .wrapIf(true) { content in
                                                if #available(macOS 15.0, *) {
                                                    content
                                                        .pointerStyle(.link)
                                                } else {
                                                    content
                                                }
                                            }
#endif
                                        @unknown default:
                                            EmptyView()
                                        }
                                    }
                                }
                                .frame(maxWidth: infoContentMaxWidth)
                            }
                        }
                        .padding(.all, interactivePlayerIsInFullScreen ? 0 : nil)
                        Spacer(minLength: 0)
                    }
                }
                .ignoresSafeArea(interactivePlayerIsInFullScreen && !isMACOS ? .all : [], edges: .all)
                .scrollDisabled(interactivePlayerIsInFullScreen)
                .onFrameChange { geometry in
                    screenWidth = geometry.size.width
                    screenHeight = geometry.size.height
                    print("\(screenWidth), \(screenHeight)")
                }
            } else {
                ExtendedConstraints {
                    ProgressView()
                }
            }
        }
        .navigationTitle(title)
#if os(iOS)
        .toolbar(interactivePlayerIsInFullScreen ? .hidden : .visible, for: .navigationBar)
        .toolbar(interactivePlayerIsInFullScreen ? .hidden : .visible, for: .tabBar)
#endif
        .navigationBarBackButtonHidden(interactivePlayerIsInFullScreen && !isMACOS)
        
        .withSystemBackground()
        .task {
            await loadTranscript()
        }
        .toolbar {
            ToolbarItem {
                Button(action: {
                    interactivePlayerIsInFullScreen.toggle()
                }, label: {
                    Image(systemName: "triangle")
                })
            }
            #if os(macOS)
            if AppFlag.DEBUG {
                ToolbarItem {
                    debugMenu
                }
            }
            #endif
        }
        .onChange(of: interactivePlayerIsInFullScreen) {
            #if os(iOS)
            if interactivePlayerIsInFullScreen {
                setDeviceOrientation(to: .landscape, allowing: [.landscapeLeft, .landscapeRight])
            } else {
                setDeviceOrientation(to: .portrait, allowing: .portrait)
            }
            #endif
        }
    }
    
    func loadTranscript() async {
        asset = switch type {
        case .event:
            await _DoriAPI.Misc.eventStoryAsset(
                eventID: Int(unsafeAssociatedID)!,
                scenarioID: scenarioID,
                locale: locale
            )
        case .main:
            await _DoriAPI.Misc.mainStoryAsset(
                scenarioID: scenarioID,
                locale: locale
            )
        case .band:
            await _DoriAPI.Misc.bandStoryAsset(
                bandID: Int(unsafeAssociatedID)!,
                scenarioID: scenarioID,
                locale: locale
            )
        case .card:
            await _DoriAPI.Misc.cardStoryAsset(
                resourceSetName: unsafeAssociatedID,
                scenarioID: scenarioID,
                locale: locale
            )
        case .actionSet:
            await _DoriAPI.Misc.actionSetStoryAsset(
                actionSetID: Int(unsafeAssociatedID)!,
                locale: locale
            )
        case .afterLive:
            await _DoriAPI.Misc.afterLiveStoryAsset(
                talkID: Int(unsafeAssociatedID)!,
                scenarioID: scenarioID,
                locale: locale
            )
        }
        transcript = asset?.transcript
    }
    
    #if os(macOS)
    @ViewBuilder
    private var debugMenu: some View {
        let voiceBundlePath = {
            switch type {
            case .event:
                "\(locale.rawValue)/sound/voice/scenario/eventstory\(unsafeAssociatedID)_\(unsafeSecondaryAssociatedID!)"
            case .main:
                "\(locale.rawValue)/sound/voice/scenario/mainstory\(unsafeAssociatedID)"
            case .band:
                "\(locale.rawValue)/sound/voice/scenario/\(voiceAssetBundleName!)"
            case .card:
                "\(locale.rawValue)/sound/voice/scenario/resourceset/\(unsafeAssociatedID)"
            case .actionSet:
                "\(locale.rawValue)/sound/voice/scenario/actionset/actionset\(Int(floor(Double(unsafeAssociatedID)! / 200) * 10))"
            case .afterLive:
                "\(locale.rawValue)/sound/voice/scenario/afterlivetalk/group\(Int(floor(Double(unsafeAssociatedID)! / 100)))"
            }
        }()
        if let asset {
            Menu(String("Debug"), systemImage: "ant.fill") {
                Section {
                    Button(String("Dump IR"), systemImage: "text.word.spacing") {
                        let downloadBase = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                        let dst = downloadBase.appending(path: "DumpIR.txt")
                        let ir = DoriStoryBuilder.Conversion.zeileIR(
                            fromBandori: asset,
                            in: locale,
                            voiceBundlePath: voiceBundlePath
                        )
                        let text = DoriStoryBuilder.Conversion.plainText(fromIR: ir)
                        try? text.write(to: dst, atomically: true, encoding: .utf8)
                        NSWorkspace.shared.selectFile(
                            nil,
                            inFileViewerRootedAtPath: dst.path
                        )
                    }
                }
            }
            .menuIndicator(.hidden)
            .menuStyle(.button)
        }
    }
    #endif
    
    struct StoryDetailInteractiveStoryEntryView: View {
        var title: String
        var scenarioID: String
        var voiceAssetBundleName: String?
        var type: StoryType
        var locale: _DoriAPI.Locale
        var unsafeAssociatedID: String // WTF
        var unsafeSecondaryAssociatedID: String?
        @Binding var asset: _DoriAPI.Misc.StoryAsset?
        var body: some View {
            if let asset {
                InteractiveStoryView(asset: asset, voiceBundlePath: {
                    switch type {
                    case .event:
                        "\(locale.rawValue)/sound/voice/scenario/eventstory\(unsafeAssociatedID)_\(unsafeSecondaryAssociatedID!)"
                    case .main:
                        "\(locale.rawValue)/sound/voice/scenario/mainstory\(unsafeAssociatedID)"
                    case .band:
                        "\(locale.rawValue)/sound/voice/scenario/\(voiceAssetBundleName!)"
                    case .card:
                        "\(locale.rawValue)/sound/voice/scenario/resourceset/\(unsafeAssociatedID)"
                    case .actionSet:
                        "\(locale.rawValue)/sound/voice/scenario/actionset/actionset\(Int(floor(Double(unsafeAssociatedID)! / 200) * 10))"
                    case .afterLive:
                        "\(locale.rawValue)/sound/voice/scenario/afterlivetalk/group\(Int(floor(Double(unsafeAssociatedID)! / 100)))"
                    }
                }(), locale: locale)
            } else {
                ProgressView()
            }
        }
    }
}


