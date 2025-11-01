//===---*- Greatdori! -*---------------------------------------------------===//
//
// CornerstoneView.swift
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

// As name, this file is the cornerstone for the whole app, providing the most basic & repeative views.
// Views marked with [×] are deprecated.
// Please consider sorting structures in alphabetical order.

// MARK: This file should be view only.

import DoriKit
import SwiftUI
import CoreMotion

// MARK: Constants
let bannerWidth: CGFloat = isMACOS ? 370 : 420
let bannerSpacing: CGFloat = isMACOS ? 10 : 15
let imageButtonSize: CGFloat = isMACOS ? 30 : 35
let cardThumbnailSideLength: CGFloat = isMACOS ? 64 : 72
let filterItemHeight: CGFloat = isMACOS ? 25 : 35
let infoContentMaxWidth: CGFloat = 600

// MARK: Banner
struct Banner<Content: View>: View {
    var isPresented: Binding<Bool>
    var color: Color
    var dismissable: Bool
    let content: () -> Content
    init(color: Color = .yellow, isPresented: Binding<Bool> = .constant(true), dismissable: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.color = color
        self.isPresented = isPresented
        self.dismissable = dismissable
        self.content = content
    }
    var body: some View {
        if isPresented.wrappedValue {
            HStack {
                content()
                Spacer()
                if dismissable {
                    Button(action: {
                        isPresented.wrappedValue = false
                    }, label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.secondary)
                    })
                    .buttonStyle(.plain)
                }
            }
                .padding()
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .foregroundStyle(color)
                            .opacity(0.3)
                        RoundedRectangle(cornerRadius: 15)
                            .strokeBorder(color.opacity(0.9), lineWidth: 2)
                    }
                }
        }
    }
}

// MARK: CompactToggle
struct CompactToggle: View {
    var isLit: Bool?
    var action: (() -> Void)? = nil
    var size: CGFloat = isMACOS ? 17 : 20
    
    var body: some View {
        if let action {
            Button(action: {
                action()
            }, label: {
                CompactToggleLabel(isLit: isLit, size: size)
            })
        } else {
            CompactToggleLabel(isLit: isLit, size: size)
        }
    }
    
    struct CompactToggleLabel: View {
        var isLit: Bool?
        var size: CGFloat
        var body: some View {
            Group {
                if isLit != false {
                    Circle()
                        .frame(width: size)
                        .foregroundStyle(.accent)
                        .inverseMask {
                            Image(systemName: isLit == true ? "checkmark" : "minus")
                                .font(.system(size: size*(isLit == true ? 0.5 : 0.6)))
                                .bold()
                        }
                } else {
                    Circle()
                        .strokeBorder(Color.accent, lineWidth: isMACOS ? 1.5 : 2)
                        .frame(width: size, height: size)
                }
            }
                .animation(.easeInOut(duration: 0.05), value: isLit)
                .contentShape(Circle())
        }
    }
}


// MARK: CustomGroupBox
struct CustomGroupBox<Content: View>: View {
    let content: () -> Content
    var cornerRadius: CGFloat = 15
    var showGroupBox: Bool = true
    var strokeLineWidth: CGFloat = 0
    var useExtenedConstraints: Bool = false
    @AppStorage("customGroupBoxVersion") var customGroupBoxVersion = 2
    @Environment(\._groupBoxStrokeLineWidth) var envStrokeLineWidth: CGFloat
    @Environment(\._suppressCustomGroupBox) var suppressCustomGroupBox
    init(showGroupBox: Bool = true, cornerRadius: CGFloat = 15, useExtenedConstraints: Bool = false, strokeLineWidth: CGFloat = 0, @ViewBuilder content: @escaping () -> Content) {
        self.showGroupBox = showGroupBox
        self.cornerRadius = cornerRadius
        self.strokeLineWidth = strokeLineWidth
        self.useExtenedConstraints = useExtenedConstraints
        self.content = content
    }
    var body: some View {
        ExtendedConstraints(isActive: useExtenedConstraints) {
            content()
                .padding(.all, showGroupBox && !suppressCustomGroupBox ? nil : 0)
        }
        .background {
            if showGroupBox && !suppressCustomGroupBox {
                if customGroupBoxVersion == 2 {
                    GeometryReader { geometry in
                        ZStack {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(.black.opacity(0.1))
                                .offset(y: 4)
                                .blur(radius: 4)
                                .mask {
                                    Rectangle()
                                        .size(width: geometry.size.width + 24, height: geometry.size.height + 24)
                                        .offset(x: -12, y: -12)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: cornerRadius)
                                                .blendMode(.destinationOut)
                                        }
                                }
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(.black.opacity(0.1))
                                .offset(y: 4)
                                .blur(radius: 16)
                                .mask {
                                    Rectangle()
                                        .size(width: geometry.size.width + 96, height: geometry.size.height + 96)
                                        .offset(x: -48, y: -48)
                                        .overlay {
                                            RoundedRectangle(cornerRadius: cornerRadius)
                                                .blendMode(.destinationOut)
                                        }
                                }
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .fill(Color(.floatingCard))
                        }
                    }
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
#if !os(macOS)
                            .foregroundStyle(Color(.secondarySystemGroupedBackground))
#else
                            .foregroundStyle(Color(NSColor.quaternarySystemFill))
#endif
                        let strokeLineWidth = strokeLineWidth > 0 ? strokeLineWidth : envStrokeLineWidth
                        if strokeLineWidth > 0 {
                            RoundedRectangle(cornerRadius: cornerRadius)
                                .strokeBorder(.tint.opacity(0.9), lineWidth: strokeLineWidth)
                        }
                    }
                }
            }
        }
        .overlay {
            if showGroupBox && !suppressCustomGroupBox && customGroupBoxVersion == 2 {
                LinearGradient(
                    colors: [
                        Color(.floatingCardTopBorder),
                        Color(.floatingCard)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .mask {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.clear)
                        .stroke(.black, style: .init(lineWidth: 1))
                }
                .allowsHitTesting(false)
            }
        }
        .overlay {
            if showGroupBox && !suppressCustomGroupBox {
                let strokeLineWidth = strokeLineWidth > 0 ? strokeLineWidth : envStrokeLineWidth
                if strokeLineWidth > 0 {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .strokeBorder(.tint.opacity(0.9), lineWidth: strokeLineWidth)
                        .allowsHitTesting(false)
                }
            }
        }
        // We pass the group box status bidirectionally to allow
        // other views that suppress the custom group box
        // to provide their own representation
        .preference(key: CustomGroupBoxActivePreference.self, value: showGroupBox)
    }
}
struct CustomGroupBoxActivePreference: PreferenceKey {
    @safe nonisolated(unsafe) static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}
