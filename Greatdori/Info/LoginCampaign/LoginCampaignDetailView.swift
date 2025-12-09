//===---*- Greatdori! -*---------------------------------------------------===//
//
// LoginCampaignDetailView.swift
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
import SDWebImageSwiftUI


// MARK: LoginCampaignDetailView
struct LoginCampaignDetailView: View {
    var id: Int
    var allLoginCampaigns: [PreviewLoginCampaign]? = nil
    var body: some View {
        DetailViewBase(forType: LoginCampaign.self, previewList: allLoginCampaigns, initialID: id) { information in
            LoginCampaignDetailOverviewView(information: information)
            DetailArtsSection {
                ArtsTab("Login-campaign.arts.background", ratio: 600/360) {
                    for locale in DoriLocale.allCases {
                        if let url = information.backgroundImageURL(in: locale, allowsFallback: false) {
                            ArtsItem(title: LocalizedStringResource(stringLiteral: locale.rawValue.uppercased()), url: url, forceApplyRatio: true)
                        }
                    }
                }
            }
            ExternalLinksSection(links: [ExternalLink(name: "External-link.bestdori", url: URL(string: "https://bestdori.com/info/logincampaigns/\(id)")!)])
        } switcherDestination: {
            LoginCampaignSearchView()
        }
    }
}

struct LoginCampaignDetailOverviewView: View {
    let information: LoginCampaign
    var dateFormatter: DateFormatter { let df = DateFormatter(); df.dateStyle = .long; df.timeStyle = .short; return df }
    
    @State var backgroundImageIsHidden = false
    var body: some View {
        VStack {
            Group {
                if !backgroundImageIsHidden {
                    Group {
                        Rectangle()
                            .opacity(0)
                            .frame(height: 2)
                        WebImage(url: information.backgroundImageURL, content: { image in
                            image
                                .resizable()
                                .antialiased(true)
                                .aspectRatio(184/110, contentMode: .fit)
                        }, placeholder: {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(getPlaceholderColor())
                                .aspectRatio(184/110, contentMode: .fit)
                        })
                        .onFailure { _ in
                            backgroundImageIsHidden = true
                        }
                        .interpolation(.high)
                        .frame(maxWidth: bannerWidth, maxHeight: bannerWidth/3)
                        .cornerRadius(10)
                        Rectangle()
                            .opacity(0)
                            .frame(height: 2)
                    }
                }
                
                CustomGroupBox {
                    LazyVStack {
                        Group {
                            ListItem {
                                Text("Login-campaign.title")
                            } value: {
                                MultilingualText(information.title)
                            }
                            Divider()
                        }
                        
                        Group {
                            ListItem {
                                Text("Login-campaign.type")
                            } value: {
                                Text(information.loginBonusType.localizedString)
                            }
                            Divider()
                        }
                        
                        Group {
                            ListItem {
                                Text("Login-campaign.start-date")
                            } value: {
                                MultilingualText(information.publishedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                            }
                            Divider()
                        }
                        
                        Group {
                            ListItem {
                                Text("Login-campaign.close-date")
                            } value: {
                                MultilingualText(information.closedAt.map{dateFormatter.string(for: $0)}, showLocaleKey: true)
                            }
                            Divider()
                        }
                        
                        ListItem {
                            Text("ID")
                        } value: {
                            Text("\(String(information.id))")
                        }
                    }
                }
            }
        }
        .frame(maxWidth: infoContentMaxWidth)
    }
}
