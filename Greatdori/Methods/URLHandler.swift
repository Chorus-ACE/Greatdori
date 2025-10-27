//===---*- Greatdori! -*---------------------------------------------------===//
//
// URLHandler.swift
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

@MainActor
func _handleURL(_ url: URL) {
    let urlString = url.absoluteString
    let fixedURLString = urlString.replacing(/^https:\/\/greatdori.com\//, with: "greatdori://")
    guard let _url = URL(string: fixedURLString),
          let components = URLComponents(url: _url, resolvingAgainstBaseURL: false) else { return }
    switch components.host {
    case "flag":
        if let items = components.queryItems {
            for item in items {
                if let value = item.value {
                    AppFlag.set((Int(value) ?? (value == "true" ? 1 : 0)) != 0, forKey: item.name)
                }
            }
        }
    case "home":
        let paths = components.path.split(separator: "/")
        if paths.count > 0 {
            switch paths[0]{
            case "news":
                if paths.count > 1, let id = Int(paths[1]) {
                    rootShowView {
                        NewsDetailView(id: id)
                    }
                } else {
                    rootShowView {
                        NewsView()
                    }
                }
            default: break
            }
        }
    case "info":
        let paths = components.path.split(separator: "/")
        if paths.count >= 2 {
            if let id = Int(paths[1]) {
                switch paths[0] {
                case "characters":
                    rootShowView {
                        CharacterDetailView(id: id)
                    }
                case "cards":
                    rootShowView {
                        CardDetailView(id: id)
                    }
                case "costumes":
                    rootShowView {
                        CostumeDetailView(id: id)
                    }
                case "events":
                    rootShowView {
                        EventDetailView(id: id)
                    }
                case "gacha":
                    rootShowView {
                        GachaDetailView(id: id)
                    }
                case "songs":
                    rootShowView {
                        SongDetailView(id: id)
                    }
                case "logincampaigns":
                    rootShowView {
                        LoginCampaignDetailView(id: id)
                    }
                case "comics":
                    rootShowView {
                        ComicDetailView(id: id)
                    }
                default: break
                }
            }
        } else if paths.count > 0 {
            switch paths[0] {
            case "characters":
                rootShowView {
                    CharacterSearchView()
                }
            case "cards":
                rootShowView {
                    CardSearchView()
                }
            case "costumes":
                rootShowView {
                    CostumeSearchView()
                }
            case "events":
                rootShowView {
                    EventSearchView()
                }
            case "gacha":
                rootShowView {
                    GachaSearchView()
                }
            case "songs":
                rootShowView {
                    SongSearchView()
                }
            case "songmeta":
                rootShowView {
                    EmptyView() // FIXME
                }
            case "logincampaigns":
                rootShowView {
                    LoginCampaignSearchView()
                }
            case "miracleticket":
                rootShowView {
                    EmptyView() // FIXME
                }
            case "comics":
                rootShowView {
                    ComicSearchView()
                }
            default: break
            }
        }
    case "tool":
        let paths = components.path.split(separator: "/")
        if paths.count > 0 {
            switch paths[0] {
            case "eventtracker":
                rootShowView {
                    EventTrackerView()
                }
            case "playersearch":
                rootShowView {
                    EmptyView() // FIXME
                }
            case "chartsimulator", "chart", "simulator":
                rootShowView {
                    ChartSimulatorView()
                }
            case "live2d":
                rootShowView {
                    Live2DViewerView()
                }
            case "storyviewer":
                rootShowView {
                    StoryViewerView()
                }
            case "explorer":
                if paths.count > 1, paths[1] == "asset" {
                    rootShowView {
                        AssetExplorerView()
                    }
                }
            default: break
            }
        }
    default: break
    }
}
