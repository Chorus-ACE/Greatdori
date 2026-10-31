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
import SDWebImageSwiftUI
import SymbolAvailability

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
    var cornerRadius: CGFloat
    var color: Color
    var dismissable: Bool
    let content: () -> Content
    init(color: Color = .yellow, cornerRaidus: CGFloat = 20, isPresented: Binding<Bool> = .constant(true), dismissable: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.color = color
        self.cornerRadius = cornerRaidus
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
                        Image(systemName: .xmark)
                            .foregroundStyle(.secondary)
                    })
                    .buttonStyle(.plain)
                }
            }
                .padding()
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .foregroundStyle(color)
                            .opacity(0.3)
                        RoundedRectangle(cornerRadius: cornerRadius)
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
private struct LegacyCustomGroupBox<Content: View>: View {
    let content: () -> Content
    var cornerRadius: CGFloat
    var showGroupBox: Bool
    var strokeLineWidth: CGFloat
    var useExtenedConstraints: Bool
    @Environment(\._groupBoxStrokeLineWidth) var envStrokeLineWidth: CGFloat
    @Environment(\._suppressCustomGroupBox) var suppressCustomGroupBox
    @Environment(\._groupBoxBackgroundTintOpacity) var backgroundTintOpacity: CGFloat
    
    init(
        showGroupBox: Bool = true,
        cornerRadius: CGFloat = isMACOS ? 15 : 20,
        useExtenedConstraints: Bool = false,
        strokeLineWidth: CGFloat = 0,
        customGroupBoxVersion: Int? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
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
        #if os(visionOS)
        .contentShape(.hoverEffect, RoundedRectangle(cornerRadius: cornerRadius))
        #endif
        .background {
            if showGroupBox && !suppressCustomGroupBox {
                GeometryReader { geometry in
                    ZStack {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.black.opacity(0.1))
                            .offset(y: 2)
                            .blur(radius: 2)
                            .mask {
                                Rectangle()
                                    .size(width: geometry.size.width + 18, height: geometry.size.height + 18)
                                    .offset(x: -9, y: -9)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: cornerRadius)
                                            .blendMode(.destinationOut)
                                    }
                            }
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.black.opacity(0.1))
                            .offset(y: 2)
                            .blur(radius: 4)
                            .mask {
                                Rectangle()
                                    .size(width: geometry.size.width + 60, height: geometry.size.height + 60)
                                    .offset(x: -30, y: -30)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: cornerRadius)
                                            .blendMode(.destinationOut)
                                    }
                            }
                        
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.accent)
                            .opacity(backgroundTintOpacity)
                        
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color(.floatingCard))
                    }
                }
            }
        }
        .overlay {
            if showGroupBox && !suppressCustomGroupBox {
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

struct CustomGroupBox<Content: View>: View {
    let content: () -> Content
    var cornerRadius: CGFloat
    var showGroupBox: Bool
    var strokeLineWidth: CGFloat
    var useExtenedConstraints: Bool
    @Environment(\._groupBoxStrokeLineWidth) var envStrokeLineWidth: CGFloat
    @Environment(\._suppressCustomGroupBox) var suppressCustomGroupBox

    init(
        showGroupBox: Bool = true,
        cornerRadius: CGFloat = 20,
        useExtenedConstraints: Bool = false,
        strokeLineWidth: CGFloat = 0,
        customGroupBoxVersion: Int? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.showGroupBox = showGroupBox
        self.cornerRadius = cornerRadius
        self.strokeLineWidth = strokeLineWidth
        self.useExtenedConstraints = useExtenedConstraints
        self.content = content
    }

    var body: some View {
        if showGroupBox && !suppressCustomGroupBox {
            #if os(iOS) || os(macOS)
            if #available(iOS 26.0, macOS 26.0, *) {
                ExtendedConstraints(isActive: useExtenedConstraints) {
                    content()
                        .padding(.all, showGroupBox && !suppressCustomGroupBox ? nil : 0)
                }
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
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
                .preference(key: CustomGroupBoxActivePreference.self, value: showGroupBox)
            } else {
                LegacyCustomGroupBox(showGroupBox: showGroupBox, cornerRadius: cornerRadius, useExtenedConstraints: useExtenedConstraints, strokeLineWidth: strokeLineWidth) {
                    content()
                }
            }
            #else
            LegacyCustomGroupBox(showGroupBox: showGroupBox, cornerRadius: cornerRadius, useExtenedConstraints: useExtenedConstraints, strokeLineWidth: strokeLineWidth) {
                content()
            }
            #endif
        } else {
            ExtendedConstraints(isActive: useExtenedConstraints) {
                content()
            }
            .preference(key: CustomGroupBoxActivePreference.self, value: showGroupBox)
        }
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
    @Entry fileprivate var _groupBoxStrokeLineWidth: CGFloat = 0
    @Entry fileprivate var _groupBoxBackgroundTintOpacity: CGFloat = 0
}
extension View {
    func groupBoxStrokeLineWidth(_ width: CGFloat) -> some View {
        environment(\._groupBoxStrokeLineWidth, width)
    }
    func groupBoxBackgroundTintOpacity(_ opacity: CGFloat) -> some View {
        environment(\._groupBoxBackgroundTintOpacity, opacity)
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

// MARK: CustomScrollView
struct CustomScrollView<Content: View>: View {
    let withSystemBackground: Bool
    let content: () -> Content
    
    init(withSystemBackground: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.withSystemBackground = withSystemBackground
        self.content = content
    }
    
    var body: some View {
        ScrollView {
            HStack {
                Spacer(minLength: 0)
                VStack {
                    content()
                }
                .padding()
                Spacer(minLength: 0)
            }
        }
        .scrollDisablesPopover()
        .withSystemBackground(isActive: withSystemBackground)
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
                    Image(systemName: .listBullet)
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
    var role: ButtonRole? = nil
    var doDismiss: Bool = true
    var action: (() -> Void)?
    var label: () -> L
    @Environment(\.dismiss) var dismiss
    var body: some View {
        Button(role: role, action: {
            (action ?? doNothing)()
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
    var content: () -> Content
    
    init(isActive: Bool = true, @ViewBuilder content: @escaping () -> Content) {
        self.isActive = isActive
        self.content = content
    }
    
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
                        Capsule().foregroundStyle(Color.accentColor).scaledToFill().scaleEffect(1.1)
                    }
                }
        })
        .animation(.easeInOut(duration: 0.2), value: filterIsFiltering)
        SorterPickerView(sorter: $sorter, allOptions: sorterKeywords, sortingItemsHaveEndingDate: hasEndingDate)
#else
        Button(action: {
            showFilterSheet.toggle()
        }, label: {
            Image(systemName: "line.3.horizontal.decrease")
                .foregroundStyle(filterIsFiltering ? Color.white : Color.primary)
                .background {
                    if filterIsFiltering {
                        Circle()
                            .fill(Color.accentColor)
                            .scaleEffect(platform == .macOS ? 1.1 : 2.2)
                    }
                }
        })
        .animation(.easeInOut(duration: 0.2), value: filterIsFiltering)
        .accessibilityLabel("Filter")
        .accessibilityValue(filterIsFiltering ? "Accessibility.filter.active" : "Accessibility.filter.not-active")
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

/// An adaptive grid that measures and retains every cell, including offscreen cells.
struct EagerVGrid: Layout {
    var minimumWidth: CGFloat
    var maximumWidth: CGFloat
    var columns: Int? = nil
    var alignment: HorizontalAlignment = .center
    var spacing: CGFloat = 8

    private func metrics(width: CGFloat?, subviews: Subviews) -> (width: CGFloat, columns: Int, cellWidth: CGFloat, heights: [CGFloat]) {
        let proposedWidth = width ?? maximumWidth
        let width = max(0, proposedWidth.isFinite ? proposedWidth : maximumWidth)
        let count = max(1, columns ?? Int((width + spacing) / (minimumWidth + spacing)))
        let cellWidth = min(maximumWidth, max(0, (width - CGFloat(count - 1) * spacing) / CGFloat(count)))
        var heights = [CGFloat]()
        for index in subviews.indices {
            let row = index / count
            if row == heights.count { heights.append(0) }
            heights[row] = max(heights[row], subviews[index].sizeThatFits(.init(width: cellWidth, height: nil)).height)
        }
        return (width, count, cellWidth, heights)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let grid = metrics(width: proposal.width, subviews: subviews)
        return CGSize(width: grid.width, height: grid.heights.reduce(0, +) + CGFloat(max(0, grid.heights.count - 1)) * spacing)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let grid = metrics(width: bounds.width, subviews: subviews)
        let gridWidth = CGFloat(grid.columns) * grid.cellWidth + CGFloat(grid.columns - 1) * spacing
        let leadingSpace = alignment == .trailing ? bounds.width - gridWidth : alignment == .leading ? 0 : (bounds.width - gridWidth) / 2
        var y = bounds.minY
        for index in subviews.indices {
            let row = index / grid.columns
            let column = index % grid.columns
            if column == 0 && row > 0 { y += grid.heights[row - 1] + spacing }
            subviews[index].place(
                at: CGPoint(x: bounds.minX + leadingSpace + CGFloat(column) * (grid.cellWidth + spacing), y: y),
                anchor: .topLeading,
                proposal: .init(width: grid.cellWidth, height: grid.heights[row])
            )
        }
    }
}

// MARK: FlowHStack
struct WrappingHStack: Layout {
    enum RowAlignment {
        case leading
        case trailing
    }
    
    var alignment: RowAlignment = .leading
    var spacing: CGFloat = 8
    var rowSpacing: CGFloat = 8
    
    @available(*, deprecated, message: "Use without `contentWidth`.")
    init(alignment: RowAlignment = .leading, contentWidth: CGFloat) {
        self.alignment = alignment
        self.spacing = 8
        self.rowSpacing = 8
    }
    
    init(alignment: RowAlignment, vSpacing: CGFloat = 8, hSpacing: CGFloat = 8) {
        self.alignment = alignment
        self.spacing = vSpacing
        self.rowSpacing = hSpacing
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        let maxWidth = proposal.width ?? .infinity

        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var usedWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if x + size.width > maxWidth {
                usedWidth = max(usedWidth, x - spacing)
                x = 0
                y += rowHeight + rowSpacing
                rowHeight = 0
            }

            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        usedWidth = max(usedWidth, x - spacing)

        return CGSize(
            width: maxWidth.isInfinite ? usedWidth : maxWidth,
            height: y + rowHeight
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        // 先按“行”把 subviews 分组
        var rows: [[Subviews.Element]] = []
        var currentRow: [Subviews.Element] = []
        var currentRowWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if !currentRow.isEmpty && currentRowWidth + size.width > bounds.width {
                rows.append(currentRow)
                currentRow = []
                currentRowWidth = 0
            }

            currentRow.append(subview)
            currentRowWidth += size.width + spacing
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        // 逐行右对齐放置
        var y = bounds.minY

        for row in rows {
            let sizes = row.map { $0.sizeThatFits(.unspecified) }
            let rowHeight = sizes.map(\.height).max() ?? 0
            let rowWidth = sizes.map(\.width).reduce(0, +)
                + spacing * CGFloat(max(row.count - 1, 0))

                        let startX: CGFloat
            switch alignment {
            case .leading:
                startX = bounds.minX
            case .trailing:
                startX = bounds.maxX - rowWidth
            }

            var x = startX

            for (subview, size) in zip(row, sizes) {
                subview.place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(size)
                )
                x += size.width + spacing
            }

            y += rowHeight + rowSpacing
        }
    }
}

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

// MARK: HighlightableText
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
                            Image(fallingSystemName: item.1)
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
                    Image(fallingSystemName: options.first(where: { $0.2 == selection })!.1)
                })
            }
            .accessibilityValue(options.first(where: { $0.2 == selection })!.0)
#else
            Picker("Search.layout", selection: $selection) {
                ForEach(options, id: \.2) { item in
                    Label(title: {
                        Text(item.0)
                    }, icon: {
                        Image(fallingSystemName: item.1)
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

// MARK: LocalePicker
struct LocalePicker<L: View>: View {
    @Binding var locale: DoriLocale
    var label: (() -> L)?
    init(_ locale: Binding<DoriLocale>, label: @escaping () -> L) {
        self._locale = locale
        self.label = label
    }
    
    init(_ locale: Binding<DoriLocale>) where L == EmptyView {
        self._locale = locale
        self.label = nil
    }
    
    var body: some View {
        Picker(selection: $locale, content: {
            ForEach(DoriLocale.allCases, id: \.self) { item in
                Text(item.rawValue.uppercased())
                    .tag(item)
            }
        }, label: {
            if let label {
                label()
            } else {
                EmptyView()
            }
        })
        .wrapIf(label == nil) {
            $0.labelsHidden()
        }
    }
}

struct MultilingualText: View {
    @Environment(\.disablePopover) var envDisablesPopover
    
    var text: LocalizedData<String>
    var showSecondaryText: Bool = true
    var showLocaleKey: Bool = false
    var reducedStrings: [DoriLocale: String]
    
    @State var isHovering = false
    @State var lastCopiedLocale: DoriLocale?
    @State var copyMessageIsDisplaying = false
    @State private var expandSheetIsDisplaying = false
    
    init(_ text: LocalizedData<String>, showSecondaryText: Bool = true, showLocaleKey: Bool = false) {
        self.text = text
        self.showSecondaryText = showSecondaryText
        self.showLocaleKey = showLocaleKey
        
        var _reducedStrings: [DoriLocale: String] = [:]
        var seenValues: [String] = []
        for locale in text.availableLocales {
            let value = text[locale] ?? ""
            if !seenValues.contains(value) {
                seenValues.append(value)
                _reducedStrings.updateValue(value, forKey: locale)
            }
        }
        
        self.reducedStrings = _reducedStrings
    }
    var body: some View {
        Group {
            #if os(iOS)
            Menu(content: {
                ForEach(reducedStrings.keys.sorted { $0._rawIntValue < $1._rawIntValue }, id: \.self) { locale in
                    Button(action: {
                        copyStringToClipboard(reducedStrings[locale] ?? "")
                        lastCopiedLocale = locale
                        copyMessageIsDisplaying = true
                    }, label: {
                        Text(reducedStrings[locale] ?? "")
                            .lineLimit(nil)
                            .multilineTextAlignment(.trailing)
                            .typesettingLanguage(.explicit(locale.nsLocale().language))
                    })
                    .accessibilityHint("Accessibility.copiable")
                }
                Section {
                    Button {
                        expandSheetIsDisplaying = true
                    } label: {
                        Label("Message.read-more", systemImage: "book.pages")
                    }
                }
            }, label: {
                ZStack(alignment: .trailing, content: {
                    Label(lastCopiedLocale == nil ? "Message.copy.success" : "Message.copy.success.locale.\(lastCopiedLocale!.rawValue.uppercased())", systemImage: "doc.on.doc")
                        .opacity(copyMessageIsDisplaying ? 1 : 0)
                        .offset(y: 2)
                    LabelView(text: text, showSecondaryText: showSecondaryText, showLocaleKey: showLocaleKey)
                        .opacity(copyMessageIsDisplaying ? 0 : 1)
                })
                .animation(.easeIn(duration: 0.2), value: copyMessageIsDisplaying)
                .onChange(of: copyMessageIsDisplaying) {
                    if copyMessageIsDisplaying {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            copyMessageIsDisplaying = false
                        }
                    }
                }
            })
            .menuStyle(.button)
            .buttonStyle(.borderless)
            .menuIndicator(.hidden)
            .foregroundStyle(.primary)
            #else
            LabelView(text: text, showSecondaryText: showSecondaryText, showLocaleKey: showLocaleKey)
                .contextMenu {
                    Button {
                        if let content = text.forPreferredLocale() {
                            copyStringToClipboard(content)
                        }
                    } label: {
                        Label("Message.copy", systemImage: "doc.on.doc")
                    }
                    Button {
                        expandSheetIsDisplaying = true
                    } label: {
                        Label("Message.read-more", systemImage: "book.pages")
                    }
                }
                .onHover { hoverStatus in
                    isHovering = hoverStatus && !envDisablesPopover
                }
                .popover(isPresented: $isHovering, arrowEdge: .bottom) {
                    VStack(alignment: .trailing) {
                        ForEach(reducedStrings.keys.sorted(by: { $0._rawIntValue < $1._rawIntValue }), id: \.self) { locale in
                            Text(reducedStrings[locale] ?? "")
                                .multilineTextAlignment(.trailing)
                                .typesettingLanguage(.explicit(locale.nsLocale().language))
                        }
                        .wrapIf(reducedStrings.values.contains(where: { $0.contains("\n") })) { context in
                            context.insert {
                                Divider()
                            }
                        }
                    }
                    .padding()
                }
            #endif
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(text.forPreferredLocale() ?? "")
        .accessibilityHint("Accessibility.multilingual")
        .sheet(isPresented: $expandSheetIsDisplaying, content: {
            NavigationStack {
                Form {
                    ForEach(text.availableLocales, id: \.self) { locale in
                        VStack(alignment: .leading) {
                            Text(locale.rawValue.uppercased())
                                .bold()
                            Text(text[locale] ?? "")
                                .multilineTextAlignment(.leading)
                                .textSelection(.enabled)
                                .typesettingLanguage(.explicit(locale.nsLocale().language))
                        }
                    }
                }
                .formStyle(.grouped)
                .frame(minHeight: 200)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction, content: {
                        Button(role: .cancel, action: {
                            expandSheetIsDisplaying = false
                        }, label: {
                            Label("Message.read-more.close", systemImage: "xmark")
                                .wrapIf(platform == .macOS, in: { content in
                                    content
                                        .labelStyle(.titleOnly)
                                })
                        })
                    })
                }
            }
        })
    }
    
    struct LabelView: View {
        let text: LocalizedData<String>
        let showSecondaryText: Bool
        let showLocaleKey: Bool
        
        var primaryLocale: DoriLocale?
        var secondaryLocale: DoriLocale?
        
        init(text: LocalizedData<String>, showSecondaryText: Bool, showLocaleKey: Bool) {
            self.text = text
            self.showSecondaryText = showSecondaryText
            self.showLocaleKey = showLocaleKey
            
            let availableLocales = text.availableLocales
            self.primaryLocale = availableLocales.first
            self.secondaryLocale = availableLocales.access(1)
        }
        var body: some View {
            VStack(alignment: .trailing) {
                if let primaryLocale {
                    Text("\(text[primaryLocale] ?? "")\(showLocaleKey ? " (\(primaryLocale.rawValue.uppercased()))" : "")")
                        .typesettingLanguage(.explicit((primaryLocale.nsLocale().language)))
                    
                    if let secondaryLocale, text[secondaryLocale] != text[primaryLocale] {
                        Text("\(text[secondaryLocale] ?? "")\(showLocaleKey ? " (\(secondaryLocale.rawValue.uppercased()))" : "")")
                            .typesettingLanguage(.explicit((secondaryLocale.nsLocale().language)))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .multilineTextAlignment(.trailing)
            .fixedSize(horizontal: false, vertical: true)
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
    
    init(
        startDate: LocalizedData<Date>,
        endDate: LocalizedData<Date>,
        aggregateEndDate: LocalizedData<Date>? = nil,
        distributionStartDate: LocalizedData<Date>? = nil
    ) {
        self.startDate = startDate
        self.endDate = endDate
        self.aggregateEndDate = aggregateEndDate
        self.distributionStartDate = distributionStartDate
    }
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
#if os(iOS)
            Menu(content: {
                VStack(alignment: .trailing) {
                    ForEach(allAvailableLocales, id: \.self) { localeValue in
                        Button(action: {
                            showCopyMessage = true
                        }, label: {
                            MultilingualTextForCountdownInternalNumbersView(startDate: startDate, endDate: endDate, aggregateEndDate: aggregateEndDate, distributionStartDate: distributionStartDate, locale: localeValue)
                        })
                        .accessibilityRemoveTraits(.isButton)
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
        .accessibilityElement(children: .ignore)
        .wrapIf(true, in: {
            if #available(iOS 18.0, macOS 15.0, *) {
                $0.accessibilityLabel(content: { _ in
                    MultilingualTextForCountdownInternalLabel(startDate: startDate, endDate: endDate, aggregateEndDate: aggregateEndDate, distributionStartDate: distributionStartDate, allAvailableLocales: allAvailableLocales)
                })
            } else {
                $0
            }
        })
        .accessibilityHint("Accessibility.multilingual")
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
                    MultilingualTextForCountdownInternalNumbersView(startDate: startDate, endDate: endDate, aggregateEndDate: aggregateEndDate, distributionStartDate: distributionStartDate, locale: DoriLocale.secondaryLocale)
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

// MARK: ListItem
struct ListItem<Content1: View, Content2: View>: View {
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.listItemLayout) var layout
    @Environment(\.listItemTextStyle) var textStyle
    @Environment(\.listItemValueIsLeading) var allowValueLeading
    @Environment(\.listItemTextSelectionIsEnabled) var allowTextSelection
    @Environment(\.defaultMinListRowHeight) private var defaultMinListRowHeight
    let title: Content1
    let value: Content2
    @State private var totalAvailableWidth: CGFloat = 0
    @State private var titleAvailableWidth: CGFloat = 0
    @State private var valueAvailableWidth: CGFloat = 0
    
    init(@ViewBuilder title: () -> Content1, @ViewBuilder value: () -> Content2) {
        self.title = title()
        self.value = value()
    }
    
//    @available(*, deprecated, message: "Use modifiers instead of parameters")
//    init(allowValueLeading: Bool = false, displayMode: ListItemLayout = .automatic, allowTextSelection: Bool = true, @ViewBuilder title: () -> Content1, @ViewBuilder value: () -> Content2) {
//        self.init(allowValueLeading: allowValueLeading, title: { title() }, value: { value() })
//    }
//    
    var body: some View {
        Group {
            if (layout == .compactOnly  || (layout == .basedOnUISizeClass && sizeClass == .regular) || (totalAvailableWidth - titleAvailableWidth - valueAvailableWidth) > 5) && layout != .expandedOnly { // HStack (SHORT)
                HStack {
                    title
                        .bold(textStyle == .bold)
                        .fixedSize(horizontal: true, vertical: true)
                        .onFrameChange(perform: { geometry in
                            titleAvailableWidth = geometry.size.width
                        })
                    Spacer()
                    value
                        .foregroundStyle(textStyle == .native ? .secondary: .primary)
                        .wrapIf(true) { content in
                            if let allowTextSelection {
                                if allowTextSelection {
                                    content.textSelection(.enabled)
                                } else {
                                    content.textSelection(.disabled)
                                }
                            } else {
                                content
                            }
                        }
                        .onFrameChange(perform: { geometry in
                            valueAvailableWidth = geometry.size.width
                        })
                        .multilineTextAlignment(.trailing)
                }
            } else { // VStack (LONG)
                VStack(alignment: .leading) {
                    title
                        .bold(textStyle == .bold)
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
                            .foregroundStyle(textStyle == .native ? .secondary: .primary)
                            .wrapIf(true) { content in
                                if let allowTextSelection {
                                    if allowTextSelection {
                                        content.textSelection(.enabled)
                                    } else {
                                        content.textSelection(.disabled)
                                    }
                                } else {
                                    content
                                }
                            }
                            .onFrameChange(perform: { geometry in
                                valueAvailableWidth = geometry.size.width
                            })
                            .multilineTextAlignment(allowValueLeading ? .leading : .trailing)
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
        .frame(minHeight: defaultMinListRowHeight * (platform == .iOS ? 0.75 : 1))
        .accessibilityElement(children: .contain)
        .accessibilityElement(children: .combine)
        
//        .wrapIf(true, in: {
//            if #available(iOS 18.0, macOS 15.0, *) {
//                $0.accessibilityLabel(content: { _ in
//                    title
//                })
//            } else {
//                $0
//            }
//        })
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
        ListItem(title: {
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
                    EagerVGrid(minimumWidth: elementWidth, maximumWidth: elementWidth, columns: columnNumbers, alignment: .trailing) {
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
            .accessibilityElement(children: .contain)
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

extension View {
    func listItemLayout(_ layout: ListItemLayout) -> some View {
        environment(\.listItemLayout, layout)
    }
    
    func listItemTextStyle(_ style: ListItemTextStyle) -> some View {
        environment(\.listItemTextStyle, style)
    }
    
    func listItemValueAlignment(_ alignment: ListItemValueAlignment) -> some View {
        environment(\.listItemValueIsLeading, alignment == .leading)
    }
    
    func listItemTextSelection(_ isEnabled: Bool?) -> some View {
        environment(\.listItemTextSelectionIsEnabled, isEnabled)
    }
}

extension EnvironmentValues {
    @Entry var listItemLayout: ListItemLayout = .automatic
    @Entry var listItemTextStyle: ListItemTextStyle = .bold
    @Entry var listItemValueIsLeading: Bool = false
    @Entry var listItemTextSelectionIsEnabled: Bool? = nil
}

enum ListItemLayout: Hashable, Equatable {
    case compactOnly
    case expandedOnly
    case automatic
    case basedOnUISizeClass
}

enum ListItemTextStyle {
    case bold
    case native
}

enum ListItemValueAlignment {
    case leading
    case trailing
}
