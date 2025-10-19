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
    @State var infoIsAvailable = true
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
            if infoIsAvailable {
                ProgressView()
                    .onAppear {
                        Task {
                            await getPosts()
                        }
                    }
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
        CustomGroupBox {
            VStack(alignment: .leading) {
                HStack {
                    Text(post.author.nickname)
                    Text("@\(post.author.username)")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(post.time, format: .dateTime) // FIXME: Better Time Logic
                        .foregroundStyle(.secondary)
                    // From Nearst to Farest (CONSIDER LOCALIZATION, DONT JUST USE FORMAT CODE)
                    // 9:41 AM (Today)
                    // Yesterday (Yesterday)
                    // Wednesday (A week ago)
                    // 3/30 (A year ago)
                    // 2017/3/30 (Further)
                }
                .font(.footnote)
                Group {
                    if !post.title.isEmpty {
                        Text(post.title)
                    } else {
                        if let recipient = post.repliesTo?.author {
                            Text("Re: @\(recipient)")
                        } else {
                            Text("Cmt: \("Title")") //FIXME: Cmt:
                        }
                    }
                }
                .bold()
                .font(.title3)
//                Text(post.content)
            }
        }
        .frame(maxWidth: 600)
    }
}
