//===---*- Greatdori! -*---------------------------------------------------===//
//
// CardSelector.swift
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

// MARK: CollectionEditorView
struct CollectionEditorView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.dismiss) var dismiss
    @State var collection: CardCollectionManager.Collection
    @State var filter = DoriFrontend.Filter()
    @State var sorter = DoriFrontend.Sorter(keyword: .releaseDate(in: .jp), direction: .descending)
    @State var cards: [CardWithBand]?
    @State var searchedCards: [CardWithBand]?
    @State var infoIsAvailable = true
    @State var searchedText = ""
    @State var layoutType = 1
    @State var showFilterSheet = false
    @State var presentingCardID: Int?
    @State var updateIndex: Int = 0
    @State var showAutoSaveTip = true
    @State var onlyShowSelectedItems = false
    
    @State var selectAllTotalRequestedItemsCount: Int = 0
    @State var selectAllTotalSucceedItemsCount: Int = 0
    @State var selectAllTotalFailureItemsCount: Int = 0
    @State var selectAllTotalExisetedItemsCount: Int = 0
    @State var selectAllPopoverIsPresenting = false
    @State var selectAllTooMuchItemsAlertIsDisplaying = false
    
    @Namespace var cardLists
    
    init(collection: CardCollectionManager.Collection) {
        self._collection = .init(wrappedValue: collection)
    }
    
    let gridLayoutItemWidth: CGFloat = 200*0.9
    let galleryLayoutItemMinimumWidth: CGFloat = 400
    let galleryLayoutItemMaximumWidth: CGFloat = 500
    var body: some View {
        NavigationStack {
            Group {
                if let resultCards = searchedCards ?? cards {
                    Group {
                        if !resultCards.isEmpty {
                            ScrollView {
                                HStack {
                                    Spacer(minLength: 0)
                                    Group {
                                        LazyVStack {
                                            ForEach(resultCards, id: \.self) { card in
                                                CollectionEditorItemView(doriCard: card.card, collection: $collection, layoutType: $layoutType, externalUpdateIndex: $updateIndex)
                                                    .highlightKeyword($searchedText)
                                            }
                                        }
                                        .frame(maxWidth: infoContentMaxWidth)
                                    }
                                    .padding(.horizontal)
                                    Spacer(minLength: 0)
                                }
                            }
                            .geometryGroup()
                        } else {
                            ContentUnavailableView("Search.no-results", systemImage: "magnifyingglass", description: Text("Search.no-results.description"))
                        }
                    }
                    .onSubmit {
                        if let cards {
                            searchedCards = cards.search(for: searchedText)
                        }
                    }
                } else {
                    if infoIsAvailable {
                        ExtendedConstraints {
                            ProgressView()
                        }
                    } else {
                        ExtendedConstraints {
                            ContentUnavailableView("Search.unavailable.\(String(localized: "Cards"))", systemImage: "person.crop.square.on.square.angled", description: Text("Search.unavailable.description"))
                                .onTapGesture {
                                    Task {
                                        await getCards()
                                    }
                                }
                        }
                    }
                }
            }
            .searchable(text: $searchedText, prompt: "Search.prompt.\(String(localized: "Cards"))")
            .navigationTitle("Cards")
            .wrapIf(searchedCards != nil, in: { content in
                if #available(iOS 26.0, *) {
                    content.navigationSubtitle(showAutoSaveTip ? "Settings.widgets.collection.selector.auto-save" : ((searchedText.isEmpty && !filter.isFiltered) ? "Card.count.\(searchedCards!.count)" :  "Search.result.\(searchedCards!.count)"))
                        .onAppear {
                            if isMACOS {
                                showAutoSaveTip = false
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        showAutoSaveTip = false
                                    }
                                }
                            }
                        }
                } else {
                    content
                }
            })
            .toolbar {
                if selectAllTotalRequestedItemsCount != 0 {
                    ToolbarItem {
                        Button(action: {
                            selectAllPopoverIsPresenting.toggle()
                        }, label: {
                            if selectAllTotalSucceedItemsCount + selectAllTotalFailureItemsCount + selectAllTotalExisetedItemsCount < selectAllTotalRequestedItemsCount {
//                                ProgressView(value: Double(selectAllTotalSucceedItemsCount + selectAllTotalFailureItemsCount + selectAllTotalExisetedItemsCount) / Double(selectAllTotalRequestedItemsCount))
                                ProgressView()
                                    .wrapIf(isMACOS, in: {
                                        $0.scaleEffect(0.5)
                                    })
//                                    .progressViewStyle(.circular)
                            } else {
                                Image(systemName: "checkmark.circle")
                            }
                        })
                        .popover(isPresented: $selectAllPopoverIsPresenting) {
                            VStack(alignment: .leading, spacing: 7) {
                                HStack {
                                    MultiSegmentProgressBar(segments: [
                                        .init(color: .green, fraction: Double(selectAllTotalSucceedItemsCount)/Double(selectAllTotalRequestedItemsCount)),
                                        .init(color: .red, fraction: Double(selectAllTotalFailureItemsCount)/Double(selectAllTotalRequestedItemsCount)),
                                        .init(color: .yellow, fraction: Double(selectAllTotalExisetedItemsCount)/Double(selectAllTotalRequestedItemsCount)),
                                        .init(color: .gray, fraction: Double(selectAllTotalRequestedItemsCount - selectAllTotalSucceedItemsCount - selectAllTotalFailureItemsCount - selectAllTotalExisetedItemsCount)/Double(selectAllTotalRequestedItemsCount))
                                    ])
                                    .frame(height: 10)
                                    //                                        Spacer()
                                    Text(verbatim: "/\(selectAllTotalRequestedItemsCount)")
                                }
                                HStack {
                                    Label(title: {
                                        Text("Settings.widgets.collection.selector.select.select-all.progress.succeed")
                                    }, icon: {
                                        Image(systemName: "checkmark.circle")
                                            .foregroundStyle(.green)
                                    })
                                    Spacer()
                                    Text(verbatim: "\(selectAllTotalSucceedItemsCount), \(unsafe String(format: "%.1f", Double(selectAllTotalSucceedItemsCount)/Double(selectAllTotalRequestedItemsCount)*100))%")
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    Label(title: {
                                        Text("Settings.widgets.collection.selector.select.select-all.progress.failure")
                                    }, icon: {
                                        Image(systemName: "xmark.circle")
                                            .foregroundStyle(.red)
                                    })
                                    Spacer()
                                    Text(verbatim: "\(selectAllTotalFailureItemsCount), \(unsafe String(format: "%.1f", Double(selectAllTotalFailureItemsCount)/Double(selectAllTotalRequestedItemsCount)*100))%")
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    Label(title: {
                                        Text("Settings.widgets.collection.selector.select.select-all.progress.existed")
                                    }, icon: {
                                        Image(systemName: "exclamationmark.circle")
                                            .foregroundStyle(.yellow)
                                    })
                                    Spacer()
                                    Text(verbatim: "\(selectAllTotalExisetedItemsCount), \(unsafe String(format: "%.1f", Double(selectAllTotalExisetedItemsCount)/Double(selectAllTotalRequestedItemsCount)*100))%")
                                        .foregroundStyle(.secondary)
                                }
                                HStack {
                                    Label(title: {
                                        Text("Settings.widgets.collection.selector.select.select-all.progress.pending")
                                    }, icon: {
                                        Image(systemName: "ellipsis.circle")
                                            .foregroundStyle(.gray)
                                    })
                                    Spacer()
                                    Text(verbatim: "\(selectAllTotalRequestedItemsCount - selectAllTotalSucceedItemsCount - selectAllTotalFailureItemsCount - selectAllTotalExisetedItemsCount), \(unsafe String(format: "%.1f", Double(selectAllTotalRequestedItemsCount - selectAllTotalSucceedItemsCount - selectAllTotalFailureItemsCount - selectAllTotalExisetedItemsCount)/Double(selectAllTotalRequestedItemsCount)*100))%")
                                        .foregroundStyle(.secondary)
                                }
                                
                                Divider()
                                if selectAllTotalSucceedItemsCount + selectAllTotalFailureItemsCount + selectAllTotalExisetedItemsCount >= selectAllTotalRequestedItemsCount {
                                    Label("Settings.widgets.collection.selector.select.select-all.progress.done", systemImage: "externaldrive.badge.checkmark")
                                } else {
                                    Label(title: {
                                        Text("Settings.widgets.collection.selector.select.select-all.progress.loading")
                                    }, icon: {
                                        ProgressView()
                                            .wrapIf(isMACOS, in: {
                                                $0.scaleEffect(0.5)
                                            })
                                    })
                                }
                            }
                            .padding()
                            .presentationCompactAdaptation(.popover)
                            .frame(width: 300)
                        }
                    }
                }
                ToolbarItem {
                    Menu(content: {
                        if !isMACOS {
                            Section {
                                Button(action: {
                                    showFilterSheet.toggle()
                                }, label: {
                                    Label(showFilterSheet ? "Settings.widgets.collection.selector.filter.hide" : "Settings.widgets.collection.selector.filter.show", systemImage: "line.3.horizontal.decrease")
                                })
                                SorterPickerView(sorter: $sorter, allOptions: CardWithBand.applicableSortingTypes)
                                LayoutPicker(selection: $layoutType, options: [("Filter.view.list", "list.bullet", 1), ("Filter.view.gallery", "text.below.rectangle", 3)])
                            }
                        }
                        Section {
                            Menu(content: {
                                Section("Search.result.\(searchedCards?.count ?? 0)") {
                                    Button(action: {
                                        if (searchedCards?.count ?? 0) > 500 {
                                            selectAllTooMuchItemsAlertIsDisplaying = true
                                        } else {
                                            selectAll()
                                        }
                                    }, label: {
                                        Label("Settings.widgets.collection.selector.select.select-all", systemImage: "checkmark.circle")
                                    })
//                                    .disabled(searchedCards?.count ?? 0 > 500)
                                    Button(action: {
                                        deselectAll()
                                    }, label: {
                                        Label("Settings.widgets.collection.selector.select.deselect-all", systemImage: "circle.slash")
                                    })
                                }
                                .disabled((searchedCards?.count ?? 0) == 0)
                            }, label: {
                                Label("Settings.widgets.collection.selector.select", systemImage: "checklist")
                            })
                            Toggle(isOn: $onlyShowSelectedItems, label: {
                                Label("Settings.widgets.collection.selector.show-selected-only", systemImage: "rectangle.on.rectangle.dashed")
                            })
                        }
                    }, label: {
                        Image(systemName: "ellipsis")
                    })
                }
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer()
                }
                if isMACOS {
                    ToolbarItemGroup {
                        FilterAndSorterPicker(showFilterSheet: $showFilterSheet, sorter: $sorter, filterIsFiltering: filter.isFiltered, sorterKeywords: PreviewCard.applicableSortingTypes, hasEndingDate: false)
                    }
                } else {
                    ToolbarItem {
                        DismissButton(action: {}, label: {
                            Image(systemName: "checkmark")
                        })
                        .wrapIf(true, in: { content in
                            if #available(iOS 26.0, macOS 26.0, *) {
                                content
                                    .buttonStyle(.glassProminent)
                            }
                        })
                    }
                }
            }
        }
        .withSystemBackground()
        .onDisappear {
            showFilterSheet = false
        }
        .wrapIf(isMACOS, in: {
            $0.inspector(isPresented: $showFilterSheet) {
                FilterView(filter: $filter, includingKeys: Set(CardWithBand.applicableFilteringKeys))
            }
        }, else: {
            $0.sheet(isPresented: $showFilterSheet) {
                FilterView(filter: $filter, includingKeys: Set(CardWithBand.applicableFilteringKeys))
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationBackgroundInteraction(.enabled)
            }
        })
        .withSystemBackground()
        .task {
            await getCards()
        }
        .onChange(of: filter) {
            updateSearchResults()
        }
        .onChange(of: sorter) {
            updateSearchResults()
        }
        .onChange(of: searchedText, {
            updateSearchResults()
        })
        .onChange(of: collection, {
            if onlyShowSelectedItems {
                updateSearchResults()
            }
        })
        .onChange(of: onlyShowSelectedItems) {
            updateSearchResults()
        }
        .alert("Settings.widgets.collection.selector.select.select-all.alert.title.\(searchedCards?.count ?? -1)", isPresented: $selectAllTooMuchItemsAlertIsDisplaying, actions: {
            Button(action: {
                selectAll()
            }, label: {
                Text("Settings.widgets.collection.selector.select.select-all.alert.select")
            })
            .keyboardShortcut(.defaultAction)
        }, message: {
            Text("Settings.widgets.collection.selector.select.select-all.alert.message")
        })
    }
    
    func getCards() async {
        infoIsAvailable = true
//        Task {
//            let allCards = await Card.all()
//            
//            searchedCards = cards.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
//        }
        withDoriCache(id: "CardList_for_collection_\(filter.identity)", trait: .realTime) {
            await Card.allWithBand()
        } .onUpdate {
            if let fetchedCards = $0 {
                cards = fetchedCards.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending))
                searchedCards = cards?.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
                if onlyShowSelectedItems {
                    searchedCards = searchedCards?.filter { doriCard in
                        collection.cards.contains { collectionCard in
                            collectionCard.id == doriCard.id
                        }
                    }
                }
            } else {
                infoIsAvailable = false
            }
        }
    }
    
    func selectAll() {
        selectAllTotalSucceedItemsCount = 0
        selectAllTotalFailureItemsCount = 0
        selectAllTotalExisetedItemsCount = 0
        selectAllTotalRequestedItemsCount = (searchedCards?.count ?? 0)*2
        if let searchedCards {
            for item in searchedCards {
                if !CardCollectionManager.shared.userCollections.first(where: { $0.name == collection.name })!.cards.contains(where: { $0.id == item.card.id && !$0.isTrained }) {
                    Task {
                        let reachablility = await DoriFrontend.URLValidator.reachability(of: item.card.coverNormalImageURL)
                        if reachablility {
                            CardCollectionManager.shared.userCollections[CardCollectionManager.shared.userCollections.firstIndex(where: { $0.name == collection.name })!].cards.append(CardCollectionManager.Card(id: item.card.id, isTrained: false, localizedName: item.card.cardName, file: .path(item.card.coverNormalImageURL.absoluteString)))
                            selectAllTotalSucceedItemsCount += 1
                        } else {
                            selectAllTotalFailureItemsCount += 1
                        }
                    }
                } else {
                    selectAllTotalExisetedItemsCount += 1
                }
                if !CardCollectionManager.shared.userCollections.first(where: { $0.name == collection.name })!.cards.contains(where: { $0.id == item.card.id && $0.isTrained }) {
                    if let url = item.card.coverAfterTrainingImageURL {
                        CardCollectionManager.shared.userCollections[CardCollectionManager.shared.userCollections.firstIndex(where: { $0.name == collection.name })!].cards.append(CardCollectionManager.Card(id: item.card.id, isTrained: true, localizedName: item.card.cardName, file: .path(url.absoluteString)))
                        selectAllTotalSucceedItemsCount += 1
                    } else {
                        selectAllTotalFailureItemsCount += 1
                    }
                } else {
                    selectAllTotalExisetedItemsCount += 1
                }
            }
            Task {
                while (selectAllTotalSucceedItemsCount + selectAllTotalFailureItemsCount + selectAllTotalExisetedItemsCount) < selectAllTotalRequestedItemsCount && selectAllTotalRequestedItemsCount != 0 {
                    await Task.yield()
                }
                
                CardCollectionManager.shared.updateStorage()
                collection = CardCollectionManager.shared.userCollections.first(where: { $0.name == collection.name })!
                
                updateIndex += 1
            }
        } else {
            selectAllTotalRequestedItemsCount = 0
        }
    }
    
    func deselectAll() {
        // Safely find the target collection index
        guard let idx = CardCollectionManager.shared.userCollections.firstIndex(where: { $0.name == collection.name }) else {
            return
        }
        
        // Safely unwrap searchedCards and precompute a fast lookup set
        guard let searchedCards, !searchedCards.isEmpty else {
            return
        }
        let searchedIDs = Set(searchedCards.map { $0.id })
        
        // Remove any collection card whose absolute ID appears in the searched IDs
        CardCollectionManager.shared.userCollections[idx].cards.removeAll { collectionCard in
            searchedIDs.contains(collectionCard.id)
        }
        
        // Persist the change if needed
        CardCollectionManager.shared.updateStorage()
        collection = CardCollectionManager.shared.userCollections.first(where: { $0.name == collection.name })!
        
        updateIndex += 1
    }
    
    func updateSearchResults() {
        if let cards {
            searchedCards = cards.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            if onlyShowSelectedItems {
                searchedCards = searchedCards?.filter { doriCard in
                    collection.cards.contains { collectionCard in
                        collectionCard.id == doriCard.id
                    }
                }
            }
        }
    }
}

