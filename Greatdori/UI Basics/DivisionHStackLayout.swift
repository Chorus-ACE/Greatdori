//
//  DivisionHStackLayout.swift
//  Greatdori!
//
//  Created by ThreeManager785 on 2026/10/24.
//

import SwiftUI


nonisolated private struct DivisionHStackLayout: Equatable, Sendable {
    let leadingWidth: CGFloat
    let spacing: CGFloat
    let trailingWidth: CGFloat
}

struct DivisionAwareHStack<Leading: View, Trailing: View>: View {
    let alignment: VerticalAlignment
    @ViewBuilder let leading: () -> Leading
    @ViewBuilder let trailing: () -> Trailing

    @State private var divisionLayout: DivisionHStackLayout?

    init(
        alignment: VerticalAlignment = .center,
        @ViewBuilder leading: @escaping () -> Leading,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.alignment = alignment
        self.leading = leading
        self.trailing = trailing
    }

    var body: some View {
        HStack(alignment: alignment, spacing: divisionLayout?.spacing) {
            leading()
                .frame(width: divisionLayout?.leadingWidth)
                .frame(maxWidth: divisionLayout == nil ? .infinity : nil)
            trailing()
                .frame(width: divisionLayout?.trailingWidth)
                .frame(maxWidth: divisionLayout == nil ? .infinity : nil)
        }
        .onGeometryChange(for: DivisionHStackLayout?.self) { proxy in
#if os(iOS)
            if #available(iOS 27.1, *) {
                guard let frame = proxy.reservedRegions(kind: .division)
                    .map(\.frame)
                    .first(where: { $0.width > 0 && $0.height > $0.width }) else {
                    return nil
                }

                let leadingEdge = min(max(frame.minX, 0), proxy.size.width)
                let trailingEdge = min(max(frame.maxX, leadingEdge), proxy.size.width)
                return DivisionHStackLayout(
                    leadingWidth: leadingEdge,
                    spacing: trailingEdge - leadingEdge,
                    trailingWidth: proxy.size.width - trailingEdge
                )
            }
#endif
            return nil
        } action: { newValue in
            divisionLayout = newValue
        }
    }
}
