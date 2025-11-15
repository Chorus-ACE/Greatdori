//===---*- Greatdori! -*---------------------------------------------------===//
//
// InfoBase.swift
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

struct DetailViewBase<Information: Sendable & Identifiable & DoriCacheable & TitleDescribable,
                      PreviewInformation: Identifiable & DoriTypeDescribable,
                      Content: View,
                      SwitcherDestination: View>: View where Information.ID == Int, PreviewInformation.ID == Int {
    var previewList: [PreviewInformation]?
    var initialID: Int
    var updateInformation: @Sendable (Int) async -> Information?
    var makeContent: (Information) -> Content
    var makeSwitcherDestination: () -> SwitcherDestination
    var unavailablePrompt: LocalizedStringResource
    
    init(
        previewList: [PreviewInformation]?,
        initialID: Int,
        @ViewBuilder content: @escaping (Information) -> Content,
        @ViewBuilder switcherDestination: @escaping () -> SwitcherDestination
    ) where Information: GettableByID, PreviewInformation: ExtendedTypeConvertible, PreviewInformation.ExtendedType == Information {
        self.init(previewList: previewList, initialID: initialID, updateInformation: {
            await PreviewInformation.ExtendedType.init(id: $0)
        }, content: content, switcherDestination: switcherDestination)
    }
    init(
        forType infoType: Information.Type,
        previewList: [PreviewInformation]?,
        initialID: Int,
        @ViewBuilder content: @escaping (Information) -> Content,
        @ViewBuilder switcherDestination: @escaping () -> SwitcherDestination
    ) where Information: GettableByID {
        self.init(previewList: previewList, initialID: initialID, updateInformation: {
            await infoType.init(id: $0)
        }, content: content, switcherDestination: switcherDestination)
    }
    init(
        previewList: [PreviewInformation]?,
        initialID: Int,
        updateInformation: @Sendable @escaping (_ id: Int) async -> Information?,
        @ViewBuilder content: @escaping (Information) -> Content,
        @ViewBuilder switcherDestination: @escaping () -> SwitcherDestination
    ) {
        self.previewList = previewList
        self.initialID = initialID
        self.updateInformation = updateInformation
        self.makeContent = content
        self.makeSwitcherDestination = switcherDestination
        self.unavailablePrompt = "Content.unavailable.\(PreviewInformation.singularName)"
    }
    
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var currentID: Int = 0
    @State private var informationLoadPromise: DoriCache.Promise<Information?>?
    @State private var information: Information?
    @State private var infoIsAvailable = true
    @State private var showSubtitle: Bool = false
    @State private var allPreviewIDs: [Int] = []
    
    var body: some View {
        Group {
            if let information {
                ScrollView {
                    HStack {
                        Spacer(minLength: 0)
                        VStack(spacing: 40) {
                            makeContent(information)
                        }
                        .padding()
                        Spacer(minLength: 0)
                    }
                }
                .scrollDisablesPopover()
            } else {
                if infoIsAvailable {
                    ExtendedConstraints {
                        ProgressView()
                    }
                } else {
                    Button(action: {
                        Task {
                            await getInformation(id: currentID)
                        }
                    }, label: {
                        ExtendedConstraints {
                            ContentUnavailableView(unavailablePrompt, systemImage: "photo.badge.exclamationmark", description: Text("Search.unavailable.description"))
                        }
                    })
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle(Text(information?.title.forPreferredLocale() ?? (isMACOS ? String(localized: String.LocalizationValue(PreviewInformation.singularName.key)) : "")))
        #if os(iOS)
        .wrapIf(showSubtitle) { content in
            if #available(iOS 26, macOS 14.0, *) {
                content
                    .navigationSubtitle(information?.title.forPreferredLocale() != nil ? "#\(String(currentID))" : "")
            } else {
                content
            }
        }
        #endif
        .onChange(of: currentID) {
            Task {
                await getInformation(id: currentID)
            }
        }
        .task {
            currentID = initialID
            await getInformation(id: currentID)
            if let previewList {
                allPreviewIDs = previewList.map { $0.id }
            } else if let ListGettableType = PreviewInformation.self as? (any (Sendable & Identifiable & ListGettable).Type) {
                // We can always assume that the ID of elements are `Int`
                // because it has been constrainted in the generic decls
                allPreviewIDs = await ListGettableType.all()?.map { $0.id as! Int } ?? []
            }
        }
        .toolbar {
            ToolbarItemGroup(content: {
                DetailsIDSwitcher(currentID: $currentID, allIDs: allPreviewIDs, destination: makeSwitcherDestination)
                    .onChange(of: currentID) {
                        information = nil
                    }
                    .onAppear {
                        showSubtitle = (sizeClass == .compact)
                    }
            })
        }
        .withSystemBackground()
    }
    
    private func getInformation(id: Int) async {
        infoIsAvailable = true
        informationLoadPromise?.cancel()
        informationLoadPromise = withDoriCache(id: "\(PreviewInformation.singularName.key)Detail_\(id)", trait: .realTime) {
            await updateInformation(id)
        } .onUpdate {
            if let information = $0 {
                self.information = information
            } else {
                infoIsAvailable = false
            }
        }
    }
}

struct SummaryViewBase<Image: View, Detail: View>: View {
    var layout: SummaryLayout
    var title: LocalizedData<String>
    var makeImageView: () -> Image
    var makeDetailView: () -> Detail
    
    init<Source: TitleDescribable>(
        _ layout: SummaryLayout,
        source: Source,
        @ViewBuilder image: @escaping () -> Image,
        @ViewBuilder detail: @escaping () -> Detail
    ) {
        self.layout = layout
        self.title = source.title
        self.makeImageView = image
        self.makeDetailView = detail
    }
    init(
        _ layout: SummaryLayout,
        title: LocalizedData<String>,
        @ViewBuilder image: @escaping () -> Image,
        @ViewBuilder detail: @escaping () -> Detail
    ) {
        self.layout = layout
        self.title = title
        self.makeImageView = image
        self.makeDetailView = detail
    }
    
    var body: some View {
        CustomGroupBox(showGroupBox: layout != .vertical(hidesDetail: true)) {
            CustomStack(axis: layout.axis) {
                makeImageView()
                if layout != .vertical(hidesDetail: true) {
                    if layout != .horizontal {
                        Spacer()
                    } else {
                        Spacer()
                            .frame(maxWidth: 15)
                    }
                    
                    VStack(alignment: layout == .horizontal ? .leading : .center) {
                        HighlightableText(title.forPreferredLocale() ?? "")
                            .bold()
                            .font(!isMACOS ? .body : .title3)
                            .layoutPriority(1)
                        makeDetailView()
                            .environment(\.isCompactHidden, layout != .horizontal)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: layout == .horizontal ? .leading : .center)
                    .multilineTextAlignment(layout == .horizontal ? .leading : .center)
                }
                Spacer(minLength: 0)
            }
            .wrapIf(layout != .horizontal) { content in
                HStack {
                    Spacer(minLength: 0)
                    content
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

enum SummaryLayout: Hashable {
    case horizontal
    case vertical(hidesDetail: Bool = false)
    
    var axis: Axis {
        switch self {
        case .horizontal: .horizontal
        case .vertical: .vertical
        }
    }
}

extension View {
    func preferHiddenInCompactLayout() -> some View {
        modifier(_CompactHiddenModifier())
    }
    
    func highlightKeyword(_ keyword: Binding<String>?) -> some View {
        environment(\.searchedKeyword, keyword)
    }
}

private struct _CompactHiddenModifier: ViewModifier {
    @Environment(\.isCompactHidden) private var isCompactHidden: Bool
    func body(content: Content) -> some View {
        if !isCompactHidden {
            content
        }
    }
}
extension EnvironmentValues {
    @Entry fileprivate var isCompactHidden: Bool = false
    @Entry var searchedKeyword: Binding<String>? = nil
}

@MainActor let verticalAndHorizontalLayouts: [(LocalizedStringKey, String, SummaryLayout)] = [("Filter.view.list", "list.bullet", SummaryLayout.horizontal), ("Filter.view.grid", "square.grid.2x2", SummaryLayout.vertical(hidesDetail: false))]
@MainActor let bannerLayouts: [(LocalizedStringKey, String, Bool)] = [("Filter.view.banner-and-details", "text.below.rectangle", true), ("Filter.view.banner-only", "rectangle.grid.1x2", false)]

struct SearchViewBase<Element: Sendable & Hashable & DoriCacheable & DoriFilterable & DoriSortable & DoriSearchable & DoriTypeDescribable, Layout, LayoutPicker: View, Container: View, Content: View, Destination: View>: View {
    var updateList: @Sendable () async -> [Element]?
    var makeLayoutPicker: (Binding<Layout>) -> LayoutPicker
    var makeContainer: (Layout, [Element], AnyView, @escaping (Element) -> AnyView) -> Container
    var makeSomeContent: (Layout, Element) -> Content
    var makeDestination: (Element, [Element]) -> Destination
    @State var currentLayout: Layout
    
    var unavailablePrompt: LocalizedStringResource
    var searchPlaceholder: LocalizedStringResource
    var getResultCountDescription: ((Int) -> LocalizedStringResource)?

    init(
        forType type: Element.Type,
        initialLayout: Layout,
        layoutOptions: [(LocalizedStringKey, String, Layout)],
        @ViewBuilder container: @escaping (_ layout: Layout, _ elements: [Element], _ content: AnyView, _ eachContent: @escaping (Element) -> AnyView) -> Container,
        @ViewBuilder eachContent: @escaping (_ layout: Layout, _ element: Element) -> Content,
        @ViewBuilder destination: @escaping (_ element: Element, _ list: [Element]) -> Destination
    ) where Element: ListGettable, Layout: Hashable, LayoutPicker == Greatdori.LayoutPicker<Layout> {
        self.init(
            forType: type,
            initialLayout: initialLayout,
            layoutPicker: { layout in
                Greatdori.LayoutPicker(selection: layout, options: layoutOptions)
            },
            container: container,
            eachContent: eachContent,
            destination: destination
        )
    }
    init(
        initialLayout: Layout,
        updateList: @Sendable @escaping () async -> [Element]?,
        layoutOptions: [(LocalizedStringKey, String, Layout)],
        @ViewBuilder container: @escaping (_ layout: Layout, _ elements: [Element], _ content: AnyView, _ eachContent: @escaping (Element) -> AnyView) -> Container,
        @ViewBuilder eachContent: @escaping (_ layout: Layout, _ element: Element) -> Content,
        @ViewBuilder destination: @escaping (_ element: Element, _ list: [Element]) -> Destination
    ) where Layout: Hashable, LayoutPicker == Greatdori.LayoutPicker<Layout> {
        self.init(
            initialLayout: initialLayout,
            updateList: updateList,
            layoutPicker: { layout in
                Greatdori.LayoutPicker(selection: layout, options: layoutOptions)
            },
            container: container,
            eachContent: eachContent,
            destination: destination
        )
    }
    init(
        forType _: Element.Type,
        initialLayout: Layout,
        @ViewBuilder layoutPicker: @escaping (Binding<Layout>) -> LayoutPicker,
        @ViewBuilder container: @escaping (_ layout: Layout, _ elements: [Element], _ content: AnyView, _ eachContent: @escaping (Element) -> AnyView) -> Container,
        @ViewBuilder eachContent: @escaping (_ layout: Layout, _ element: Element) -> Content,
        @ViewBuilder destination: @escaping (_ element: Element, _ list: [Element]) -> Destination
    ) where Element: ListGettable {
        self.init(
            initialLayout: initialLayout,
            updateList: Element.all,
            layoutPicker: layoutPicker,
            container: container,
            eachContent: eachContent,
            destination: destination
        )
    }
    init(
        initialLayout: Layout,
        updateList: @Sendable @escaping () async -> [Element]?,
        @ViewBuilder layoutPicker: @escaping (Binding<Layout>) -> LayoutPicker,
        @ViewBuilder container: @escaping (_ layout: Layout, _ elements: [Element], _ content: AnyView, _ eachContent: @escaping (Element) -> AnyView) -> Container,
        @ViewBuilder eachContent: @escaping (_ layout: Layout, _ element: Element) -> Content,
        @ViewBuilder destination: @escaping (_ element: Element, _ list: [Element]) -> Destination
    ) {
        self.updateList = updateList
        self.makeLayoutPicker = layoutPicker
        self.makeContainer = container
        self.makeSomeContent = eachContent
        self.makeDestination = destination
        self._currentLayout = .init(initialValue: initialLayout)
        self.unavailablePrompt = "Search.unavailable.\(Element.singularName)"
        self.searchPlaceholder = "Search.prompt.\(Element.pluralName)"
        self._filter = .init(initialValue: .recoverable(id: Element.pluralName.key))
    }
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.colorScheme) private var colorScheme
    @Namespace private var navigationAnimationNamespace
    @State private var filter: _DoriFrontend.Filter
    @State private var sorter = DoriSorter(keyword: Element.applicableSortingTypes.contains(.releaseDate(in: .jp)) ? .releaseDate(in: .jp) : .id, direction: .descending)
    @State private var elements: [Element]?
    @State private var searchedElements: [Element]?
    @State private var infoIsAvailable = true
    @State private var searchedText = ""
    @State private var showFilterSheet = false
    @State private var presentingElement: Element?
    @State private var isCustomGroupBoxActive = false
    
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
                                                    showFilterSheet = false
                                                    presentingElement = element
                                                }, label: {
                                                    // # Why?
                                                    // After updating CustomGroupBox to 2, some issue occured here.
                                                    //
                                                    // # What happened?
                                                    // the `matchedTransitionSource(id:in:)` constraints a view's
                                                    // viewport to its own frame, that is, our shadows are clipped
                                                    // into the frame of the box itself.
                                                    //
                                                    // # How do we solve it?
                                                    // First we add a preference key for custom group boxes,
                                                    // if there's any active `CustomGroupBox` in the view
                                                    // from `makeSomeContent(_:_:)`, we can receive the info
                                                    // by the `onPreferenceChange` call below.
                                                    // We suppress the group box in content by setting
                                                    // the env value `_suppressCustomGroupBox` to `true`,
                                                    // then add a custom group box
                                                    // after the `matchedTransitionSource(id:in:)` call
                                                    // if needed to solve this problem.
                                                    // That's why codes here seem wired.
                                                    makeSomeContent(currentLayout, element)
                                                        .highlightKeyword($searchedText)
                                                        .environment(\._suppressCustomGroupBox, true)
                                                        .onPreferenceChange(CustomGroupBoxActivePreference.self) { isActive in
                                                            isCustomGroupBoxActive = isActive
                                                        }
                                                        .wrapIf(true) { content in
                                                            if #available(iOS 18.0, macOS 15.0, *) {
                                                                content
                                                                    .matchedTransitionSource(id: element.hashValue, in: navigationAnimationNamespace)
                                                            } else {
                                                                content
                                                            }
                                                        }
                                                        .wrapIf(isCustomGroupBoxActive) { content in
                                                            CustomGroupBox {
                                                                content
                                                            }
                                                        }
                                                })
                                                .buttonStyle(.plain)
                                            }
                                        )
                                    ) { element in
                                        AnyView(
                                            Button(action: {
                                                showFilterSheet = false
                                                presentingElement = element
                                            }, label: {
                                                makeSomeContent(currentLayout, element)
                                                    .highlightKeyword($searchedText)
                                                    .environment(\._suppressCustomGroupBox, true)
                                                    .onPreferenceChange(CustomGroupBoxActivePreference.self) { isActive in
                                                        isCustomGroupBoxActive = isActive
                                                    }
                                                    .wrapIf(true) { content in
                                                        if #available(iOS 18.0, macOS 15.0, *) {
                                                            content
                                                                .matchedTransitionSource(id: element.hashValue, in: navigationAnimationNamespace)
                                                        } else {
                                                            content
                                                        }
                                                    }
                                                    .wrapIf(isCustomGroupBoxActive) { content in
                                                        CustomGroupBox {
                                                            content
                                                        }
                                                    }
                                            })
                                            .buttonStyle(.plain)
                                        )
                                    }
                                    .padding(.horizontal)
                                    Spacer(minLength: 0)
                                }
                            }
                            .geometryGroup()
                            .navigationDestination(item: $presentingElement) { element in
                                makeDestination(element, elements ?? [])
#if !os(macOS)
                                    .wrapIf(true, in: { content in
                                        if #available(iOS 18.0, *) {
                                            content
                                                .navigationTransition(.zoom(sourceID: element.hashValue, in: navigationAnimationNamespace))
                                        } else {
                                            content
                                        }
                                    })
                                #endif
                            }
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
                            ContentUnavailableView(unavailablePrompt, systemImage: Element.symbol, description: Text("Search.unavailable.description"))
                                .onTapGesture {
                                    Task {
                                        await getList()
                                    }
                                }
                        }
                    }
                }
            }
            .searchable(text: $searchedText, prompt: searchPlaceholder)
            .navigationTitle(Element.pluralName)
            .wrapIf(searchedElements != nil, in: { content in
                if #available(iOS 26.0, *) {
                    content.navigationSubtitle((searchedText.isEmpty && !filter.isFiltered) ? (getResultCountDescription?(searchedElements!.count) ?? "Search.item.\(searchedElements!.count)") :  "Search.result.\(searchedElements!.count)")
                } else {
                    content
                }
            })
            .toolbar {
                ToolbarItem {
                    makeLayoutPicker($currentLayout)
                }
                if #available(iOS 26.0, macOS 26.0, *) {
                    ToolbarSpacer()
                }
                ToolbarItemGroup {
                    FilterAndSorterPicker(showFilterSheet: $showFilterSheet, sorter: $sorter, filterIsFiltering: filter.isFiltered, sorterKeywords: Element.applicableSortingTypes, hasEndingDate: false)
                }
            }
            .onDisappear {
                showFilterSheet = false
            }
        }
        .withSystemBackground()
        .inspector(isPresented: $showFilterSheet) {
            FilterView(filter: $filter, includingKeys: Set(Element.applicableFilteringKeys))
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationBackgroundInteraction(.enabled)
        }
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
        withDoriCache(id: "\(Element.pluralName.key)List_\(filter.identity)", trait: .realTime) {
            await updateList()
        }.onUpdate {
            if let cards = $0 {
                self.elements = cards.sorted(withDoriSorter: _DoriFrontend.Sorter(keyword: .id, direction: .ascending))
                searchedElements = cards.filter(withDoriFilter: filter).search(for: searchedText).sorted(withDoriSorter: sorter)
            } else {
                infoIsAvailable = false
            }
        }
    }
}

