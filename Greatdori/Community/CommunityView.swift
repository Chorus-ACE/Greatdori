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
import MarkdownUI

struct CommunityView: View {
    @State var posts: DoriAPI.Post.PagedPosts?
    @State var infoIsAvailable = true
    @State var pageOffset = 0
    @State var isLoadingMore = false
    var body: some View {
        NavigationStack {
            Group {
                if let posts {
                    ScrollView {
                        LazyVStack {
                            ForEach(posts.content) { post in
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
                            }
                        }
                        .padding()
                    }
                } else {
                    if infoIsAvailable {
                        ExtendedConstraints {
                            ProgressView()
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
                    switch post.categoryName {
                    case .cardComment:
                        commentSourceTitle = await Card(id: Int(post.categoryID) ?? -1)?.title.forPreferredLocale()
//                    case .chartSimulatorComment:
//                        commentSourceTitle = await()
                    case .characterComment:
                        commentSourceTitle = await Character(id: Int(post.categoryID) ?? -1)?.characterName.forPreferredLocale()
                    case .comicComment:
                        commentSourceTitle = await Comic(id: Int(post.categoryID) ?? -1)?.title.forPreferredLocale()
                    case .costumeComment:
                        commentSourceTitle = await Costume(id: Int(post.categoryID) ?? -1)?.title.forPreferredLocale()
                    case .eventArchiveComment:
                        commentSourceTitle = await Event(id: Int(post.categoryID.split(separator: "_").first!) ?? -1)?.title.forPreferredLocale()
                    case .eventComment:
                        commentSourceTitle = await Event(id: Int(post.categoryID.split(separator: "_").first!) ?? -1)?.title.forPreferredLocale()
                    case .eventTrackerComment:
                        commentSourceTitle = await Event(id: Int(post.categoryID.split(separator: "_").first!) ?? -1)?.title.forPreferredLocale()
                    case .gachaComment:
                        commentSourceTitle = await Gacha(id: Int(post.categoryID) ?? -1)?.title.forPreferredLocale()
                    case .live2dComment:
                        commentSourceTitle = String(post.categoryID.split(separator: "/").last ?? "nil")
                    case .loginCampaignComment:
                        commentSourceTitle = await LoginCampaign(id: Int(post.categoryID) ?? -1)?.title.forPreferredLocale()
                    case .newsComment:
                        commentSourceTitle = await NewsItem(id: Int(post.categoryID) ?? -1)?.title
                    case .songComment:
                        commentSourceTitle = await Song(id: Int(post.categoryID) ?? -1)?.title.forPreferredLocale()
                    case .storyComment:
                        commentSourceTitle = String(post.categoryID.split(separator: "/").last ?? "nil")
                    default:
                        commentSourceTitle = await DoriAPI.Post.basicData(of: post.id)?.title
                    }
                }
            }
            
            Task {
                await handleTags()
            }
        }
    }
    
    @MainActor
    func handleTags() async {
        /*
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
                group.addTask {
                    //FIXME: [251020] Data Race
                    switch tag {
                    case .card(let id):
                        allTags[index] = await Card(id: id)?.title.forPreferredLocale() ?? String(localized: "Community.tags.card.id.\(id)")
                    case .character(let id):
                        allTags[index] = await Character(id: id)?.characterName.forPreferredLocale() ?? String(localized: "Community.tags.character.id.\(id)")
                    case .text(let content):
                        allTags[index] = content
                    default:
                        allTags[index] = String(localized: "Community.tags.unknown")
                    }
                }
            }
        }
        tagsText = allTags.map { "#\($0)" }.joined(separator: "  ")
         */
    }
}

extension DoriAPI.Post.Post {
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