struct CollectionEditorItemView: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    
    var doriCard: PreviewCard
    @Binding var collection: CardCollectionManager.Collection
    @Binding var layoutType: Int
    @Binding var externalUpdateIndex: Int
    @State var normalCardIsSelected: Bool = false
    @State var trainedCardIsSelected: Bool = false
    
    @State var normalCoverIsPreviewable = true
    
    @State var normalCoverIsSelectable = true
    @State var trainedCoverIsSelectable = true
    @State var normalCoverSelectableCheckIsPending = true
    @State var trainedCoverSelectableCheckIsPending = true
    @State var characterName: LocalizedData<String>? = nil
    var body: some View {
        CustomGroupBox(strokeLineWidth: (normalCardIsSelected || trainedCardIsSelected) ? 3 : 0) {
            CustomStack(axis: isMACOS ? .horizontal : .vertical) {
                CustomStack(axis: layoutType == 1 ? .horizontal : .vertical) {
                    if layoutType != 3 {
                        HStack(spacing: 5) {
                            if normalCoverIsPreviewable {
                                CardPreviewImage(doriCard)
                            }
                            if doriCard.thumbAfterTrainingImageURL != nil {
                                CardPreviewImage(doriCard, showTrainedVersion: true)
                            }
                        }
                        .wrapIf(sizeClass == .regular) { content in
                            content.frame(maxWidth: 200)
                        }
                    } else {
                        CardCoverImage(doriCard, band: DoriCache.preCache.categorizedCharacters.first(where: { $0.value.contains(where: { $0.id == doriCard.characterID }) })?.key)
#if !os(macOS)
                            .allowsHitTesting(false)
#endif
                    }
                    if layoutType != 1 {
                        Spacer()
                    } else {
                        Spacer()
                            .frame(maxWidth: 15)
                    }
                    
                    HStack {
                        if layoutType == 3 {
                            if normalCoverSelectableCheckIsPending || trainedCoverSelectableCheckIsPending {
                                ProgressView()
                            }
                        }
                        VStack(alignment: layoutType == 1 ? .leading : .center) {
                            HighlightableText(doriCard.cardName.forPreferredLocale() ?? "")
                                .bold()
                                .layoutPriority(1)
                            Group {
                                Text(characterName?.forPreferredLocale() ?? String(localized: "Character.unknown")) + Text("Typography.bold-dot-seperater").bold() + Text("#\(String(doriCard.id))").fontDesign(.monospaced)
                            }
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: layoutType == 1 ? .leading : .center)
                    .multilineTextAlignment(layoutType == 1 ? .leading : .center)
                    Spacer(minLength: 0)
                    if layoutType != 3 {
                        VStack {
                            if normalCoverSelectableCheckIsPending || trainedCoverSelectableCheckIsPending {
                                ProgressView()
                                    .wrapIf(isMACOS, in: {
                                        $0.scaleEffect(0.5)
                                    })
                                if !isMACOS {
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .wrapIf(layoutType == 3, in: { content in
                    content
                        .padding(.bottom, 2)
                })
                CustomStack(axis: isMACOS ? .vertical : .horizontal) {
                    Button(action: {
                        if normalCoverIsSelectable && !normalCoverSelectableCheckIsPending {
                            normalCardIsSelected.toggle()
                            
                            if normalCardIsSelected {
                                CardCollectionManager.shared.userCollections[CardCollectionManager.shared.userCollections.firstIndex(where: { $0.name == collection.name })!].cards.append(
                                    CardCollectionManager.Card(id: doriCard.id, isTrained: false, localizedName: doriCard.cardName, file: .path(doriCard.coverNormalImageURL.absoluteString))
                                )
                            } else {
                                CardCollectionManager.shared.userCollections[CardCollectionManager.shared.userCollections.firstIndex(where: { $0.name == collection.name })!].cards.removeAll(where: {
                                    !$0.isTrained && ($0.id == doriCard.id)
                                })
                            }
                            
                            CardCollectionManager.shared.updateStorage()
                            collection = CardCollectionManager.shared.userCollections.first(where: { $0.name == collection.name })!
                        }
                    }, label: {
                        CollectionEditorCapsule(isActive: normalCardIsSelected, isDisabled: !normalCoverIsSelectable, content: {
                            Text("Settings.widgets.collection.selector.normal")
                                .bold()
                                .wrapIf(!isMACOS, in: { content in
                                    HStack {
                                        Spacer()
                                        content
                                        Spacer()
                                    }
                                })
                        })
                    })
                    .buttonStyle(.plain)
                    Button(action: {
                        if trainedCoverIsSelectable && !trainedCoverSelectableCheckIsPending {
                            trainedCardIsSelected.toggle()
                            
                            if trainedCardIsSelected {
                                CardCollectionManager.shared.userCollections[CardCollectionManager.shared.userCollections.firstIndex(where: { $0.name == collection.name })!].cards.append(
                                    CardCollectionManager.Card(id: doriCard.id, isTrained: true, localizedName: doriCard.cardName, file: .path(doriCard.coverAfterTrainingImageURL!.absoluteString))
                                )
                            } else {
                                CardCollectionManager.shared.userCollections[CardCollectionManager.shared.userCollections.firstIndex(where: { $0.name == collection.name })!].cards.removeAll(where: {
                                    $0.isTrained && $0.id == doriCard.id
                                })
                            }
                            
                            CardCollectionManager.shared.updateStorage()
                            collection = CardCollectionManager.shared.userCollections.first(where: { $0.name == collection.name })!
                        }
                    }, label: {
                        CollectionEditorCapsule(isActive: trainedCardIsSelected, isDisabled: !trainedCoverIsSelectable, content: {
                            Text("Settings.widgets.collection.selector.trained")
                                .bold()
                                .wrapIf(!isMACOS, in: { content in
                                    HStack {
                                        Spacer()
                                        content
                                        Spacer()
                                    }
                                })
                        })
                    })
                    .buttonStyle(.plain)
                }
                .onAppear {
                    normalCardIsSelected = CardCollectionManager.shared.userCollections[CardCollectionManager.shared.userCollections.firstIndex(where: { $0.name == collection.name })!].cards.contains(where: {!$0.isTrained && ($0.id == doriCard.id)})
                    trainedCardIsSelected = CardCollectionManager.shared.userCollections[CardCollectionManager.shared.userCollections.firstIndex(where: { $0.name == collection.name })!].cards.contains(where: {$0.isTrained && ($0.id == doriCard.id)})
                }
                .onChange(of: externalUpdateIndex) {
                    normalCardIsSelected = CardCollectionManager.shared.userCollections[CardCollectionManager.shared.userCollections.firstIndex(where: { $0.name == collection.name })!].cards.contains(where: {!$0.isTrained && ($0.id == doriCard.id)})
                    trainedCardIsSelected = CardCollectionManager.shared.userCollections[CardCollectionManager.shared.userCollections.firstIndex(where: { $0.name == collection.name })!].cards.contains(where: {$0.isTrained && ($0.id == doriCard.id)})
                }
            }
            .wrapIf(layoutType != 1) { content in
                HStack {
                    Spacer(minLength: 0)
                    content
                    Spacer(minLength: 0)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: normalCardIsSelected || trainedCardIsSelected)
        .onAppear {
            characterName = DoriCache.preCache.characterDetails[doriCard.characterID]?.characterName
            Task {
                normalCoverIsSelectable = await DoriURLValidator.reachability(of: doriCard.coverNormalImageURL)
                normalCoverSelectableCheckIsPending = false
            }
            Task {
                if doriCard.coverAfterTrainingImageURL != nil {
                    trainedCoverIsSelectable = await DoriURLValidator.reachability(of: doriCard.coverAfterTrainingImageURL!)
                } else {
                    trainedCoverIsSelectable = false
                }
                trainedCoverSelectableCheckIsPending = false
//                print("#\(doriCard.id) - \(doriCard.prefix.jp) - \(trainedCoverIsSelectable)")
            }
            Task {
                normalCoverIsPreviewable = await DoriURLValidator.reachability(
                    of: layoutType != 3 ? doriCard.thumbNormalImageURL : doriCard.coverNormalImageURL
                )
            }
        }
        .wrapIf(doriCard == nil, in: { content in
            content
                .redacted(reason: .placeholder)
        })
    }
    
    
    struct CollectionEditorCapsule<Content: View>: View {
        @Environment(\.horizontalSizeClass) var sizeClass
        var isActive: Bool
        var isDisabled: Bool = false
        let content: Content
//        let cornerRadius: CGFloat = capsuleDefaultCornerRadius
        @State var textWidth: CGFloat = 0
        @State var showUnavailablePrompt = false
        
        init(isActive: Bool, isDisabled: Bool = false, @ViewBuilder content: () -> Content) {
            self.isActive = isActive
            self.isDisabled = isDisabled
            self.content = content()
        }
        var body: some View {
            ZStack {
//                RoundedRectangle(cornerRadius: cornerRadius)
                Group {
                    if isDisabled {
                        Capsule()
                            .strokeBorder(Color.gray, lineWidth: 2)
                    } else {
                        Capsule()
                    }
                }
                .foregroundStyle(!isDisabled ? (isActive ? Color.accent : getTertiaryLabelColor()) : Color.clear)
                .frame(width: textWidth, height: filterItemHeight)
                Group {
                    if showUnavailablePrompt {
                        HStack {
                            Spacer()
                            Text("N/A")
                                .bold()
                            Spacer()
                        }
                    } else {
                        content
                            .strikethrough(isDisabled)
                    }
                }
                .foregroundStyle(isActive && !isDisabled ? .white : Color.gray)
                .frame(height: filterItemHeight)
                .padding(.horizontal, isMACOS ? 10 : nil)
                .onFrameChange(perform: { geometry in
                    textWidth = geometry.size.width
                })
                
            }
            .animation(.easeInOut(duration: 0.05), value: isActive)
            .wrapIf(isDisabled, in: { content in
                content
                    .onTapGesture {
                        withAnimation {
                            showUnavailablePrompt = true
                        }
                    }
            })
            .onChange(of: showUnavailablePrompt) {
                if showUnavailablePrompt {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showUnavailablePrompt = false
                        }
                    }
                }
            }
        }
    }
    
}


struct MultiSegmentProgressBar: View {
    struct Segment: Identifiable {
        let id = UUID()
        let color: Color
        let fraction: Double // 0.0 ~ 1.0
    }
    
    var segments: [Segment]
    
    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(segments) { segment in
                    Rectangle()
                        .fill(segment.color)
                        .frame(width: geo.size.width * segment.fraction)
                }
            }
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
        .frame(height: 10)
        .animation(.easeInOut, value: segments.map(\.fraction))
    }
}
