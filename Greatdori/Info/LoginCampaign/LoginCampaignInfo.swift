//===---*- Greatdori! -*---------------------------------------------------===//
//
// LoginCampaignInfo.swift
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


// MARK: LoginCampaignInfo
struct LoginCampaignInfo: View {
    @State var information: PreviewLoginCampaign
    var layout: SummaryLayout
    
    init(_ campaign: PreviewLoginCampaign, layout: SummaryLayout = .horizontal) {
        self.information = campaign
        self.layout = layout
    }
    
    init(_ campaign: LoginCampaign, layout: SummaryLayout = .horizontal) {
        self.information = PreviewLoginCampaign(campaign)
        self.layout = layout
    }
    
    var body: some View {
        SummaryViewBase(layout, source: information) {
            WebImage(url: information.backgroundImageURL) { image in
                image
                    .resizable()
                    .antialiased(true)
                    .aspectRatio(184/110, contentMode: .fit)
                    .frame(width: 184, height: 110)
                    .cornerRadius(5)
            } placeholder: {
                RoundedRectangle(cornerRadius: 5)
                    .fill(getPlaceholderColor())
                    .frame(width: 184, height: 110)
            }
            .interpolation(.high)
        } detail: {
            Text(information.loginBonusType.localizedString)
                .font(isMACOS ? .body : .caption)
        }
    }
}




/*
 // MARK: LoginCampaignInfo
 struct LoginCampaignInfo: View {
 @Binding var searchedKeyword: String
 @State var attributedTitle: AttributedString?
 
 @State var information: PreviewLoginCampaign?
 @State var currentID: Int
 
 var preferHeavierFonts: Bool = true
 var locale: DoriAPI.Locale?
 var showDetails: Bool
 var showID: Bool
 
 init(_ campaign: PreviewLoginCampaign, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, subtitle: LocalizedStringKey? = nil, showDetails: Bool = false, showID: Bool = false, searchedKeyword: Binding<String> = .constant("")) {
 self.information = campaign
 self.currentID = campaign.id
 
 self.preferHeavierFonts = preferHeavierFonts
 self.locale = locale
 self.showDetails = showDetails
 self.showID = showID
 self._searchedKeyword = searchedKeyword
 }
 init(_ campaign: LoginCampaign, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, subtitle: LocalizedStringKey? = nil, showDetails: Bool = false, showID: Bool = false, searchedKeyword: Binding<String> = .constant("")) {
 self.information = PreviewLoginCampaign(campaign)
 self.currentID = campaign.id
 
 self.preferHeavierFonts = preferHeavierFonts
 self.locale = locale
 self.showDetails = showDetails
 self.showID = showID
 self._searchedKeyword = searchedKeyword
 }
 init(id: Int, preferHeavierFonts: Bool = false, inLocale locale: DoriAPI.Locale? = DoriAPI.preferredLocale, subtitle: LocalizedStringKey? = nil, showDetails: Bool = false, showID: Bool = false, searchedKeyword: Binding<String> = .constant("")) {
 self.information = nil
 self.currentID = id
 
 self.preferHeavierFonts = preferHeavierFonts
 self.locale = locale
 self.showDetails = showDetails
 self.showID = showID
 self._searchedKeyword = searchedKeyword
 }
 
 let lighterVersionBannerScaleFactor: CGFloat = 0.85
 
 var body: some View {
 CustomGroupBox(showGroupBox: showDetails) {
 HStack {
 if !preferHeavierFonts {
 Spacer(minLength: 0)
 }
 VStack {
 if preferHeavierFonts {
 Spacer(minLength: 0)
 }
 WebImage(url: information?.backgroundImageURL) { image in
 image
 .resizable()
 .antialiased(true)
 .aspectRatio(480 / 288, contentMode: .fit)
 .frame(maxWidth: 420*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), maxHeight: 140*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
 } placeholder: {
 RoundedRectangle(cornerRadius: 10)
 .fill(getPlaceholderColor())
 .aspectRatio(480 / 288, contentMode: .fit)
 .frame(maxWidth: 420*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor), maxHeight: 140*(preferHeavierFonts ? 1 : lighterVersionBannerScaleFactor))
 }
 .interpolation(.high)
 .cornerRadius(10)
 
 if showDetails {
 VStack {
 Text(attributedTitle ?? "Lorem Ipsum")
 .multilineTextAlignment(.center)
 .bold()
 .font((!preferHeavierFonts && !isMACOS) ? .body : .title3)
 .typesettingLanguage(.explicit(((locale ?? .jp).nsLocale().language)))
 .wrapIf(attributedTitle == nil, in: { content in
 content.redacted(reason: .placeholder)
 })
 .onAppear {
 attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (information?.caption.forLocale(locale!) ?? information?.caption.jp) : (information?.caption.forPreferredLocale())))
 }
 .onChange(of: searchedKeyword) {
 attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (information?.caption.forLocale(locale!) ?? information?.caption.jp) : (information?.caption.forPreferredLocale())))
 }
 .onChange(of: information) {
 attributedTitle = highlightOccurrences(of: searchedKeyword, in: (locale != nil ? (information?.caption.forLocale(locale!) ?? information?.caption.jp) : (information?.caption.forPreferredLocale())))
 }
 }
 .frame(height: showDetails ? nil : 0)
 .opacity(showDetails ? 1 : 0)
 }
 if preferHeavierFonts {
 Spacer(minLength: 0)
 }
 }
 if !preferHeavierFonts {
 Spacer(minLength: 0)
 }
 }
 }
 .task {
 if information == nil {
 let fetchedLoginCampaign = await LoginCampaign(id: currentID)
 if let fetchedLoginCampaign {
 information = PreviewLoginCampaign(fetchedLoginCampaign)
 }
 }
 }
 }
 }
 */
