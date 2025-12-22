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
#if os(iOS)
import Mute
#endif
import SwiftUI
import SDWebImageSwiftUI

struct StoryDetailView: View {
    var title: LocalizedData<String>
    var scenarioID: String
    var voiceAssetBundleName: String?
    var type: StoryType
    var unsafeAssociatedID: String // WTF --@WindowsMEMZ
    var unsafeSecondaryAssociatedID: String?
    @State var isvLayoutSelectionSheetIsDisplaying = false
    @State var locale: _DoriAPI.Locale
    @State var asset: _DoriAPI.Misc.StoryAsset?
    @State var ir: StoryIR?
    @State var transcript: [NeoTranscript]?
    @State var isAssetUnavailable = false
    @State var isvCurrentBlockingActionIndex: Int?
    
    @AppStorage("ISVAlwaysFullScreen") var isvAlwaysFullScreen = false
    @AppStorage("ISVHadChosenOption") var ISVHadChosenOption = false
    @State var audioPlayer = AVPlayer()
    @State var interactivePlayerIsInFullScreen = false
    @State var screenWidth: CGFloat = 0
    @State var screenHeight: CGFloat = 0
    @State var safeAreaInsets = EdgeInsets()
    @State var isMuted = false
    
    init(
        title: LocalizedData<String>,
        scenarioID: String,
        voiceAssetBundleName: String? = nil,
        type: StoryType,
        locale: DoriLocale,
        unsafeAssociatedID: String,
        unsafeSecondaryAssociatedID: String? = nil
    ) {
        self.title = title
        self.scenarioID = scenarioID
        self.voiceAssetBundleName = voiceAssetBundleName
        self.type = type
        self._locale = .init(initialValue: locale)
        self.unsafeAssociatedID = unsafeAssociatedID
        self.unsafeSecondaryAssociatedID = unsafeSecondaryAssociatedID
    }
    init(
        title: String,
        scenarioID: String,
        voiceAssetBundleName: String? = nil,
        type: StoryType,
        locale: DoriLocale,
        unsafeAssociatedID: String,
        unsafeSecondaryAssociatedID: String? = nil
    ) {
        self.init(
            title: .init(repeating: title),
            scenarioID: scenarioID,
            voiceAssetBundleName: voiceAssetBundleName,
            type: type,
            locale: locale,
            unsafeAssociatedID: unsafeAssociatedID,
            unsafeSecondaryAssociatedID: unsafeSecondaryAssociatedID
        )
    }
    
