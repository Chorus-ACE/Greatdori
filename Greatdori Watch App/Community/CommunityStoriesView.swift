//===---*- Greatdori! -*---------------------------------------------------===//
//
// CommunityStoriesView.swift
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

struct CommunityStoriesView: View {
    @State var posts: _DoriAPI.Posts.PagedPosts?
    @State var availability = true
    @State var pageOffset = 0
    @State var isLoadingMore = false
    var body: some View {
        Form {
            if let posts {
                ForEach(Array(posts.content.enumerated()), id: \.element.id) { (index, post) in
                    VStack(alignment: .leading) {
                        if let storyMeta = post.storyMetadata {
                            HStack {
                                Spacer(minLength: 0)
                                VStack(alignment: .leading) {
                                    Text(post.title)
                                        .font(.headline)
                                    HStack {
                                        Image(systemName: "info.circle.fill")
                                        Text(storyMeta.rating.localizedString)
                                    }
                                    Text(storyMeta.summary)
                                        .font(.system(size: 14))
                                }
                                Spacer(minLength: 0)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.gray.opacity(0.2)))
                        }
                        RichContentView(post.content)
                            .richEmojiFrame(width: 15, height: 15)
                            .font(.system(size: 14))
                    }
                    .onAppear {
                        if !isLoadingMore && index == posts.content.count - 1 {
                            continueLoadPosts()
                        }
                    }
                }
                if isLoadingMore {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
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
                    UnavailableView("载入故事时出错", systemImage: "book.pages.fill", retryHandler: getPosts)
                }
            }
        }
        .navigationTitle("故事")
        .onAppear {
            // SwiftUI's `task` cancels the request immediately after call,
            // we have to use `onAppear`, why?
            Task {
                await getPosts()
            }
        }
    }
    
    func getPosts() async {
        posts = await _DoriAPI.Posts.communityStories(offset: pageOffset)
    }
    func continueLoadPosts() {
        if let posts, posts.hasMore {
            pageOffset = posts.nextOffset
            Task {
                isLoadingMore = true
                if let newPosts = await _DoriAPI.Posts.communityPosts(offset: pageOffset) {
                    self.posts!.content += newPosts.content
                }
                isLoadingMore = false
            }
        }
    }
}