extension EnvironmentValues {
    @Entry var _suppressCustomGroupBox: Bool = false
}

extension EnvironmentValues {
    @Entry fileprivate var _groupBoxStrokeLineWidth: CGFloat = 0
}
extension View {
    func groupBoxStrokeLineWidth(_ width: CGFloat) -> some View {
        environment(\._groupBoxStrokeLineWidth, width)
    }
}

// MARK: CustomGroupBoxOld [×]
struct CustomGroupBoxOld<Content: View>: View {
    @Binding var backgroundOpacity: CGFloat
    let content: () -> Content
    init(backgroundOpacity: Binding<CGFloat> = .constant(1), @ViewBuilder content: @escaping () -> Content) {
        self._backgroundOpacity = backgroundOpacity
        self.content = content
    }
    var body: some View {
#if os(iOS)
        content()
            .padding()
            .background {
                RoundedRectangle(cornerRadius: 15)
                    .foregroundStyle(Color(.secondarySystemGroupedBackground))
            }
#elseif os(macOS)
        GroupBox {
            content()
                .padding()
        }
#endif
    }
}


// MARK: CustomStack
struct CustomStack<Content: View>: View {
    let axis: Axis
    let spacing: CGFloat?
    let hAlignment: HorizontalAlignment
    let vAlignment: VerticalAlignment
    let content: () -> Content
    
    init(
        axis: Axis,
        spacing: CGFloat? = nil,
        hAlignment: HorizontalAlignment = .center,
        vAlignment: VerticalAlignment = .center,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.axis = axis
        self.spacing = spacing
        self.hAlignment = hAlignment
        self.vAlignment = vAlignment
        self.content = content
    }
    
    var body: some View {
        Group {
            switch axis {
            case .horizontal:
                HStack(alignment: vAlignment, spacing: spacing) {
                    content()
                }
            case .vertical:
                VStack(alignment: hAlignment, spacing: spacing) {
                    content()
                }
            }
        }
    }
}


// MARK: DetailsIDSwitcher
struct DetailsIDSwitcher<Content: View>: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let destination: () -> Content
    @Binding var currentID: Int
    var allIDs: [Int]
    init(currentID: Binding<Int>, allIDs: [Int], @ViewBuilder destination: @escaping () -> Content) {
        self._currentID = currentID
        self.allIDs = allIDs
        self.destination = destination
    }
    
    var body: some View {
        Group {
            if sizeClass == .regular {
                HStack(spacing: 0) {
                    Button(action: {
                        if currentID > 1 {
                            currentID = allIDs[(allIDs.firstIndex(where: { $0 == currentID }) ?? 0 ) - 1]
                        }
                    }, label: {
                        Label("Detail.previous", systemImage: "arrow.backward")
                    })
                    .disabled(currentID <= 1 || currentID > allIDs.last ?? 0)
                    NavigationLink(destination: {
                        //                EventSearchView()
                        destination()
                    }, label: {
                        Text("#\(String(currentID))")
                            .fontDesign(.monospaced)
                            .bold()
                    })
                    Button(action: {
                        currentID = allIDs[(allIDs.firstIndex(where: { $0 == currentID }) ?? 0 ) + 1]
                    }, label: {
                        Label("Detail.next", systemImage: "arrow.forward")
                    })
                    .disabled(currentID >= allIDs.last ?? 0)
                }
                .disabled(currentID == 0)
                .disabled(allIDs.isEmpty)
            } else {
                NavigationLink(destination: {
                    destination()
                }, label: {
                    Image(systemName: "list.bullet")
                })
            }
        }
        .contextMenu {
            Group {
                Button(action: {
                    if currentID > 1 {
                        currentID = allIDs[(allIDs.firstIndex(where: { $0 == currentID }) ?? 0 ) - 1]
                    }
                }, label: {
                    Label("Detail.previous", systemImage: "arrow.backward")
                })
                .disabled(currentID <= 1 || currentID > allIDs.last ?? 0)
                Button(action: {
                    currentID = allIDs[(allIDs.firstIndex(where: { $0 == currentID }) ?? 0 ) + 1]
                }, label: {
                    Label("Detail.next", systemImage: "arrow.forward")
                })
                .disabled(currentID >= allIDs.last ?? 0)
            }
            .disabled(currentID == 0)
            .disabled(allIDs.isEmpty)
        }
    }
}
// # Guidance for `DetailsIDSwitcher`
//
// ```swift
// ToolbarItemGroup(content: {
//     DetailsIDSwitcher(currentID: $itemID, allIDs: $allItemIDs, destination: { ItemSearchView() })
//         .onChange(of: itemID) {
//             information = nil
//         }
//         .onAppear {
//             showSubtitle = (sizeClass == .compact)
//         }
// })
//```


// MARK: DimissButton
struct DismissButton<L: View>: View {
    var action: () -> Void
    var label: () -> L
    var doDismiss: Bool = true
    @Environment(\.dismiss) var dismiss
    var body: some View {
        Button(action: {
            action()
            if doDismiss {
                dismiss()
            }
        }, label: {
            label()
        })
    }
}