    var body: some View {
        ZStack {
            if let transcript {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack {
                            // MARK: - ISV
                            if !isvAlwaysFullScreen || interactivePlayerIsInFullScreen {
                                Section {
                                    Group {
                                        if let ir {
                                            InteractiveStoryView(ir, fullScreenToggleIsAvailable: true, mutingIsAvailable: true)
                                        } else {
                                            ProgressView()
                                        }
                                    }
                                    .safeAreaPadding(interactivePlayerIsInFullScreen ? safeAreaInsets : .init())
                                    .aspectRatio(interactivePlayerIsInFullScreen ? screenWidth/screenHeight : 16/10, contentMode: .fit)
                                    .clipped()
                                    .isvIsMuted($isMuted)
                                    .isvIsInFullScreen($interactivePlayerIsInFullScreen)
                                    .isvCurrentBlockingActionIndex($isvCurrentBlockingActionIndex)
                                }
                                .frame(maxWidth: interactivePlayerIsInFullScreen ? nil : infoContentMaxWidth)
                            }
                            
                            if !interactivePlayerIsInFullScreen {
                                if !isvAlwaysFullScreen {
                                    // MARK: - Control Bar
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
                                
                                // MARK: - Transcript
                                Section {
                                    ForEach(Array(transcript.enumerated()), id: \.element.self) { index, transcript in
                                        if transcript.isTelop {
                                            HStack {
                                                Spacer()
                                                Text(transcript.text)
                                                    .underline()
                                                    .multilineTextAlignment(.center)
                                                    .foregroundStyle(isvCurrentBlockingActionIndex == transcript.sourceIndex ?? -3417 ? .accent : .primary)
                                                Spacer()
                                            }
                                            .padding(index > 0 && self.transcript![index - 1].isTelop ? .bottom : .vertical)
                                        } else {
                                            CustomGroupBox(cornerRadius: 20) {
                                                Button(action: {
                                                    if let voiceID = transcript.voiceID {
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
                                                                switch transcript.characterType {
                                                                case .single:
                                                                    if let url = transcript.characterIconImageURL {
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
                                                                Text(transcript.characterName ?? "Character.unknown")
                                                                    .font(.headline)
                                                                Spacer()
                                                                if AppFlag.ISV_DEBUG {
                                                                    if let index = transcript.sourceIndex {
                                                                        Text(verbatim: "#\(index)")
                                                                            .foregroundStyle(.secondary)
                                                                    }
                                                                }
                                                            }
                                                            .accessibilityElement(children: .combine)
                                                            .accessibilityLabel(transcript.characterName ?? "Character.unknown")
                                                            Text(transcript.text)
                                                                .font(.body)
                                                                .multilineTextAlignment(.leading)
                                                                .fixedSize(horizontal: false, vertical: true)
                                                        }
                                                        Spacer()
                                                    }
                                                    .foregroundStyle(Color.primary)
                                                })
                                                .buttonStyle(.borderless)
                                            }
                                            .groupBoxStrokeLineWidth(isvCurrentBlockingActionIndex == transcript.sourceIndex ?? -3417 ? 3 : 0)
//                                            .groupBoxBackgroundTintOpacity(isvCurrentBlockingActionIndex == transcript.sourceIndex ?? -3417 ? 0.5: 0)
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
        .navigationTitle(title.forLocale(locale) ?? String(localized: "Story"))
#if os(iOS)
        .toolbar(interactivePlayerIsInFullScreen ? .hidden : .visible, for: .navigationBar)
        .toolbar(interactivePlayerIsInFullScreen ? .hidden : .visible, for: .tabBar)
#endif
        .navigationBarBackButtonHidden(interactivePlayerIsInFullScreen)
        .withSystemBackground()
        .task {
            await loadAssets()
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
                            await loadAssets()
                        }
                    }
                    //                    .menuIndicator(.hidden)
                }
            }
#if os(macOS)
            if AppFlag.ISV_DEBUG {
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
#if os(iOS)
            if Mute.shared.isMute {
                isMuted = true
                print("SILENT MODE: MUTE")
            }
#endif
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
    
    
    func loadAssets() async {
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
            ir = getIR(scenarioID: scenarioID, voiceAssetBundleName: voiceAssetBundleName, type: type, locale: locale, unsafeAssociatedID: unsafeAssociatedID, unsafeSecondaryAssociatedID: unsafeSecondaryAssociatedID, asset: newAsset)
            if let ir {
                transcript = DoriStoryBuilder.Conversion.neoTranscript(fromIR: ir)
            }
        } else {
            isAssetUnavailable = true
        }
    }
    
    func getIR(scenarioID: String, voiceAssetBundleName: String?, type: StoryType, locale: DoriLocale, unsafeAssociatedID: String, unsafeSecondaryAssociatedID: String?, asset: _DoriAPI.Misc.StoryAsset) -> StoryIR {
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
        return DoriStoryBuilder.Conversion.zeileIR(fromBandori: asset, in: locale, voiceBundlePath: voiceBundlePath)
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
                    Button(action: {
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
                    }, label: {
                        Label(String("Dump IR"), systemImage: "text.word.spacing")
                    })
                    
                    Button(action: {
                        let downloadBase = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                        let dst = downloadBase.appending(path: "JsonIR.txt")
                        let ir = DoriStoryBuilder.Conversion.zeileIR(
                            fromBandori: asset,
                            in: locale,
                            voiceBundlePath: voiceBundlePath
                        )
                        let text = DoriStoryBuilder.Conversion.bestdoriJSON(fromIR: ir)
                        if let text {
                            try? text.write(to: dst, atomically: true, encoding: .utf8)
                            NSWorkspace.shared.selectFile(
                                dst.path,
                                inFileViewerRootedAtPath: ""
                            )
                        }
                    }, label: {
                        Label(String("JSON IR"), systemImage: "curlybraces")
                    })
                    
                    Button(action: {
                        let downloadBase = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
                        let dst = downloadBase.appending(path: "Sirius.txt")
                        let ir = DoriStoryBuilder.Conversion.zeileIR(
                            fromBandori: asset,
                            in: locale,
                            voiceBundlePath: voiceBundlePath
                        )
                        let text = DoriStoryBuilder.Conversion.sirius(fromIR: ir)
                        //                        if let text {
                        try? text.write(to: dst, atomically: true, encoding: .utf8)
                        NSWorkspace.shared.selectFile(
                            dst.path,
                            inFileViewerRootedAtPath: ""
                        )
                        //                        }
                    }, label: {
                        Label(String("Sirius"), systemImage: "sparkles")
                    })
                }
            }
            .menuIndicator(.hidden)
            .menuStyle(.button)
        }
    }
#endif
    
    /*
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
     */
}
