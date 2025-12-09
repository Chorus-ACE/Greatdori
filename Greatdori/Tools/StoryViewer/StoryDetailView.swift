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
    @State var locale: _DoriAPI.Locale
    var unsafeAssociatedID: String // WTF --@WindowsMEMZ
    var unsafeSecondaryAssociatedID: String?
    @AppStorage("ISVAlwaysFullScreen") var isvAlwaysFullScreen = false
//    @AppStorage("ISVBannerIsShowing") var ISVBannerIsShowing = true
    @AppStorage("ISVHadChosenOption") var ISVHadChosenOption = false
    @State var isvLayoutSelectionSheetIsDisplaying = false
    @State var asset: _DoriAPI.Misc.StoryAsset?
    @State var transcript: [_DoriAPI.Misc.StoryAsset.Transcript]?
    @State var isAssetUnavailable = false
    @State var audioPlayer = AVPlayer()
    @State var interactivePlayerIsInFullScreen = false
    @State var screenWidth: CGFloat = 0
    @State var screenHeight: CGFloat = 0
    @State var safeAreaInsets = EdgeInsets()
    @State var isMuted = false
    var body: some View {
        ZStack {
            if let transcript {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
                            if !isvAlwaysFullScreen || interactivePlayerIsInFullScreen {
                                Section {
                                    StoryDetailInteractiveStoryEntryView(
                                        scenarioID: scenarioID,
                                        voiceAssetBundleName: voiceAssetBundleName,
                                        type: type,
                                        locale: locale,
                                        unsafeAssociatedID: unsafeAssociatedID,
                                        unsafeSecondaryAssociatedID: unsafeSecondaryAssociatedID,
                                        asset: $asset
                                    )
                                    .safeAreaPadding(interactivePlayerIsInFullScreen ? safeAreaInsets : .init())
                                    .aspectRatio(interactivePlayerIsInFullScreen ? screenWidth/screenHeight : 16/10, contentMode: .fit)
                                    .clipped()
                                    .isvIsMuted($isMuted)
                                    .isvIsInFullScreen($interactivePlayerIsInFullScreen)
                                }
                                .frame(maxWidth: interactivePlayerIsInFullScreen ? nil : infoContentMaxWidth)
                            }
                            if !interactivePlayerIsInFullScreen {
                                if !isvAlwaysFullScreen {
                                    HStack {
                                        Button(action: {
                                            isMuted.toggle()
                                        }, label: {
                                            Label("Story-viewer.mute", systemImage: isMuted ? "speaker.slash" :"speaker.wave.2")
                                                .foregroundStyle(isMuted ? .red : .primary)
                                                .labelStyle(.iconOnly)
                                                .frame(width: isMACOS ? 10 : 15)
                                                .wrapIf(true) {
                                                    if #available(iOS 18.0, macOS 15.0, *) {
                                                        $0.contentTransition(.symbolEffect(.replace.magic(fallback: .downUp)))
                                                    } else {
                                                        $0
                                                    }
                                                }
//                                                .contentTransition(.symbolEffect(.replace.magic(fallback: .downUp.byLayer), options: .nonRepeating))
                                        })
                                        Button(action: {
                                            interactivePlayerIsInFullScreen = true
                                        }, label: {
                                            Label("Story-viewer.enter-full-screen", systemImage: "arrow.down.backward.and.arrow.up.forward")
                                        })
                                        
                                    }
                                    .wrapIf(true) {
                                        if #available(iOS 26.0, macOS 26.0, *) {
                                            $0.buttonStyle(.glass)
                                        } else {
                                            $0.buttonStyle(.bordered)
                                        }
                                    }
                                    .buttonBorderShape(.capsule)
                                    DetailSectionsSpacer(height: 15)
                                }
                                
                                // Dialog
                                Section {
                                    ForEach(Array(transcript.enumerated()), id: \.element.self) { index, transcript in
                                        switch transcript {
                                        case .notation(let content):
                                            HStack {
                                                Spacer()
                                                Text(content)
                                                    .underline()
                                                    .multilineTextAlignment(.center)
                                                Spacer()
                                            }
                                            .padding(index > 0 && { if case .notation = self.transcript![index - 1] { true } else { false } }() ? .bottom : .vertical)
                                        case .talk(let talk):
                                            CustomGroupBox(cornerRadius: 20) {
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
                                                                switch talk.personGroupType {
                                                                case .single:
                                                                    if let url = talk.characterIconImageURL {
                                                                        WebImage(url: url)
                                                                            .resizable()
                                                                            .frame(width: 20, height: 20)
                                                                    } else {
                                                                        Image(systemName: "person.crop.circle")
                                                                            .bold()
                                                                    }
                                                                case .multiple:
                                                                    Image(systemName: "person.3.fill")
                                                                        .bold()
                                                                        .frame(height: 20)
                                                                case .unknown:
                                                                    Image(systemName: "person.crop.circle.badge.questionmark")
                                                                        .bold()
                                                                        .frame(width: 20, height: 20)
                                                                }
                                                                Text(talk.characterName)
                                                                    .font(.headline)
                                                            }
                                                            .accessibilityElement(children: .combine)
                                                            .accessibilityLabel(talk.characterName)
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
                    
                    if !isMACOS {
                        var insets = geometry.safeAreaInsets
                        insets.bottom += 30
                        self.safeAreaInsets = insets
                    }
                }
            } else {
                ExtendedConstraints {
                    if !isAssetUnavailable {
                        ProgressView()
                            .controlSize(.large)
                    } else {
                        ContentUnavailableView("Story.unavailable", systemImage: "books.vertical")
                    }
                }
            }
        }
        .navigationTitle(title)
        #if os(iOS)
        .toolbar(interactivePlayerIsInFullScreen ? .hidden : .visible, for: .navigationBar)
        .toolbar(interactivePlayerIsInFullScreen ? .hidden : .visible, for: .tabBar)
        #endif
        .navigationBarBackButtonHidden(interactivePlayerIsInFullScreen)
        .withSystemBackground()
        .task {
            await loadTranscript()
        }
        .toolbar {
            if !interactivePlayerIsInFullScreen {
                ToolbarItem {
                    Menu(content: {
                        LocalePicker($locale)
                            .pickerStyle(.inline)
                    }, label: {
                        Image(systemName: "globe")
                    })
                    .onChange(of: locale) {
                        Task {
                            await loadTranscript()
                        }
                    }
                    .menuIndicator(.hidden)
                }
            }
#if os(macOS)
            if AppFlag.DEBUG {
                ToolbarItem {
                    debugMenu
                }
            }
#endif
            if isvAlwaysFullScreen || !isMACOS {
                ToolbarItem {
                    Button(action: {
                        interactivePlayerIsInFullScreen.toggle()
                    }, label: {
                        Image(systemName: "arrow.down.backward.and.arrow.up.forward")
                    })
                }
            }
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
        .onAppear {
            if !ISVHadChosenOption {
                isvLayoutSelectionSheetIsDisplaying = true
            }
            isvLayoutSelectionSheetIsDisplaying = false // MARK: !!!
        }
        .sheet(isPresented: $isvLayoutSelectionSheetIsDisplaying, onDismiss: {
            if !ISVHadChosenOption {
                isvLayoutSelectionSheetIsDisplaying = true
            }
        }) {
            ISVLayoutPickerSheet()
                .interactiveDismissDisabled()
        }
    }
    
    func loadTranscript() async {
        isAssetUnavailable = false
        asset = nil
        transcript = nil
        let newAsset = switch type {
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
        if let newAsset {
            asset = newAsset
            transcript = newAsset.transcript
        } else {
            isAssetUnavailable = true
        }
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
            Menu(String("Debug"), systemImage: "ant") {
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
                            dst.path,
                            inFileViewerRootedAtPath: ""
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

struct ISVLayoutPickerSheet: View {
    @AppStorage("ISVHadChosenOption") var ISVHadChosenOption = false
    @AppStorage("ISVAlwaysFullScreen") var isvAlwaysFullScreen = false
    @State var selection = "N"
    var body: some View {
        NavigationStack {
            /*
            VStack {
                Text("Story-viewer.layout-test-sheet.title")
                    .font(.largeTitle)
                    .bold()
                //            Text()
                Text("Story-viewer.layout-test-sheet.body")
                
                HStack {
                    Text(verbatim: "1")
                    Text(verbatim: "2")
                }
                Spacer()
#if os(iOS)
                Button(action: {
                    
                }, label: {
                    Text(verbatim: "3")
                })
#endif
            }
             */
            EmptyView()
            .padding()
            .toolbar {
#if os(macOS)
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        submit()
                    }, label: {
                        Text(verbatim: "Story-viewer.layout-test-sheet.done")
                    })
                    .disabled(selection == "N")
                }
#endif
            }
        }
    }
    private func submit() {
        isvAlwaysFullScreen = selection == "F"
        ISVHadChosenOption = true
    }
}

extension _DoriAPI.Misc.StoryAsset.Transcript.Talk {
    var personGroupType: PersonGroupType {
        if characterName == "一同"
            || characterName == "全员"
            || characterName == "全員"
            || characterName == "All"
            || characterName.middleContains("・")
            || characterName.middleContains("と")
            || characterName.middleContains("&") {
            return .multiple
        } else if characterName == "???" || characterName == "？？？" {
            return .unknown
        }
        
        return .single
    }
    
    enum PersonGroupType {
        case single
        case multiple
        case unknown
    }
}

extension String {
    fileprivate func middleContains(_ other: some StringProtocol) -> Bool {
        if _fastPath(self.count > 2) {
            self.dropFirst().dropLast().contains(other)
        } else {
            false
        }
    }
}