// MARK: ExtendedConstraints
struct ExtendedConstraints<Content: View>: View {
    var isActive: Bool = true
    let content: () -> Content
    var body: some View {
        if isActive {
            VStack {
                Spacer(minLength: 0)
                HStack {
                    Spacer(minLength: 0)
                    content()
                    Spacer(minLength: 0)
                }
                Spacer(minLength: 0)
            }
        } else {
            content()
        }
    }
}


// MARK: FilterAndSorterPicker
struct FilterAndSorterPicker: View {
    @Binding var showFilterSheet: Bool
    @Binding var sorter: DoriSorter
    var filterIsFiltering: Bool
    let sorterKeywords: [DoriSorter.Keyword]
    let hasEndingDate: Bool
    var body: some View {
#if os(macOS)
        HStack(spacing: 0) {
            Button(action: {
                showFilterSheet.toggle()
            }, label: {
                (filterIsFiltering ? Color.white : .primary)
                    .scaleEffect(2) // a larger value has no side effects because we're using `mask`
                    .mask {
                        // We use `mask` to prgacha unexpected blink
                        // while changing `foregroundStyle`.
                        Image(systemName: "line.3.horizontal.decrease")
                    }
                    .background {
                        if filterIsFiltering {
                            Capsule().foregroundStyle(Color.accentColor).scaledToFill().scaleEffect(isMACOS ? 1.1 : 1.65)
                        }
                    }
            })
            .animation(.easeInOut(duration: 0.2), value: filterIsFiltering)
            SorterPickerView(sorter: $sorter, allOptions: sorterKeywords, sortingItemsHaveEndingDate: hasEndingDate)
        }
#else
        Button(action: {
            showFilterSheet.toggle()
        }, label: {
            (filterIsFiltering ? Color.white : .primary)
                .scaleEffect(2) // a larger value has no side effects because we're using `mask`
                .mask {
                    // We use `mask` to prgacha unexpected blink
                    // while changing `foregroundStyle`.
                    Image(systemName: "line.3.horizontal.decrease")
                }
                .background {
                    if filterIsFiltering {
                        Capsule().foregroundStyle(Color.accentColor).scaledToFill().scaleEffect(isMACOS ? 1.1 : 1.65)
                    }
                }
        })
        .animation(.easeInOut(duration: 0.2), value: filterIsFiltering)
        SorterPickerView(sorter: $sorter, allOptions: sorterKeywords, sortingItemsHaveEndingDate: hasEndingDate)
#endif
    }
}
// # Guidance for `FilterAndSorterPicker`
//
// ```swift
// ToolbarItemGroup {
//     FilterAndSorterPicker(showFilterSheet: $showFilterSheet, sorter: $sorter, filterIsFiltering: filter.isFiltered, sorterKeywords: PreviewItem.applicableSortingTypes)
// }
//```


#if os(macOS)
/// Hi, what happened?
/// We NEED this to workaround a bug (maybe of SwiftUI?)
struct HereTheWorld<each T, V: View>: NSViewRepresentable {
    private var controller: NSViewController
    private var viewBuilder: (repeat each T) -> V
    init(arguments: (repeat each T) = (), @ViewBuilder view: @escaping (repeat each T) -> V) {
        self.controller = NSHostingController(rootView: view(repeat each arguments))
        self.viewBuilder = view
    }
    func makeNSView(context: Context) -> some NSView {
        self.controller.view
    }
    func updateNSView(_ nsView: NSViewType, context: Context) {}
    func updateArguments(_ arguments: (repeat each T)) {
        let newView = viewBuilder(repeat each arguments)
        controller.view = NSHostingView(rootView: newView)
    }
}
#else
/// Hi, what happened?
/// We NEED this to workaround a bug (maybe of SwiftUI?)
struct HereTheWorld<each T, V: View>: UIViewRepresentable {
    private var controller: UIViewController
    private var viewBuilder: (repeat each T) -> V
    init(arguments: (repeat each T) = (), @ViewBuilder view: @escaping (repeat each T) -> V) {
        self.controller = UIHostingController(rootView: view(repeat each arguments))
        self.viewBuilder = view
    }
    func makeUIView(context: Context) -> some UIView {
        self.controller.view
    }
    func updateUIView(_ nsView: UIViewType, context: Context) {}
    func updateArguments(_ arguments: (repeat each T)) {
        let newView = viewBuilder(repeat each arguments)
        let newUIViewController = UIHostingController(rootView: newView)
        let newUIView = newUIViewController.view
        newUIViewController.view = nil // detach
        controller.view = newUIView
    }
}
#endif


