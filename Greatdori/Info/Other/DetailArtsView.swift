//===---*- Greatdori! -*---------------------------------------------------===//
//
// DetailArtsView.swift
//
// This source file is part of the Greatdori! open source project
//
// Copyright (c) 2025 the Greatdori! project authors
// Licensed under Apache License v2.0
//
// See https://greatdori.memz.top/LICENSE.txt for license information
// See https://greatdori.memz.top/CONTRIBUTORS.txt for the list of Greatdori! project authors
//
//===----------------------------------------------------------------------===//


import DoriKit
import SwiftUI
import QuickLook
import SDWebImageSwiftUI

@resultBuilder
struct ArtsBuilder {
    static func buildExpression(_ expression: ArtsTab) -> [ArtsTab] {
        [expression]
    }
    
    static func buildBlock(_ components: [ArtsTab]...) -> [ArtsTab] {
        components.flatMap { $0 }
    }
    
    static func buildOptional(_ component: [ArtsTab]?) -> [ArtsTab] {
        component ?? []
    }
    static func buildEither(first component: [ArtsTab]) -> [ArtsTab] {
        component
    }
    static func buildEither(second component: [ArtsTab]) -> [ArtsTab] {
        component
    }
    
    static func buildArray(_ components: [[ArtsTab]]) -> [ArtsTab] {
        components.flatMap { $0 }
    }
}

@resultBuilder
struct ArtsItemBuilder {
    static func buildExpression(_ expression: ArtsItem) -> [ArtsItem] {
        [expression]
    }
    
    static func buildBlock(_ components: [ArtsItem]...) -> [ArtsItem] {
        components.flatMap { $0 }
    }
    
    static func buildOptional(_ component: [ArtsItem]?) -> [ArtsItem] {
        component ?? []
    }
    static func buildEither(first component: [ArtsItem]) -> [ArtsItem] {
        component
    }
    static func buildEither(second component: [ArtsItem]) -> [ArtsItem] {
        component
    }
    
    static func buildArray(_ components: [[ArtsItem]]) -> [ArtsItem] {
        components.flatMap { $0 }
    }
}

struct ArtsTab: Identifiable, Hashable, Equatable {
    let id: String
    var tabName: LocalizedStringResource
    var content: [ArtsItem]
}
extension ArtsTab {
    init(id: String, name: LocalizedStringResource, @ArtsItemBuilder content: () -> [ArtsItem]) {
        self.id = id
        self.tabName = name
        self.content = content()
    }
}

struct ArtsItem: Hashable, Equatable {
    let id = UUID()
    var title: LocalizedStringResource
    var url: URL
    var expectedRatio: CGFloat = 3.0
}

// MARK: DetailArtsSection
struct DetailArtsSection: View {
    var information: [ArtsTab]
    @State var tab: String? = nil
#if os(macOS)
    @State private var previewController = PreviewController()
#endif
    @State var nativeImages = [UUID: PlatformImage]()
    @State var quickLookOnFocusItem: ImageLookItem?
    @State var hiddenItems: [UUID] = []
    
    let itemMinimumWidth: CGFloat = 280
    let itemMaximumWidth: CGFloat = 320
    var body: some View {
        LazyVStack(pinnedViews: .sectionHeaders) {
            Section(content: {
                Group {
                    if let tab, let tabContent = information.first(where: {$0.id == tab}) {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: itemMinimumWidth, maximum: itemMaximumWidth))]) {
                            ForEach(tabContent.content, id: \.self) { item in
                                if !hiddenItems.contains(item.id) {
                                    Button(action: {
                                        #if os(iOS)
                                        if let image = nativeImages[item.id] {
                                            quickLookOnFocusItem = .init(
                                                image: image,
                                                title: .init(localized: tabContent.tabName),
                                                subtitle: .init(localized: item.title)
                                            )
                                        }
                                        #else
                                        // Build visible items and open Quick Look at the tapped item
                                        let visibleItems = tabContent.content.filter { !hiddenItems.contains($0.id) }
                                        previewController.fileURLs = visibleItems.map(\.url)
                                        if let selectedIndex = visibleItems.firstIndex(where: { $0.id == item.id }) {
                                            previewController.showPanel(startingAt: selectedIndex)
                                        } else {
                                            previewController.showPanel()
                                        }
                                        #endif
                                    }, label: {
                                        CustomGroupBox {
                                            VStack {
                                                Spacer(minLength: 0)
                                                ZStack {
                                                    WebImage(url: item.url) { image in
                                                        image
                                                            .resizable()
                                                            .antialiased(true)
                                                            .scaledToFit()
                                                    } placeholder: {
                                                        RoundedRectangle(cornerRadius: 10)
                                                            .fill(getPlaceholderColor())
                                                            .aspectRatio(3, contentMode: .fit)
                                                    }
                                                    .interpolation(.high)
                                                    .onSuccess { image, _, _ in
                                                        DispatchQueue.main.async { // yield
                                                            nativeImages.updateValue(image, forKey: item.id)
                                                        }
                                                    }
                                                    .onFailure { _ in
                                                        DispatchQueue.main.async { // yield
                                                            hiddenItems.append(item.id)
                                                        }
                                                    }
                                                }
                                                Text(item.title)
                                                    .multilineTextAlignment(.center)
                                                Spacer(minLength: 0)
                                            }
                                        }
                                    })
                                    .buttonStyle(.plain)
                                    .imageContextMenu([.init(url: item.url, description: item.title)])
                                }
                            }
                        }
                    } else {
                        DetailUnavailableView(title: "Details.arts.unavailable", symbol: "photo.on.rectangle.angled")
                    }
                }
                .frame(maxWidth: 600)
            }, header: {
                HStack {
                    Text("Details.arts")
                        .font(.title2)
                        .bold()
                    //                    if information.count > 1 {
                    DetailSectionOptionPicker(selection: $tab, options: information.map(\.id), labels: information.reduce(into: [String?: String]()) { $0.updateValue(String(localized: $1.tabName), forKey: $1.id) })
                    //                    }
                    Spacer()
                }
                .frame(maxWidth: 615)
            })
        }
        .onAppear {
            if tab == nil {
                tab = information.first!.id
            }
        }
        #if os(iOS)
        .fullScreenCover(item: $quickLookOnFocusItem) { item in
            ImageLookView(image: item.image, title: item.title, subtitle: item.subtitle)
        }
        #endif
    }
    
    struct ImageLookItem: Identifiable {
        var id = UUID()
        var image: PlatformImage
        var title: String
        var subtitle: String
    }
}
extension DetailArtsSection {
    init(@ArtsBuilder content: () -> [ArtsTab]) {
        self.information = content()
    }
}

