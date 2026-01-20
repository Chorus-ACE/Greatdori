//===---*- Greatdori! -*---------------------------------------------------===//
//
// NewsDetailsView.swift
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
import MarkdownUI
import SwiftUI
import SymbolAvailability

struct NewsDetailView: View {
    var id: Int
    var title: String
    @State var information: NewsItem? = nil
    @State var informationIsLoading = true
    init(previewNews: PreviewNewsItem) {
        self.id = previewNews.id
        self.title = previewNews.title
    }
    init(id: Int, title: String = String(localized: "News")) {
        self.id = id
        self.title = title
    }
    
    var body: some View {
        Group {
            if let information {
                ScrollView {
                    VStack(alignment: .leading) {
                        HStack {
                            Markdown(information.content.toMarkdown().addMarkdownTitle(title))
                                .markdownImageProvider(.greatdoriRichContentProvider)
                            Spacer()
                        }
                    }
                    .padding()
                                            .textSelection(.enabled)
                }
            } else {
                if informationIsLoading {
                    ExtendedConstraints {
                        ProgressView()
                    }
                } else {
                    ExtendedConstraints {
                        ContentUnavailableView("News.unavailable", systemImage: "newspaper", description: Text("News.unavailable.description"))
                            .onTapGesture {
                                Task {
                                    await getInformation()
                                }
                            }
                    }
                }
            }
        }
        .navigationTitle(title)
        .onAppear {
            Task {
                await getInformation()
            }
        }
    }
    
    private func getInformation() async {
        informationIsLoading = true
        //        informationLoadPromise?.cancel()
        withDoriCache(id: "NewsDetail_\(id)") {
            await NewsItem(id: id)
        } .onUpdate {
            if let information = $0 {
                self.information = information
            }
            informationIsLoading = false
        }
    }
}

struct GreatdoriRichContentProvider: ImageProvider {
    private let validContentSources = ["asset", "event"]
    func makeImage(url: URL?) -> some View {
        if let richContentID = extractRichContentIDFromPath(url), validContentSources.contains(richContentID.0) {
            GreatdoriRichContentRenderer(richContentID: richContentID)
        } else {
            // Normal Image Renderer
            // Editable
            DefaultImageProvider().makeImage(url: url)
        }
    }
    
    func extractRichContentIDFromPath(_ url: URL?) -> (String, String)? {
        guard url != nil else { return nil }
        if url!.absoluteString.hasPrefix("greatdori://rich-content/") {
            let path = url!.absoluteString.dropFirst("greatdori://rich-content/".count)
            let spliitedPath = path.split(separator: "/")
            
            guard spliitedPath.count >= 2 else { return nil }
            if spliitedPath.first == "asset" {
                return (String(spliitedPath[0]), String(path.dropFirst("asset/".count)))
            } else if validContentSources.contains(String(spliitedPath.first ?? "")) {
                guard Int(spliitedPath[1]) != nil else { return nil }
                return (String(spliitedPath[0]), String(spliitedPath[1]))
            } else {
                return nil
            }
        } else {
            return nil
        }
    }
    
    private struct GreatdoriRichContentRenderer: View {
        var richContentID: (String, String)
        @State var information: Any? = nil
        var body: some View {
            Group {
                if let information {
                    switch richContentID.0 {
                    case "asset":
                        Text(richContentID.1)
                    case "event":
                        EventInfo(information as! Event)
                    default:
                        Image(systemName: .questionmarkCircle)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ProgressView()
                }
            }
            .padding(5)
            .onAppear {
                if richContentID.0 == "asset" {
                    
                } else if let numericalID = Int(richContentID.1) {
                    Task {
                        switch richContentID.0 {
                        case "event":
                            information = await Event(id: numericalID)
                        default:
                            information = 0
                        }
                    }
                } else {
                    information = 0
                }
            }
        }
    }
}

extension ImageProvider where Self == GreatdoriRichContentProvider {
    static var greatdoriRichContentProvider: Self {
        .init()
    }
}


extension String {
    func addMarkdownTitle(_ title: String) -> String {
        return isMACOS ? ("#\(title)\n" + self) : self
    }
}
