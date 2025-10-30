//===---*- Greatdori! -*---------------------------------------------------===//
//
// CommunityView.swift
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
import SwiftUI
import MarkdownUI

struct CommunityView: View {
    @State var posts: _DoriAPI.Posts.PagedPosts?
    @State var infoIsAvailable = true
    @State var pageOffset = 0
    @State var isLoadingMore = false
    var body: some View {
        NavigationStack {
            Group {
                if let posts {
                    ScrollView {
                        LazyVStack {
                            ForEach(Array(posts.content.enumerated()), id: \.element.id) { index, post in
                                PostSectionView(post: post)
                                    .swipeActions {
                                        Button(action: {
                                            
                                        }, label: {
                                            if post.liked {
                                                Label("Community.like", systemImage: "heart")
                                                    .foregroundStyle(.red)
                                            } else {
                                                Label("Community.remove-like", systemImage: "heart.slash.fill")
                                                    .foregroundStyle(.red)
                                            }
                                        })
                                    }
                                    .onAppear {
                                        if index == posts.content.count - 1 {
                                            continueLoadPosts()
                                        }
                                    }
                            }
                            if isLoadingMore {
                                ProgressView()
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        await getPosts()
                    }
                } else {
                    if infoIsAvailable {
                        ExtendedConstraints {
                            ProgressView()
                                .controlSize(.large)
                        }
                        .onAppear {
                            Task {
                                await getPosts()
                            }
                        }
                    } else {
                        ExtendedConstraints {
                            ContentUnavailableView("Community.unavailable", systemImage: "richtext.page.fill")
                        }
                        .onTapGesture {
                            Task {
                                await getPosts()
                            }
                        }
                    }
                }
            }
            .withSystemBackground()
            .navigationTitle(isMACOS || posts != nil ? "Community" : "")
        }
    }
    
    func getPosts() async {
        posts = await _DoriAPI.Posts.communityAll(offset: pageOffset)
    }
    func continueLoadPosts() {
        guard !isLoadingMore else { return }
        if let posts, posts.hasMore {
            pageOffset = posts.nextOffset
            Task {
                isLoadingMore = true
                if let newPosts = await _DoriAPI.Posts.communityAll(offset: pageOffset) {
                    self.posts!.content += newPosts.content
                }
                isLoadingMore = false
            }
        }
    }
}

private struct PostSectionView: View {
    var post: _DoriAPI.Posts.Post
    @State var commentSourceTitle: String?
    @State var tagsText: String = ""
    var body: some View {
        CustomGroupBox {
            VStack(alignment: .leading) {
                HStack {
                    if !post.author.nickname.isEmpty {
                        Text(post.author.nickname)
                        Text("@\(post.author.username)")
                            .foregroundStyle(.secondary)
                    } else {
                        Text("@\(post.author.username)")
                    }
                    Spacer()
                    Group {
                        if post.likes != 0 {
                            HStack(spacing: 0) {
                                Image(systemName: post.liked ? "heart.fill" : "heart")
                                Text("\(post.likes)")
                            }
                        }
                        Text(post.time.formattedRelatively())
                        Image(systemName: post.getPostTypeSymbol())
                    }
                    .foregroundStyle(.gray)
                    .wrapIf(!isMACOS, in: { content in
                        #if os(iOS)
                        Menu(content: {
                            Button(action: {
                                
                            }, label: {
                                if !post.liked {
                                    Label("Community.like", systemImage: "heart")
                                } else {
                                    Label("Community.remove-like", systemImage: "heart.slash")
                                }
                            })
                        }, label: {
                            content
                        })
                        .menuStyle(.borderlessButton)
                        #endif
                    })
                    
                }
                .font(.footnote)
                Group {
                    if !post.title.isEmpty {
                        Text(post.title)
                    } else {
                        if let recipient = post.repliesTo?.author {
                            Text("Community.title.re.\("@\(recipient)")")
                        } else {
                            Text("Community.title.cmt.\(commentSourceTitle ?? "nil")")
                                .wrapIf(commentSourceTitle == nil, in: { content in
                                    content
                                        .redacted(reason: .placeholder)
                                })
                        }
                    }
                }
                .bold()
                .font(.title3)
                Markdown(post.content.toMarkdown())
                    .markdownInlineImageProvider(.postContent(imageFrame: .init(width: 20, height: 20)))
                if !tagsText.isEmpty {
                    Text(tagsText)
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
        }
        .frame(maxWidth: 600)
        .textSelection(.enabled)
        .onAppear {
            if commentSourceTitle == nil {
                Task {
                    switch await post.parent {
                    case .post(let basicData):
                        commentSourceTitle = basicData.title
                    case .news(let item):
                        commentSourceTitle = item.title
                    case .character(let character):
                        commentSourceTitle = character.characterName.forPreferredLocale()
                    case .card(let card):
                        commentSourceTitle = card.prefix.forPreferredLocale()
                    case .costume(let costume):
                        commentSourceTitle = costume.description.forPreferredLocale()
                    case .event(let event):
                        commentSourceTitle = event.eventName.forPreferredLocale()
                    case .gacha(let gacha):
                        commentSourceTitle = gacha.gachaName.forPreferredLocale()
                    case .song(let song):
                        commentSourceTitle = song.musicTitle.forPreferredLocale()
                    case .loginCampaign(let campaign):
                        commentSourceTitle = campaign.caption.forPreferredLocale()
                    case .comic(let comic):
                        commentSourceTitle = comic.title.forPreferredLocale()
                    case .eventTracker(let event):
                        commentSourceTitle = event.eventName.forPreferredLocale()
                    case .chartSimulator(let song):
                        commentSourceTitle = song.musicTitle.forPreferredLocale()
                    case .live2d, .story:
                        commentSourceTitle = String(post.categoryID.split(separator: "/").last ?? "nil")
                    default: break
                    }
                }
            }
            
            Task {
                await handleTags()
            }
        }
    }
    
    func handleTags() async {
        var allTags: [String] = []
        
        if !post.tags.isEmpty {
            for (index, tag) in post.tags.enumerated() {
                if index != 0 {
                    allTags.append("  ")
                }
                switch tag {
                case .card(let id):
                    allTags.append(String(localized: "Community.tags.card.id.\(id)"))
                case .character(let id):
                    allTags.append(String(localized: "Community.tags.character.id.\(id)"))
                case .text(let content):
                    allTags.append(content)
                default:
                    allTags.append(String(localized: "Community.tags.unknown"))
                }
            }
        }
        
        tagsText = allTags.map { "#\($0)" }.joined(separator: "  ")
        
        await withTaskGroup { group in
            for (index, tag) in post.tags.enumerated() {
                group.addTask { () -> (Int, String) in
                    switch tag {
                    case .card(let id):
                        (index, await Card(id: id)?.title.forPreferredLocale() ?? String(localized: "Community.tags.card.id.\(id)"))
                    case .character(let id):
                        (index, await Character(id: id)?.characterName.forPreferredLocale() ?? String(localized: "Community.tags.character.id.\(id)"))
                    case .text(let content):
                        (index, content)
                    default:
                        (index, String(localized: "Community.tags.unknown"))
                    }
                }
            }
            for await (index, newTag) in group {
                allTags[index] = newTag
            }
        }
        tagsText = allTags.map { "#\($0)" }.joined(separator: "  ")
    }
}

extension _DoriAPI.Posts.Post {
    func getPostTypeSymbol() -> String {
        if self.categoryID == "chart" {
            return "apple.classical.pages"
        } else if self.categoryID == "story" {
            return "book"
        } else if self.categoryName == .selfPost {
            return "text.bubble"
        } else {
            return "arrowshape.turn.up.left"
        }
    }
}

struct PostContentInlineImageProvider: InlineImageProvider {
    var imageFrame: CGSize
    func image(with url: URL, label: String) async throws -> Image {
        await RichContentGroup.resolveMarkdownImage(
            url: url,
            label: label,
            emojiIdealSize: imageFrame
        )
            
    }
}
extension InlineImageProvider where Self == PostContentInlineImageProvider {
    static func postContent(imageFrame: CGSize) -> Self {
        .init(imageFrame: imageFrame)
    }
}