#if os(iOS)
struct ImageLookView: View {
    var image: UIImage
    var title: String
    var subtitle: String
    @Environment(\.dismiss) private var dismiss
    @State private var isShareViewPresented = false
    @State private var isFullScreen = false
    var body: some View {
        NavigationStack {
            VStack {
                _ZoomScrollView {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .scaledToFit()
                }
                .ignoresSafeArea()
            }
            .onTapGesture {
                isFullScreen.toggle()
            }
            .sheet(isPresented: $isShareViewPresented) {
                _ImageShareView(image: image)
            }
            .toolbar {
                if !isFullScreen {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Dismiss", systemImage: "xmark") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        VStack {
                            Text(title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            Text(subtitle)
                                .font(.caption2)
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 40)
                        .wrapIf(true) { content in
                            if #available(iOS 26.0, *) {
                                content
                                    .glassEffect()
                            } else {
                                content
                            }
                        }
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Button("Share…", systemImage: "square.and.arrow.up") {
                            isShareViewPresented = true
                        }
                    }
                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(.fixed, placement: .bottomBar)
                    }
                    ToolbarItemGroup(placement: .bottomBar) {
                        Button("Image.save.photos", systemImage: "photo.badge.plus") {
                            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                        }
                        Button("Image.copy.image", systemImage: "document.on.document") {
                            UIPasteboard.general.image = image
                        }
                        if #available(iOS 18.0, macOS 15.0, *) {
                            Button("Image.copy.subject", systemImage: "circle.dashed.rectangle") {
                                Task {
                                    if let _data = image.pngData(), let result = await getImageSubject(_data) {
                                        UIPasteboard.general.image = .init(data: result)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .statusBarHidden(isFullScreen)
        .animation(.spring(duration: 0.3, bounce: 0.15), value: isFullScreen)
    }
}
private struct _ZoomScrollView<Content: View>: UIViewRepresentable {
    var minimumZoomScale: CGFloat = 1
    var maximumZoomScale: CGFloat = 5
    let hostingController: UIHostingController<Content>
    
    init(
        minimumZoomScale: CGFloat = 1,
        maximumZoomScale: CGFloat = 5,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.minimumZoomScale = minimumZoomScale
        self.maximumZoomScale = maximumZoomScale
        self.hostingController = .init(rootView: content())
    }
    
    let scrollView = UIScrollView()
    
    func makeUIView(context: Context) -> UIScrollView {
        let hostedView = hostingController.view!
        hostedView.translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.addSubview(hostedView)
        
        scrollView.contentInsetAdjustmentBehavior = .never
        NSLayoutConstraint.activate([
            hostedView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            hostedView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            hostedView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            hostedView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            hostedView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            hostedView.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
        
        scrollView.delegate = context.coordinator
        scrollView.minimumZoomScale = minimumZoomScale
        scrollView.maximumZoomScale = maximumZoomScale
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        
        let doubleTapRecognizer = UITapGestureRecognizer(target: context.coordinator, action: #selector(ScrollZoomDelegate<Content>.onDoubleTap(with:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(doubleTapRecognizer)
        
        return scrollView
    }
    func updateUIView(_ uiView: UIViewType, context: Context) {}
    func makeCoordinator() -> ScrollZoomDelegate<Content> {
        ScrollZoomDelegate(parent: self)
    }
    
    class ScrollZoomDelegate<C: View>: NSObject, UIScrollViewDelegate {
        var parent: _ZoomScrollView<C>
        
        init(parent: _ZoomScrollView<C>) {
            self.parent = parent
        }
        
        func viewForZooming(in scrollView: UIScrollView) -> UIView? {
            parent.hostingController.view
        }
        
        @objc
        func onDoubleTap(with recognizer: UITapGestureRecognizer) {
            let pointInView = recognizer.location(in: parent.hostingController.view)
            
            var newZoomScale = parent.scrollView.zoomScale * 2
            newZoomScale = min(newZoomScale, parent.scrollView.maximumZoomScale)
            if parent.scrollView.zoomScale > 1 {
                newZoomScale = 1
            }
            
            let scrollViewSize = parent.scrollView.bounds.size
            let w = scrollViewSize.width / newZoomScale
            let h = scrollViewSize.height / newZoomScale
            let x = pointInView.x - (w / 2.0)
            let y = pointInView.y - (h / 2.0)
            
            let rectToZoomTo = CGRectMake(x, y, w, h);
            
            parent.scrollView.zoom(to: rectToZoomTo, animated: true)
        }
    }
}

private struct _ImageShareView: UIViewControllerRepresentable {
    var image: UIImage
    
    init(image: UIImage) {
        self.image = image
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [image], applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {}
}
#endif // os(iOS)
