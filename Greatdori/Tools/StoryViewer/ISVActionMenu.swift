//===---*- Greatdori! -*---------------------------------------------------===//
//
// ISVActionMenu.swift
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
//
//import SwiftUI
//
//@ViewBuilder
//func ISVActionMenu(inout isAutoPlaying: Bool, inout uiIsHiding: Bool, ) {
//    Menu {
//        Section {
//            // AUTO-PLAY
//            Button(action: {
//                isAutoPlaying.toggle()
//                if isAutoPlaying {
//                    next()
//                } else {
//                    autoPlayTimer?.invalidate()
//                }
//            }, label: {
//                Label(isAutoPlaying ? "Story-viewer.menu.auto.cancel" : "Story-viewer.menu.auto", systemImage: isAutoPlaying ? "play.slash" : "play")
//            })
//            
//            // HIDE & AUTO-PLAY
//            Button(action: {
//                isAutoPlaying = true
//                uiIsHiding = true
//                next()
//            }, label: {
//                Label("Story-viewer.menu.hide-ui-auto", systemImage: "pano.badge.play")
//            })
//            .disabled(talkAudios.isEmpty)
//            
//            // FAST FORWARD
//            Button(action: {
//                if fastForwardTimer != nil {
//                    fastForwardTimer?.invalidate()
//                    fastForwardTimer = nil
//                    return
//                }
//                //                    fastForwardTimer = .scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
//                //                        DispatchQueue.main.async {
//                //                            next(ignoresDelay: true)
//                //                        }
//                //                    }
//            }, label: {
//                if fastForwardTimer == nil {
//                    Label("Story-viewer.menu.fast-forward", systemImage: "forward")
//                } else {
//                    Label("Story-viewer.menu.fast-forward.cancel", image: "custom.forward.slash")
//                }
//            })
//            
//            // BACKLOG
//            Button(action: {
//                backlogIsPresenting = true
//            }, label: {
//                Label("Story-viewer.menu.backlog", systemImage: "text.document")
//            })
//            .disabled(currentTalk == nil)
//            
//            // HIDE UI
//            Button(action: {
//                uiIsHiding = true
//            }, label: {
//                Label("Story-viewer.menu.hide", systemImage: "xmark")
//            })
//            
//            if isvAlwaysFullScreen || !fullScreenToggleIsAvailable {
//                // QUIT
//                Button(role: .destructive, action: {
//                    exitViewer()
//                }, label: {
//                    Label("Story-viewer.menu.quit", systemImage: "escape")
//                })
//                .foregroundStyle(.red)
//            } else {
//                // FULL SCREEN
//                Button(action: {
//                    interactivePlayerIsInFullScreen.toggle()
//                }, label: {
//                    if interactivePlayerIsInFullScreen {
//                        Label("Story-viewer.menu.full-screen.quit", systemImage: "arrow.down.right.and.arrow.up.left")
//                    } else {
//                        Label("Story-viewer.menu.full-screen.enter", systemImage: "arrow.up.left.and.arrow.down.right")
//                    }
//                })
//            }
//        }
//    } label: {
//        Image(systemName: "ellipsis")
//        //                .font(.title)
//        //            #if os(iOS)
//        //                .font(.system(size: 20))
//        //                .padding(12)
//        //            #endif
//    }
//    .menuStyle(.button)
//    .menuIndicator(.hidden)
//}
