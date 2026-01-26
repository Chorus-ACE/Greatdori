//===---*- Greatdori! -*---------------------------------------------------===//
//
// ItemSelector.swift
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
import SymbolAvailability
@_spi(Advanced) import SwiftUIIntrospect

struct ItemSelectorView<Element: Sendable & Hashable & DoriCacheable & DoriFilterable & DoriSortable & DoriSearchable & DoriTypeDescribable, Layout, LayoutPicker: View, Container: View, Content: View>: View {
//    var titleKey: LocalizedStringResource
    @Binding var selection: [Element]
    var updateList: @Sendable () async -> [Element]?
    var makeLayoutPicker: (Binding<Layout>) -> LayoutPicker
    var makeContainer: (Layout, [Element], AnyView, @escaping (Element) -> AnyView) -> Container
    var makeSomeContent: (Layout, Element) -> Content
    @State var currentLayout: Layout
    
    var unavailableSystemImage: String = "bolt.horizontal.fill"
    var getResultCountDescription: ((Int) -> LocalizedStringResource)?
    
    init(
//        _ titleKey: LocalizedStringResource,
        selection: Binding<[Element]>,
        initialLayout: Layout,
        layoutOptions: [(LocalizedStringKey, String, Layout)],
        @ViewBuilder container: @escaping (_ layout: Layout, _ elements: [Element], _ content: AnyView, _ eachContent: @escaping (Element) -> AnyView) -> Container,
        @ViewBuilder eachContent: @escaping (_ layout: Layout, _ element: Element) -> Content
    ) where Element: ListGettable, Layout: Hashable, LayoutPicker == Greatdori.LayoutPicker<Layout> {
        self.init(
//            titleKey,
            selection: selection,
            initialLayout: initialLayout,
            layoutPicker: { layout in
                Greatdori.LayoutPicker(selection: layout, options: layoutOptions)
            },
            container: container,
            eachContent: eachContent
        )
    }
    init(
//        _ titleKey: LocalizedStringResource,
        selection: Binding<[Element]>,
        initialLayout: Layout,
        updateList: @Sendable @escaping () async -> [Element]?,
        layoutOptions: [(LocalizedStringKey, String, Layout)],
        @ViewBuilder container: @escaping (_ layout: Layout, _ elements: [Element], _ content: AnyView, _ eachContent: @escaping (Element) -> AnyView) -> Container,
        @ViewBuilder eachContent: @escaping (_ layout: Layout, _ element: Element) -> Content
    ) where Layout: Hashable, LayoutPicker == Greatdori.LayoutPicker<Layout> {
        self.init(
//            titleKey,
            selection: selection,
            initialLayout: initialLayout,
            updateList: updateList,
            layoutPicker: { layout in
                Greatdori.LayoutPicker(selection: layout, options: layoutOptions)
            },
            container: container,
            eachContent: eachContent
        )
    }
    init(
//        _ titleKey: LocalizedStringResource,
        selection: Binding<[Element]>,
        initialLayout: Layout,
        @ViewBuilder layoutPicker: @escaping (Binding<Layout>) -> LayoutPicker,
        @ViewBuilder container: @escaping (_ layout: Layout, _ elements: [Element], _ content: AnyView, _ eachContent: @escaping (Element) -> AnyView) -> Container,
        @ViewBuilder eachContent: @escaping (_ layout: Layout, _ element: Element) -> Content
    ) where Element: ListGettable {
        self.init(
//            titleKey,
            selection: selection,
            initialLayout: initialLayout,
            updateList: Element.all,
            layoutPicker: layoutPicker,
            container: container,
            eachContent: eachContent
        )
    }
    init(
//        _ titleKey: LocalizedStringResource,
        selection: Binding<[Element]>,
        initialLayout: Layout,
        updateList: @Sendable @escaping () async -> [Element]?,
        @ViewBuilder layoutPicker: @escaping (Binding<Layout>) -> LayoutPicker,
        @ViewBuilder container: @escaping (_ layout: Layout, _ elements: [Element], _ content: AnyView, _ eachContent: @escaping (Element) -> AnyView) -> Container,
        @ViewBuilder eachContent: @escaping (_ layout: Layout, _ element: Element) -> Content
    ) {
//        self.titleKey = titleKey
        self._selection = selection
        self.updateList = updateList
        self.makeLayoutPicker = layoutPicker
        self.makeContainer = container
        self.makeSomeContent = eachContent
        self._currentLayout = .init(initialValue: initialLayout)
        self._filter = .init(initialValue: .recoverable(id: Element.singularName.key))
    }
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.supportsMultipleWindows) private var supportsMultipleWindows
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\._itemSelectorMultiSelectionDisabled) private var isMultipleSelectionDisabled
    @State private var filter: DoriFrontend.Filter
    @State private var sorter = DoriFrontend.Sorter(keyword: .releaseDate(in: .jp), direction: .descending)
    @State private var elements: [Element]?
    @State private var searchedElements: [Element]?
    @State private var infoIsAvailable = true
    @State private var searchedText = ""
    @State private var showFilterSheet = false
    
    var body: some View {
        Group {
            Group {
                if let resultElements = searchedElements ?? elements {
                    Group {
                        if !resultElements.isEmpty {
                            ScrollView {
                                HStack {
                                    Spacer(minLength: 0)
                                    makeContainer(currentLayout, resultElements,
                                      AnyView(
                                        ForEach(resultElements, id: \.self) { element in
                                            Button(action: {
                                                if !isMultipleSelectionDisabled {
                                                    if selection.contains(element) {
                                                        selection.removeAll { $0 == element }
                                                    } else {
                                                        selection.append(element)
                                                    }
                                                } else {
                                                    selection = [element]
                                                    dismiss()
                                                }
                                            }, label: {
                                                makeSomeContent(currentLayout, element)
                                                    .highlightKeyword($searchedText)
                                                    .groupBoxStrokeLineWidth(selection.contains(element) ? 3 : 0)
                                            })
                                            .buttonStyle(.plain)
                                        }
                                      )
                                    ) { element in
                                        AnyView(
                                            Button(action: {
                                                if !isMultipleSelectionDisabled {
                                                    if selection.contains(element) {
                                                        selection.removeAll { $0 == element }
                                                    } else {
                                                        selection.append(element)
                                                    }
                                                } else {
                                                    selection = [element]
                                                    dismiss()
                                                }
                                            }, label: {
                                                makeSomeContent(currentLayout, element)
                                                    .highlightKeyword($searchedText)
                                                    .groupBoxStrokeLineWidth(selection.contains(element) ? 3 : 0)
                                            })
                                            .buttonStyle(.plain)
                                        )
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
                        if let elements {
                            searchedElements = elements.search(for: searchedText)
                        }
                    }
                } else {
                    if infoIsAvailable {
                        ExtendedConstraints {
                            ProgressView()
                        }
                    } else {
                        ExtendedConstraints {
                            ContentUnavailableView("Search.unavailable.\(Element.singularName)", systemImage: Element.symbol, description: Text("Search.unavailable.description"))
                                .onTapGesture {
                                    Task {
                                        await getList()
                                    }
                                }
                        }
                    }
                }
            }
            .searchable(text: $searchedText, prompt: "Search.prompt.\(Element.pluralName)")
            .navigationTitle(Element.pluralName)
            #if !os(visionOS)
            .wrapIf(searchedElements != nil, in: { content in
                if #available(iOS 26.0, *) {
                    content.navigationSubtitle((searchedText.isEmpty && !filter.isFiltered) ? (getResultCountDescription?(searchedElements!.count) ?? "Search.item.\(searchedElements!.count)") :  "Search.result.\(searchedElements!.count)")
                } else {
                    content
                }
            })
            #endif
            .toolbar {
                ToolbarItem {
                    makeLayoutPicker($currentLayout)
                }
                #if !os(visionOS)
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer()
                }
                #endif
                ToolbarItemGroup {
                    FilterAndSorterPicker(showFilterSheet: $showFilterSheet, sorter: $sorter, filterIsFiltering: filter.isFiltered, sorterKeywords: Element.applicableSortingTypes, hasEndingDate: false)
                }
                #if !os(visionOS)
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer()
                }
                #endif
                if !supportsMultipleWindows {
                    ToolbarItem {
                        Button("Done", systemImage: "checkmark") {
                            dismiss()
                        }
                        .wrapIf(true) { content in
                            #if !os(visionOS)
                            if #available(iOS 26.0, macOS 26.0, *) {
                                content
                                    .buttonStyle(.glassProminent)
                            } else {
                                content
                                    .buttonStyle(.borderedProminent)
                            }
                            #else
                            content
                                .buttonStyle(.borderedProminent)
                            #endif
                        }
                    }
                }
            }
            .onDisappear {
                showFilterSheet = false
            }
        }
        .withSystemBackground()
        #if !os(visionOS)
        .inspector(isPresented: $showFilterSheet) {
            FilterView(filter: $filter, includingKeys: Set(Element.applicableFilteringKeys))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
        }
        #else
        .ornament(visibility: showFilterSheet ? .visible : .hidden, attachmentAnchor: .scene(.trailing)) {
            HStack {
                Spacer(minLength: 300)
                FilterView(filter: $filter, includingKeys: Set(Element.applicableFilteringKeys))
                    .padding(.top)
                    .glassBackgroundEffect()
                    .frame(width: 300, height: 600)
            }
            .rotation3DEffect(.degrees(-30), axis: .y)
        }
        #endif
        .withSystemBackground() // This modifier MUST be placed BOTH before
                                // and after `inspector` to make it work as expected
        .task {
            await getList()
        }
        .onChange(of: filter) {
            if let elements {
                searchedElements = elements.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: sorter) {
            if let elements {
                searchedElements = elements.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        }
        .onChange(of: searchedText, {
            if let elements {
                searchedElements = elements.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            }
        })
    }
    
    func getList() async {
        infoIsAvailable = true
        withDoriCache(id: "\(Element.singularName.key)List_\(filter.identity)", trait: .realTime) {
            await updateList()
        }.onUpdate {
            if let cards = $0 {
                self.elements = cards.sorted(withDoriSorter: DoriFrontend.Sorter(keyword: .id, direction: .ascending))
                searchedElements = cards.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            } else {
                infoIsAvailable = false
            }
        }
    }
}

extension ItemSelectorView {
    func resultCountDescription(content: ((Int) -> LocalizedStringResource)?) -> Self {
        var mutable = self
        mutable.getResultCountDescription = content
        return mutable
    }
}
extension View {
    func selectorDisablesMultipleSelection(_ disabled: Bool = true) -> some View {
        environment(\._itemSelectorMultiSelectionDisabled, disabled)
    }
}
extension EnvironmentValues {
    @Entry fileprivate var _itemSelectorMultiSelectionDisabled = false
}

struct ItemSelectorButton<Element: Sendable & Hashable & Identifiable & DoriCacheable & TitleDescribable & DoriTypeDescribable & ListGettable>: View {
    @Binding var selection: Element?
    var closeWindowOnSelectionChange = false
    var updateList: () async -> [Element]? = { await Element.all() }
    @Environment(\.isEnabled) private var isEnabled
    @State private var selectorWindowIsPresented = false
    var body: some View {
        Button(action: {
            selectorWindowIsPresented = true
        }, label: {
            if let selection {
                HStack {
                    Text(selection.title.forPreferredLocale() ?? "#\(selection.id)")
                        .multilineTextAlignment(.trailing)
                    Image(systemName: .chevronUpChevronDown)
                        .bold(isMACOS)
                        .font(.footnote)
                }
            } else {
                Text("Selector.prompt.\(Element.singularName)")
            }
        })
        .wrapIf(!isMACOS) {
            $0.foregroundStyle(isEnabled ? .accent : .gray)
        }
        .padding(.vertical, isMACOS ? 0 : 3)
        .onChange(of: selection, {
            if closeWindowOnSelectionChange {
                selectorWindowIsPresented = false
            }
        })
        .onDisappear {
            selectorWindowIsPresented = false
        }
        .window(isPresented: $selectorWindowIsPresented) {
            NavigationStack {
                if let eventBinding = bindingCast($selection, to: PreviewEvent?.self) {
                    EventSelector(selection: eventBinding)
                } else if let cardBinding = bindingCast($selection, to: PreviewCard?.self) {
                    CardSelector(selection: cardBinding, updateList: castUpdateList(updateList, to: PreviewCard.self)!)
                } else if let costumeBinding = bindingCast($selection, to: PreviewCostume?.self) {
                    CostumeSelector(selection: costumeBinding)
                } else if let characterBinding = bindingCast($selection, to: PreviewCharacter?.self) {
                    CharacterSelector(selection: characterBinding)
                } else if let songBinding = bindingCast($selection, to: PreviewSong?.self) {
                    SongSelector(selection: songBinding)
                }
            }
            #if os(macOS)
            .introspect(.window, on: .macOS(.v14...)) { window in
                window.standardWindowButton(.zoomButton)?.isEnabled = false
                window.standardWindowButton(.miniaturizeButton)?.isEnabled = false
                window.collectionBehavior = [.fullScreenAuxiliary, .fullScreenNone]
                window.level = .floating
            }
            #endif
        }
    }
    func castUpdateList<T>(
        _ updateList: @escaping () async -> [Element]?,
        to: T.Type
    ) -> (() async -> [T]?)? {
        return {
            let array = await updateList()
            return array as? [T]
        }
    }
}