// MARK: LayoutPicker
struct LayoutPicker<T: Hashable>: View {
    @Binding var selection: T
    var options: [(LocalizedStringKey, String, T)]
    var body: some View {
        if options.count > 1 {
#if os(iOS)
            Menu {
                Picker("", selection: $selection.animation(.easeInOut(duration: 0.2))) {
                    ForEach(options, id: \.2) { item in
                        Label(title: {
                            Text(item.0)
                        }, icon: {
                            Image(_internalSystemName: item.1)
                        })
                        .tag(item.2)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } label: {
                Label(title: {
                    Text("Search.layout")
                }, icon: {
                    Image(_internalSystemName: options.first(where: { $0.2 == selection })!.1)
                })
            }
#else
            Picker("Search.layout", selection: $selection) {
                ForEach(options, id: \.2) { item in
                    Label(title: {
                        Text(item.0)
                    }, icon: {
                        Image(_internalSystemName: item.1)
                    })
                    .tag(item.2)
                }
            }
            .pickerStyle(.inline)
#endif
        }
    }
}
// # Guidance for `LayoutPicker`
//
// ```swift
// ToolbarItem {
//     LayoutPicker(selection: $layout, options: [("Localized String Key", "symbol", value)])
// }
//```


// MARK: MultilingualText
struct MultilingualText: View {
    let source: LocalizedData<String>
    var showSecondaryText: Bool = true
    //    let locale: Locale
    var showLocaleKey: Bool = false
    var allowPopover = true
    @Environment(\.disablePopover) var envDisablesPopover
    @State var isHovering = false
    @State var allLocaleTexts: [String] = []
    @State var shownLocaleValueDict: [String: DoriLocale] = [:]
    @State var primaryDisplayString = ""
    @State var showCopyMessage = false
    @State var lastCopiedLocaleValue: DoriLocale? = nil
    
    init(_ source: LocalizedData<String>, showSecondaryText: Bool = true, showLocaleKey: Bool = false, allowPopover: Bool = true) {
        self.source = source
        self.showSecondaryText = showSecondaryText
        self.showLocaleKey = showLocaleKey
        self.allowPopover = allowPopover
        
        var __allLocaleTexts: [String] = []
        var __shownLocaleValueDict: [String: DoriLocale] = [:]
        for lang in DoriLocale.allCases {
            if let pendingString = source.forLocale(lang) {
                if !__allLocaleTexts.contains(pendingString) {
                    __allLocaleTexts.append("\(pendingString)\(showLocaleKey ? " (\(lang.rawValue.uppercased()))" : "")")
                    __shownLocaleValueDict.updateValue(lang, forKey: __allLocaleTexts.last!)
                }
            }
        }
        self._allLocaleTexts = .init(initialValue: __allLocaleTexts)
        self._shownLocaleValueDict = .init(initialValue: __shownLocaleValueDict)
    }
    var body: some View {
        Group {
#if !os(macOS)
            Menu(content: {
                ForEach(allLocaleTexts, id: \.self) { localeValue in
                    Button(action: {
                        copyStringToClipboard(localeValue)
                        print(shownLocaleValueDict)
                        lastCopiedLocaleValue = shownLocaleValueDict[localeValue]
                        print()
                        showCopyMessage = true
                    }, label: {
                        Text(localeValue)
                            .lineLimit(nil)
                            .multilineTextAlignment(.trailing)
                            .textSelection(.enabled)
                            .typesettingLanguage(.explicit((shownLocaleValueDict[localeValue]?.nsLocale().language) ?? Locale.current.language))
                    })
                }
            }, label: {
                ZStack(alignment: .trailing, content: {
                    Label(lastCopiedLocaleValue == nil ? "Message.copy.success" : "Message.copy.success.locale.\(lastCopiedLocaleValue!.rawValue.uppercased())", systemImage: "document.on.document")
                        .opacity(showCopyMessage ? 1 : 0)
                        .offset(y: 2)
                    MultilingualTextInternalLabel(source: source, showSecondaryText: showSecondaryText, showLocaleKey: showLocaleKey)
                        .opacity(showCopyMessage ? 0 : 1)
                })
                .animation(.easeIn(duration: 0.2), value: showCopyMessage)
                .onChange(of: showCopyMessage, {
                    if showCopyMessage {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showCopyMessage = false
                        }
                    }
                })
            })
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
            .foregroundStyle(.primary)
#else
            MultilingualTextInternalLabel(source: source, showSecondaryText: showSecondaryText, showLocaleKey: showLocaleKey)
                .onHover { isHovering in
                    if allowPopover {
                        self.isHovering = isHovering && !envDisablesPopover
                    }
                }
                .popover(isPresented: $isHovering, arrowEdge: .bottom) {
                    VStack(alignment: .trailing) {
                        ForEach(allLocaleTexts, id: \.self) { text in
                            Text(text)
                                .multilineTextAlignment(.trailing)
                                .typesettingLanguage(.explicit((shownLocaleValueDict[text]?.nsLocale().language) ?? Locale.current.language))
                            if text.contains("\n") && text != allLocaleTexts.last {
                                Text("")
                            }
//                                .typesettingLanguage(.explicit(DoriAPI.Locale(rawValue: localeValue)?.nsLocale()))
                        }
                    }
                    .padding()
                }
#endif
        }
    }
    struct MultilingualTextInternalLabel: View {
        let source: LocalizedData<String>
        //    let locale: Locale
        let showSecondaryText: Bool
        let showLocaleKey: Bool
        let allowTextSelection: Bool = true
        @State var primaryDisplayString: String = ""
        var body: some View {
            VStack(alignment: .trailing) {
                if let sourceInPrimaryLocale = source.forPreferredLocale(allowsFallback: false) {
                    Text("\(sourceInPrimaryLocale)\(showLocaleKey ? " (\(DoriLocale.primaryLocale.rawValue.uppercased()))" : "")")
                        .typesettingLanguage(.explicit((DoriLocale.primaryLocale.nsLocale().language)))
                        .onAppear {
                            primaryDisplayString = sourceInPrimaryLocale
                        }
                } else if let sourceInSecondaryLocale = source.forSecondaryLocale(allowsFallback: false) {
                    Text("\(sourceInSecondaryLocale)\(showLocaleKey ? " (\(DoriLocale.secondaryLocale.rawValue.uppercased()))" : "")")
                        .typesettingLanguage(.explicit((DoriLocale.secondaryLocale.nsLocale().language)))
                        .onAppear {
                            primaryDisplayString = sourceInSecondaryLocale
                        }
                } else if let sourceInJP = source.jp {
                    Text("\(sourceInJP)\(showLocaleKey ? " (JP)" : "")")
                        .typesettingLanguage(.explicit((DoriLocale.jp.nsLocale().language)))
                        .onAppear {
                            primaryDisplayString = sourceInJP
                        }
                } else if let sourceInWhateverLocale = source.en {
                    Text("\(sourceInWhateverLocale)\(showLocaleKey ? " (EN)" : "")")
                        .typesettingLanguage(.explicit((DoriLocale.en.nsLocale().language)))
                        .onAppear {
                            primaryDisplayString = sourceInWhateverLocale
                        }
                } else if let sourceInWhateverLocale = source.tw {
                    Text("\(sourceInWhateverLocale)\(showLocaleKey ? " (TW)" : "")")
                        .typesettingLanguage(.explicit((DoriLocale.tw.nsLocale().language)))
                        .onAppear {
                            primaryDisplayString = sourceInWhateverLocale
                        }
                } else if let sourceInWhateverLocale = source.cn {
                    Text("\(sourceInWhateverLocale)\(showLocaleKey ? " (CN)" : "")")
                        .typesettingLanguage(.explicit((DoriLocale.cn.nsLocale().language)))
                        .onAppear {
                            primaryDisplayString = sourceInWhateverLocale
                        }
                } else if let sourceInWhateverLocale = source.kr {
                    Text("\(sourceInWhateverLocale)\(showLocaleKey ? " (KR)" : "")")
                        .typesettingLanguage(.explicit((DoriLocale.kr.nsLocale().language)))
                        .onAppear {
                            primaryDisplayString = sourceInWhateverLocale
                        }
                }
                if showSecondaryText {
                    if let secondarySourceInSecondaryLang = source.forSecondaryLocale(allowsFallback: false), secondarySourceInSecondaryLang != primaryDisplayString {
                        Text("\(secondarySourceInSecondaryLang)\(showLocaleKey ? " (\(DoriLocale.secondaryLocale.rawValue.uppercased()))" : "")")
                            .typesettingLanguage(.explicit((DoriLocale.secondaryLocale.nsLocale().language)))
                            .foregroundStyle(.secondary)
                    } else if let secondarySourceInJP = source.jp, secondarySourceInJP != primaryDisplayString {
                        Text("\(secondarySourceInJP)\(showLocaleKey ? " (JP)" : "")")
                            .typesettingLanguage(.explicit((DoriLocale.jp.nsLocale().language)))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .multilineTextAlignment(.trailing)
            .wrapIf(allowTextSelection, in: { content in
                content
                    .textSelection(.enabled)
            }, else: { content in
                content
                    .textSelection(.disabled)
            })
        }
    }
}


// MARK: MultilingualTextForCountdown
struct MultilingualTextForCountdown: View {
    let startDate: LocalizedData<Date>
    let endDate: LocalizedData<Date>
    let aggregateEndDate: LocalizedData<Date>?
    let distributionStartDate: LocalizedData<Date>?
    
    @State var isHovering = false
    @State var allAvailableLocales: [DoriLocale] = []
    @State var primaryDisplayLocale: DoriLocale?
    @State var showCopyMessage = false
    
    init(_ source: Event) {
        self.startDate = source.startAt
        self.endDate = source.endAt
        self.aggregateEndDate = source.aggregateEndAt
        self.distributionStartDate = source.distributionStartAt
    }
    init(_ source: Gacha) {
        self.startDate = source.publishedAt
        self.endDate = source.closedAt
        self.aggregateEndDate = nil
        self.distributionStartDate = nil
    }
    var body: some View {
        Group {
#if !os(macOS)
            Menu(content: {
                VStack(alignment: .trailing) {
                    ForEach(allAvailableLocales, id: \.self) { localeValue in
                        Button(action: {
//                            copyStringToClipboard(getCountdownLocalizedString(source, forLocale: localeValue) ?? LocalizedStringResource(""))
                            showCopyMessage = true
                        }, label: {
                            MultilingualTextForCountdownInternalNumbersView(startDate: startDate, endDate: endDate, aggregateEndDate: aggregateEndDate, distributionStartDate: distributionStartDate, locale: localeValue)
                        })
                    }
                }
            }, label: {
                ZStack(alignment: .trailing, content: {
                    Label("Message.copy.unavailable.for.countdown", systemImage: "exclamationmark.circle")
                        .offset(y: 2)
                        .opacity(showCopyMessage ? 1 : 0)
                    MultilingualTextForCountdownInternalLabel(startDate: startDate, endDate: endDate, aggregateEndDate: aggregateEndDate, distributionStartDate: distributionStartDate, allAvailableLocales: allAvailableLocales)
                        .opacity(showCopyMessage ? 0 : 1)
                })
                .animation(.easeIn(duration: 0.2), value: showCopyMessage)
                .onChange(of: showCopyMessage, {
                    if showCopyMessage {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showCopyMessage = false
                        }
                    }
                })
            })
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
            .foregroundStyle(.primary)
#else
            MultilingualTextForCountdownInternalLabel(startDate: startDate, endDate: endDate, aggregateEndDate: aggregateEndDate, distributionStartDate: distributionStartDate, allAvailableLocales: allAvailableLocales)
                .onHover { isHovering in
                    self.isHovering = isHovering
                }
                .popover(isPresented: $isHovering, arrowEdge: .bottom) {
                    VStack(alignment: .trailing) {
                        ForEach(allAvailableLocales, id: \.self) { localeValue in
                            MultilingualTextForCountdownInternalNumbersView(startDate: startDate, endDate: endDate, aggregateEndDate: aggregateEndDate, distributionStartDate: distributionStartDate, locale: localeValue)
                        }
                    }
                    .padding()
                }
#endif
        }
        .onAppear {
            allAvailableLocales = []
            for lang in DoriLocale.allCases {
                if startDate.availableInLocale(lang) {
                    allAvailableLocales.append(lang)
                }
            }
        }
    }
    struct MultilingualTextForCountdownInternalLabel: View {
        let startDate: LocalizedData<Date>
        let endDate: LocalizedData<Date>
        let aggregateEndDate: LocalizedData<Date>?
        let distributionStartDate: LocalizedData<Date>?
        let allAvailableLocales: [DoriLocale]
        let allowTextSelection: Bool = true
        @State var primaryDisplayingLocale: DoriLocale? = nil
        var body: some View {
            VStack(alignment: .trailing) {
                if allAvailableLocales.contains(DoriLocale.primaryLocale) {
                    MultilingualTextForCountdownInternalNumbersView(startDate: startDate, endDate: endDate, aggregateEndDate: aggregateEndDate, distributionStartDate: distributionStartDate, locale: DoriLocale.primaryLocale)
                        .onAppear {
                            primaryDisplayingLocale = DoriLocale.primaryLocale
                        }
                } else if allAvailableLocales.contains(DoriLocale.secondaryLocale) {
                    MultilingualTextForCountdownInternalNumbersView(startDate: startDate, endDate: endDate, aggregateEndDate: aggregateEndDate, distributionStartDate: distributionStartDate, locale: DoriLocale.primaryLocale)
                        .onAppear {
                            primaryDisplayingLocale = DoriLocale.secondaryLocale
                        }
                } else if allAvailableLocales.contains(.jp) {
                    MultilingualTextForCountdownInternalNumbersView(startDate: startDate, endDate: endDate, aggregateEndDate: aggregateEndDate, distributionStartDate: distributionStartDate, locale: .jp)
                        .onAppear {
                            primaryDisplayingLocale = .jp
                        }
                } else if !allAvailableLocales.isEmpty {
                    MultilingualTextForCountdownInternalNumbersView(startDate: startDate, endDate: endDate, aggregateEndDate: aggregateEndDate, distributionStartDate: distributionStartDate, locale: allAvailableLocales.first!)
                        .onAppear {
                            print(allAvailableLocales)
                            primaryDisplayingLocale = allAvailableLocales.first!
                        }
                }
                
                if allAvailableLocales.contains(DoriLocale.secondaryLocale), DoriLocale.secondaryLocale != primaryDisplayingLocale {
                    MultilingualTextForCountdownInternalNumbersView(startDate: startDate, endDate: endDate, aggregateEndDate: aggregateEndDate, distributionStartDate: distributionStartDate, locale: DoriLocale.secondaryLocale)
                        .foregroundStyle(.secondary)
                } else if allAvailableLocales.contains(.jp), .jp != primaryDisplayingLocale {
                    MultilingualTextForCountdownInternalNumbersView(startDate: startDate, endDate: endDate, aggregateEndDate: aggregateEndDate, distributionStartDate: distributionStartDate, locale: .jp)
                        .foregroundStyle(.secondary)
                }
            }
            .wrapIf(allowTextSelection, in: { content in
                content
                    .textSelection(.enabled)
            }, else: { content in
                content
                    .textSelection(.disabled)
            })
            .onAppear {
//                print(allAvailableLocales)
            }
        }
    }
    struct MultilingualTextForCountdownInternalNumbersView: View {
//        let event: DoriFrontend.Event.Event
        let startDate: LocalizedData<Date>
        let endDate: LocalizedData<Date>
        let aggregateEndDate: LocalizedData<Date>?
        let distributionStartDate: LocalizedData<Date>?
        let locale: DoriLocale
        var body: some View {
            if let startDate = startDate.forLocale(locale),
               let endDate = endDate.forLocale(locale) {
                if startDate > .now {
                    Text("Countdown.start-at.\(Text(startDate, style: .relative)).\(locale.rawValue.uppercased())")
                } else if endDate > .now {
                    Text("Countdown.end-at.\(Text(endDate, style: .relative)).\(locale.rawValue.uppercased())")
                } else if let aggregateEndDate = aggregateEndDate?.forLocale(locale), aggregateEndDate > .now {
                    Text("Countdown.results-in.\(Text(aggregateEndDate, style: .relative)).\(locale.rawValue.uppercased())")
                } else if let distributionStartDate = distributionStartDate?.forLocale(locale), distributionStartDate > .now {
                    Text("Countdown.rewards-in.\(Text(distributionStartDate, style: .relative)).\(locale.rawValue.uppercased())")
                } else {
                    Text("Countdown.completed.\(locale.rawValue.uppercased())")
                }
            }
        }
    }
}

// MARK: MultilingualTextForCountdownAlt
struct MultilingualTextForCountdownAlt: View {
    let date: LocalizedData<Date>
    
    @State var isHovering = false
    @State var allAvailableLocales: [DoriLocale] = []
    @State var primaryDisplayLocale: DoriLocale?
    @State var showCopyMessage = false
    
    var body: some View {
        Group {
#if !os(macOS)
            Menu(content: {
                VStack(alignment: .trailing) {
                    ForEach(allAvailableLocales, id: \.self) { localeValue in
                        Button(action: {
                            //                            copyStringToClipboard(getCountdownLocalizedString(source, forLocale: localeValue) ?? LocalizedStringResource(""))
                            showCopyMessage = true
                        }, label: {
                            MultilingualTextForCountdownAltInternalNumbersView(date: date, locale: localeValue)
                        })
                    }
                }
            }, label: {
                ZStack(alignment: .trailing, content: {
                    Label("Message.copy.unavailable.for.countdown", systemImage: "exclamationmark.circle")
                        .offset(y: 2)
                        .opacity(showCopyMessage ? 1 : 0)
                    MultilingualTextForCountdownAltInternalLabel(date: date, allAvailableLocales: allAvailableLocales)
                        .opacity(showCopyMessage ? 0 : 1)
                })
                .animation(.easeIn(duration: 0.2), value: showCopyMessage)
                .onChange(of: showCopyMessage, {
                    if showCopyMessage {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            showCopyMessage = false
                        }
                    }
                })
            })
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
            .foregroundStyle(.primary)
#else
            MultilingualTextForCountdownAltInternalLabel(date: date, allAvailableLocales: allAvailableLocales)
                .onHover { isHovering in
                    self.isHovering = isHovering
                }
                .popover(isPresented: $isHovering, arrowEdge: .bottom) {
                    VStack(alignment: .trailing) {
                        ForEach(allAvailableLocales, id: \.self) { localeValue in
                            MultilingualTextForCountdownAltInternalNumbersView(date: date, locale: localeValue)
                        }
                    }
                    .padding()
                }
#endif
        }
        .onAppear {
            allAvailableLocales = []
            for lang in DoriLocale.allCases {
                if date.availableInLocale(lang) {
                    allAvailableLocales.append(lang)
                }
            }
        }
    }
    struct MultilingualTextForCountdownAltInternalLabel: View {
        let date: LocalizedData<Date>
        let allAvailableLocales: [DoriLocale]
        let allowTextSelection: Bool = true
        @State var primaryDisplayingLocale: DoriLocale? = nil
        var body: some View {
            VStack(alignment: .trailing) {
                if allAvailableLocales.contains(DoriLocale.primaryLocale) {
                    MultilingualTextForCountdownAltInternalNumbersView(date: date, locale: DoriLocale.primaryLocale)
                        .onAppear {
                            primaryDisplayingLocale = DoriLocale.primaryLocale
                        }
                } else if allAvailableLocales.contains(DoriLocale.secondaryLocale) {
                    MultilingualTextForCountdownAltInternalNumbersView(date: date, locale: DoriLocale.secondaryLocale)
                        .onAppear {
                            primaryDisplayingLocale = DoriLocale.secondaryLocale
                        }
                } else if allAvailableLocales.contains(.jp) {
                    MultilingualTextForCountdownAltInternalNumbersView(date: date, locale: .jp)
                        .onAppear {
                            primaryDisplayingLocale = .jp
                        }
                } else if !allAvailableLocales.isEmpty {
                    MultilingualTextForCountdownAltInternalNumbersView(date: date, locale: allAvailableLocales.first!)
                        .onAppear {
                            print(allAvailableLocales)
                            primaryDisplayingLocale = allAvailableLocales.first!
                        }
                }
                
                if allAvailableLocales.contains(DoriLocale.secondaryLocale), DoriLocale.secondaryLocale != primaryDisplayingLocale {
                    MultilingualTextForCountdownAltInternalNumbersView(date: date, locale: DoriLocale.secondaryLocale)
                        .foregroundStyle(.secondary)
                } else if allAvailableLocales.contains(.jp), .jp != primaryDisplayingLocale {
                    MultilingualTextForCountdownAltInternalNumbersView(date: date, locale: .jp)
                        .foregroundStyle(.secondary)
                }
            }
            .wrapIf(allowTextSelection, in: { content in
                content
                    .textSelection(.enabled)
            }, else: { content in
                content
                    .textSelection(.disabled)
            })
            .onAppear {
                //                print(allAvailableLocales)
            }
        }
    }
    struct MultilingualTextForCountdownAltInternalNumbersView: View {
        //        let event: DoriFrontend.Event.Event
        let date: LocalizedData<Date>
        let locale: DoriLocale
        var body: some View {
            if let localizedDate = date.forLocale(locale) {
                if localizedDate > .now {
                    Text("Countdown.release-in.\(Text(localizedDate, style: .relative)).\(locale.rawValue.uppercased())")
                } else {
                    Text("Countdown.released.\(locale.rawValue.uppercased())")
                }
            }
        }
    }
}


// MARK: ListItemView
struct ListItemView<Content1: View, Content2: View>: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    let title: Content1
    let value: Content2
    var allowValueLeading: Bool = false
    var displayMode: ListItemType = .automatic
    var allowTextSelection: Bool = true
    @State private var totalAvailableWidth: CGFloat = 0
    @State private var titleAvailableWidth: CGFloat = 0
    @State private var valueAvailableWidth: CGFloat = 0
    
    init(@ViewBuilder title: () -> Content1, @ViewBuilder value: () -> Content2, allowValueLeading: Bool = false, displayMode: ListItemType = .automatic, allowTextSelection: Bool = true) {
        self.title = title()
        self.value = value()
        self.allowValueLeading = allowValueLeading
        self.displayMode = displayMode
        self.allowTextSelection = allowTextSelection
    }
    
    var body: some View {
        Group {
            if (displayMode == .compactOnly  || (displayMode == .basedOnUISizeClass && sizeClass == .regular) || (totalAvailableWidth - titleAvailableWidth - valueAvailableWidth) > 5) && displayMode != .expandedOnly { // HStack (SHORT)
                HStack {
                    title
                        .bold()
                        .fixedSize(horizontal: true, vertical: true)
                        .onFrameChange(perform: { geometry in
                            titleAvailableWidth = geometry.size.width
                        })
                    Spacer()
                    value
                        .wrapIf(allowTextSelection, in: { content in
                            content.textSelection(.enabled)
                        }, else: { content in
                            content.textSelection(.disabled)
                        })
                        .onFrameChange(perform: { geometry in
                            valueAvailableWidth = geometry.size.width
                        })
                }
            } else { // VStack (LONG)
                VStack(alignment: .leading) {
                    title
                        .bold()
                        .fixedSize(horizontal: true, vertical: true)
                        .onFrameChange(perform: { geometry in
                            titleAvailableWidth = geometry.size.width
                        })
                        .padding(.vertical, 1)
                    HStack {
                        if !allowValueLeading {
                            Spacer()
                        }
                        value
                            .wrapIf(allowTextSelection, in: { content in
                                content.textSelection(.enabled)
                            }, else: { content in
                                content.textSelection(.disabled)
                            })
                            .onFrameChange(perform: { geometry in
                                valueAvailableWidth = geometry.size.width
                            })
                        if allowValueLeading {
                            Spacer()
                        }
                    }
                }
            }
        }
        .onFrameChange(perform: { geometry in
            totalAvailableWidth = geometry.size.width
        })
    }
}


// MARK: ListItemWithWrappingView
struct ListItemWithWrappingView<Content1: View, Content2: View, Content3: View, T>: View {
    let title: Content1
    let element: (T?) -> Content2
    let caption: Content3
    let columnNumbers: Int?
    let elementWidth: CGFloat
    var contentArray: [T?]
    @State var contentArrayChunked: [[T?]] = []
    @State var titleWidth: CGFloat = 0 // Fixed
    @State var captionWidth: CGFloat = 0 // Fixed
    //    @State var cardsContentRegularWidth: CGFloat = 0 // Fixed
    @State var fixedWidth: CGFloat = 0 //Fixed
    @State var useCompactLayout = true
    