extension SearchViewBase {
    func resultCountDescription(content: ((Int) -> LocalizedStringResource)?) -> Self {
        var mutable = self
        mutable.getResultCountDescription = content
        return mutable
    }
}

struct DetailSectionBase<Element: Hashable & DoriTypeDescribable, Content: View>: View {
    var localizedElements: LocalizedData<[Element]>
    var showLocalePicker: Bool
    var makeEachContent: (Element) -> Content
    
    init(
        elements: [Element],
        @ViewBuilder eachContent: @escaping (Element) -> Content
    ) {
        self.localizedElements = .init(forEveryLocale: elements)
        self.showLocalePicker = false
        self.makeEachContent = eachContent
    }
    init(
        _ titleKey: LocalizedStringResource,
        elements: LocalizedData<[Element]>,
        @ViewBuilder eachContent: @escaping (Element) -> Content
    ) {
        self.localizedElements = elements
        self.showLocalePicker = false
        self.makeEachContent = eachContent
    }
    
    @State private var locale = DoriLocale.primaryLocale
    @State private var showAll = false
    
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section {
                Group {
                    if let elements = localizedElements.forLocale(locale), !elements.isEmpty {
                        ForEach((showAll ? elements : Array(elements.prefix(3))), id: \.self) { item in
                            makeEachContent(item)
                                .buttonStyle(.plain)
                        }
                    } else {
                        DetailUnavailableView(title: "Details.unavailable.\(Element.singularName)", symbol: Element.symbol)
                    }
                }
                .frame(maxWidth: infoContentMaxWidth)
            } header: {
                HStack {
                    Text(Element.pluralName)
                        .font(.title2)
                        .bold()
                    if showLocalePicker {
                        DetailSectionOptionPicker(selection: $locale, options: DoriLocale.allCases)
                    }
                    Spacer()
                    if (localizedElements.forLocale(locale)?.count ?? 0) > 3 {
                        Button(action: {
                            showAll.toggle()
                        }, label: {
                            Text(showAll ? "Details.show-less" : "Details.show-all.\(localizedElements.forLocale(locale)?.count ?? 0)")
                                .foregroundStyle(.secondary)
                        })
                        .buttonStyle(.plain)
                    }
                }
                .frame(maxWidth: 615)
            }
        }
    }
}

