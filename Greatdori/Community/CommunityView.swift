//===---*- Greatdori! -*---------------------------------------------------===//
//
// CommunityView.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.memz.top/LICENSE.txt for license information
// See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//

import DoriKit
import SwiftUI

struct CommunityView: View {
    @State var posts: DoriAPI.Post.PagedPosts?
    @State var availability = true
    @State var pageOffset = 0
    @State var isLoadingMore = false
    var body: some View {
        if let posts {
            ScrollView {
                LazyVStack {
                    ForEach(posts.content) { post in
                        PostSectionView(post: post)
                    }
                }
                .padding()
            }
        } else {
            if availability {
                ProgressView()
            } else {
                ExtendedConstraints {
                    ContentUnavailableView("载入帖子时出错", systemImage: "richtext.page.fill")
                }
                .onTapGesture {
                    Task {
                        await getPosts()
                    }
                }
            }
        }
    }
    
    func getPosts() async {
        posts = await DoriAPI.Post.communityAll(offset: pageOffset)
    }
    func continueLoadPosts() {
        if let posts, posts.hasMore {
            pageOffset = posts.nextOffset
            Task {
                isLoadingMore = true
                if let newPosts = await DoriAPI.Post.communityAll(offset: pageOffset) {
                    self.posts!.content += newPosts.content
                }
                isLoadingMore = false
            }
        }
    }
}

private struct PostSectionView: View {
    var post: DoriAPI.Post.Post
    var body: some View {
        EmptyView() // FIXME
    }
}