    init(@ViewBuilder title: () -> Content1, @ViewBuilder element: @escaping (T?) -> Content2, @ViewBuilder caption: () -> Content3, contentArray: [T], columnNumbers: Int? = nil, elementWidth: CGFloat) {
        self.title = title()
        self.element = element
        self.caption = caption()
        self.contentArray = contentArray
        self.elementWidth = elementWidth
        self.columnNumbers = columnNumbers
    }
    var body: some View {
        ListItemView(title: {
            title
                .onFrameChange(perform: { geometry in
                    titleWidth = geometry.size.width
                    fixedWidth = (CGFloat(contentArray.count)*elementWidth) + titleWidth + captionWidth
                })
        }, value: {
            HStack {
                if !useCompactLayout {
                    HStack {
                        ForEach(0..<contentArray.count, id: \.self) { elementIndex in
                            element(contentArray[elementIndex])
                            //contentArray[elementIndex]
                        }
                    }
                } else {
                    LazyVGrid(columns: columnNumbers == nil ? [.init(.adaptive(minimum: elementWidth, maximum: elementWidth))] : Array(repeating: .init(.fixed(elementWidth)), count: columnNumbers!), alignment: .trailing) {
                        ForEach(0..<contentArray.count, id: \.self) { index in
                            if contentArray[index] != nil {
                                element(contentArray[index])
                            } else {
//                                Rectangle()
//                                    .opacity(0)
//                                    .frame(width: 0, height: 0)
                            }
                        }
                    }
//                    Grid(alignment: .trailing) {
//                        ForEach(0..<contentArrayChunked.count, id: \.self) { rowIndex in
//                            GridRow {
//                                ForEach(0..<contentArrayChunked[rowIndex].count, id: \.self) { columnIndex in
//
//                            }
//                        }
//                    }
//                    .gridCellAnchor(.trailing)
                }
                caption
                    .onFrameChange(perform: { geometry in
                        captionWidth = geometry.size.width
                        fixedWidth = (CGFloat(contentArray.count)*elementWidth) + titleWidth + captionWidth
                    })
            }
        })
        .onAppear {
            fixedWidth = (CGFloat(contentArray.count)*elementWidth) + titleWidth + captionWidth
            
            if let columnNumbers {
                contentArrayChunked = contentArray.chunked(into: columnNumbers)
                for i in 0..<contentArrayChunked.count {
                    while contentArrayChunked[i].count < columnNumbers {
                        contentArrayChunked[i].insert(nil, at: 0)
                    }
                }
            }
        }
        .onFrameChange(perform: { geometry in
            if (geometry.size.width - fixedWidth) < 50 && !useCompactLayout {
                useCompactLayout = true
            } else if (geometry.size.width - fixedWidth) > 50 && useCompactLayout {
                useCompactLayout = false
            }
        })
    }
}

struct WrappingHStack<Content: View>: View {
    var alignment: HorizontalAlignment
    var rowSpacing: CGFloat?
    var columnSpacing: CGFloat?
    var contentWidth: CGFloat
    var makeContent: () -> Content
    
