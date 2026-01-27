//===---*- Greatdori! -*---------------------------------------------------===//
//
// StoryCardView.swift
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
import SDWebImageSwiftUI
import SwiftUI

struct StoryCardView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var scenarioID: String
    var caption: String
    var title: LocalizedData<String>
    var synopsis: String
    var voiceAssetBundleName: String?
    var storyNote: String?
    
    var type: StoryType
    var locale: DoriAPI.Locale
    var unsafeAssociatedID: String
    var unsafeSecondaryAssociatedID: String?
    var notes: String?
    var images: [URL] = []
    var characterIDs: [Int]?
    
    init(story: DoriAPI.Story, type: StoryType, locale: DoriAPI.Locale, unsafeAssociatedID: String, unsafeSecondaryAssociatedID: String? = nil, notes: String? = nil) {
        self.scenarioID = story.scenarioID
        self.caption = story.caption.forLocale(locale) ?? ""
        self.title = story.title
        self.synopsis = story.synopsis.forLocale(locale) ?? ""
        self.voiceAssetBundleName = story.voiceAssetBundleName
        self.type = type
        self.locale = locale
        self.unsafeAssociatedID = unsafeAssociatedID
        self.unsafeSecondaryAssociatedID = unsafeSecondaryAssociatedID
        self.notes = notes
        self.storyNote = nil
        self.characterIDs = nil
    }
    init(story: CustomStory, type: StoryType, locale: DoriAPI.Locale, unsafeAssociatedID: String, unsafeSecondaryAssociatedID: String? = nil, notes: String? = nil, images: [URL] = [], characterIDs: [Int]? = nil) {
        self.scenarioID = story.scenarioID
        self.caption = story.caption
        self.title = story.title
        self.synopsis = story.synopsis
        self.voiceAssetBundleName = story.voiceAssetBundleName
        self.type = type
        self.locale = locale
        self.unsafeAssociatedID = unsafeAssociatedID
        self.unsafeSecondaryAssociatedID = unsafeSecondaryAssociatedID
        self.notes = notes
        self.storyNote = story.note
        self.images = images
        self.characterIDs = characterIDs
    }
    
    var body: some View {
        NavigationLink(destination: {
            StoryDetailView(
                title: title,
                scenarioID: scenarioID,
                voiceAssetBundleName: voiceAssetBundleName,
                type: type,
                locale: locale,
                unsafeAssociatedID: unsafeAssociatedID,
                unsafeSecondaryAssociatedID: unsafeSecondaryAssociatedID
            )
        }) {
            CustomGroupBox(cornerRadius: 20) {
                HStack {
                    VStack(alignment: .leading) {
                        if type != .card {
                            Text(verbatim: "\(caption)\(getLocalizedColon(forLocale: locale))\(title.forLocale(locale) ?? "")")
                                .font(.headline)
                            HStack {
                                if let characterIDs {
                                    ForEach(characterIDs, id: \.self) { item in
                                        WebImage(url: URL(string: "https://bestdori.com/res/icon/chara_icon_\(item).png")!)
                                            .resizable()
                                            .clipShape(Circle())
                                            .frame(width: 25, height: 25)
                                    }
                                }
                                
                                Text(synopsis)
                                    .foregroundStyle(.secondary)
                            }
                            
                            if let notes, sizeClass == .compact {
                                Text(notes)
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                    .padding(.top, 1)
                            }
                        } else {
                            Text(caption)
                            Text(title.forLocale(locale) ?? "")
                                .bold()
                                .font(.title3)
                        }
                    }
                    Spacer()
                    if let notes, sizeClass == .regular {
                        Text(notes)
                            .foregroundStyle(.secondary)
                    }
                    if !images.isEmpty {
                        FallbackableWebImage(throughURLs: images)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 60)
                    }
                }
            }
            .typesettingLanguage(locale.nsLocale().language)
        }
        .buttonStyle(.plain)
        .buttonBorderShape(.roundedRectangle(radius: 20))
    }
}