struct DetailInfoBase<Head: View>: View {
    var detailInfo: [DetailInfoItem]
    var makeHead: () -> Head
    
    init(
        @DetailInfoBuilder content: () -> [DetailInfoItem],
        @ViewBuilder head: @escaping () -> Head
    ) {
        self.detailInfo = content()
        self.makeHead = head
    }
    
    var body: some View {
        VStack {
            makeHead()
                .padding(.vertical, 2)
            CustomGroupBox(cornerRadius: 20) {
                LazyVStack {
                    ForEach(Array(detailInfo.enumerated()), id: \.element.id) { index, info in
                        info._makeView()
                            .buttonStyle(.plain)
                        if index != detailInfo.count - 1 {
                            Divider()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: infoContentMaxWidth)
    }
}

@MainActor
struct DetailInfoItem: Identifiable {
    var id: UUID = .init()
    var titleKey: LocalizedStringResource
    var makeContent: () -> AnyView
    var showLocaleKey: Bool = false
    
    init<Content: View>(
        _ titleKey: LocalizedStringResource,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.titleKey = titleKey
        self.makeContent = {
            AnyView(content())
        }
    }
}

extension DetailInfoItem {
    init<S: StringProtocol>(_ titleKey: LocalizedStringResource, text: S) {
        self.init(titleKey) {
            Text(text)
        }
    }
    init(_ titleKey: LocalizedStringResource, text: LocalizedData<String>) {
        self.init(titleKey) {
            MultilingualText(text)
        }
    }
    
    init(_ titleKey: LocalizedStringResource, date: Date) {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .short
        self.init(titleKey, text: df.string(from: date))
    }
    init(_ titleKey: LocalizedStringResource, date: LocalizedData<Date>) {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .short
        self.init(titleKey, text: date.map { $0 != nil ? df.string(from: $0!) : nil })
    }
}

extension DetailInfoItem {
    @ViewBuilder
    func _makeView() -> some View {
        ListItem {
            Text(titleKey)
                .bold()
        } value: {
            makeContent()
        }
    }
}

extension DetailInfoItem {
    func showsLocaleKey(_ showing: Bool = true) -> Self {
        var mutating = self
        mutating.showLocaleKey = showing
        return mutating
    }
}

@resultBuilder
struct DetailInfoBuilder {
    static func buildExpression(_ expression: DetailInfoItem) -> [DetailInfoItem] {
        [expression]
    }
    
    static func buildBlock(_ components: [DetailInfoItem]...) -> [DetailInfoItem] {
        components.flatMap { $0 }
    }
    
    static func buildOptional(_ component: [DetailInfoItem]?) -> [DetailInfoItem] {
        component ?? []
    }
    static func buildEither(first component: [DetailInfoItem]) -> [DetailInfoItem] {
        component
    }
    static func buildEither(second component: [DetailInfoItem]) -> [DetailInfoItem] {
        component
    }
    
    static func buildArray(_ components: [[DetailInfoItem]]) -> [DetailInfoItem] {
        components.flatMap { $0 }
    }
}