    init(
        alignment: HorizontalAlignment = .center,
        rowSpacing: CGFloat? = nil,
        columnSpacing: CGFloat? = nil,
        contentWidth: CGFloat,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.alignment = alignment
        self.rowSpacing = rowSpacing
        self.columnSpacing = columnSpacing
        self.contentWidth = contentWidth
        self.makeContent = content
    }
    
    @Environment(\.layoutDirection) private var layoutDirection
    
    var body: some View {
        LazyVGrid(
            columns: [.init(.adaptive(minimum: contentWidth), spacing: columnSpacing)],
            alignment: alignment,
            spacing: rowSpacing
        ) {
            makeContent()
                .environment(\.layoutDirection, layoutDirection == .leftToRight ? .leftToRight : .rightToLeft)
        }
        .environment(\.layoutDirection, layoutDirection == .leftToRight ? .rightToLeft : .leftToRight)
    }
}

struct HighlightableText: View {
    private var resolvedText: String
    private var prefixText: String = ""
    private var suffixText: String = ""
    private var id: Int? = nil
    @State private var attributedText: AttributedString = ""
    
//    init(_ titleKey: LocalizedStringResource) {
//        self.init(String(localized: titleKey))
//    }
//    init(verbatim text: String) {
//        self.init(text)
//    }
//    init(prefix: String = "", _ text: String, suffix: String = "") {
//       
//    }
    @_disfavoredOverload
    init<S: StringProtocol>(_ string: S, prefix: String = "", suffix: String = "", itemID: Int? = nil) {
        self.resolvedText = String(string)
        self._attributedText = .init(initialValue: .init(string))
        self.prefixText = prefix
        self.suffixText = suffix
        self.id = itemID
    }
    
    @Environment(\.searchedKeyword) private var searchedKeyword: Binding<String>?
    
    var body: some View {
        Group {
            if let id {
                Text(prefixText) + Text(attributedText) + Text(suffixText) + Text("Typography.bold-dot-seperater") + Text(verbatim: "#\(String(id))").fontDesign(.monospaced)
            } else {
                Text(prefixText) + Text(attributedText) + Text(suffixText)
            }
        }
        .onChange(of: resolvedText, searchedKeyword?.wrappedValue, initial: true) {
            attributedText = highlightOccurrences(of: searchedKeyword?.wrappedValue ?? "", in: resolvedText) ?? .init(resolvedText)
        }
    }
}
