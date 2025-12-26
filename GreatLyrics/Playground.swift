//===---*- Greatdori! -*---------------------------------------------------===//
//
// Playground.swift
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

import Alamofire
import SwiftyJSON
import SwiftSoup
import SwiftUI

struct PlaygroundView: View {
    @State var inputURL = ""
    @State var fetchResult: String? = nil
    @State var fetchHadFailed = false
    @State var isFetching = false
    var body: some View {
        Form {
            TextField("URL", text: $inputURL)
            Button(action: {
                isFetching = true
                fetchResult = nil
                fetchHadFailed = false
                if let url = URL(string: inputURL) {
                    Task {
                        fetchResult = await fetchLyricsFromMusixmatch(url)
                    }
                } else {
                    fetchHadFailed = true
                }
                isFetching = false
            }, label: {
                HStack {
                    if isFetching {
                        ProgressView()
                            .controlSize(.small)
                    }
                    Text("Fetch")
                }
            })
            .disabled(isFetching)
            if let fetchResult {
                Text(fetchResult)
                    .fontDesign(.monospaced)
            }
            if fetchHadFailed {
                Text("Fetch failed.")
                    .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
    }
}

func fetchLyricsFromMusixmatch(_ url: URL) async -> String? {
    guard url.absoluteString.contains("musixmatch.com") else { return nil }
    
    let html = await withCheckedContinuation { continuation in
        let response = AF.request(url).response { response in
            if let data = response.data, let literalResponse = String(data: data, encoding: .utf8) {
                continuation.resume(returning: literalResponse)
            } else {
                continuation.resume(returning: "")
            }
        }
    }
    
    var literalJSON: String? = ""
    if !html.isEmpty {
        do {
            let document = try SwiftSoup.parse(html)
            let body = document.body()
            let script = try body?.getElementById("__NEXT_DATA__")
            literalJSON = try script?.html()
        } catch {
            print(error)
        }
    }
    
    if let literalJSON, !literalJSON.isEmpty {
        let json = JSON(parseJSON: literalJSON)
        return json["props"]["pageProps"]["data"]["trackInfo"]["data"]["lyrics"]["body"].string
    }
    
    return nil
}
