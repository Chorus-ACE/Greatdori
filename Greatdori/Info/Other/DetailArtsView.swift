//===---*- Greatdori! -*---------------------------------------------------===//
//
// DetailArtsView.swift
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
import QuickLook
import SDWebImageSwiftUI
import SymbolAvailability

#if os(visionOS)
import RealityKit
#endif

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
    var tabName: LocalizedStringResource
    var content: [ArtsItem]
    var ratio: CGFloat
    
    var id: String {
        tabName.key
    }
    
    init(_ tabName: LocalizedStringResource, content: [ArtsItem], ratio: CGFloat = 1) {
        self.tabName = tabName
        self.content = content
        self.ratio = ratio
    }
    
    init(_ name: LocalizedStringResource, ratio: CGFloat = 1, @ArtsItemBuilder content: () -> [ArtsItem]) {
        self.tabName = name
        self.content = content()
        self.ratio = ratio
    }
}

struct ArtsItem: Hashable, Equatable {
    let id = UUID()
    var title: LocalizedStringResource
    var url: URL
    var ratio: CGFloat? = nil
    var forceApplyRatio: Bool = false
}

// MARK: DetailArtsSection
struct DetailArtsSection: View {
    var information: [ArtsTab]
    @State var tab: String? = nil
    #if os(macOS)
    @State private var previewController = PreviewController()
    #endif
    @State var nativeImages = [UUID: PlatformImage]()
    @State var imageFrames = [UUID: CGRect]()
    @State var quickLookOnFocusItem: ImageLookItem?
    @State var hiddenItems: [UUID] = []
    
    let itemMinimumWidth: CGFloat = 280
    let itemMaximumWidth: CGFloat = 440
    var body: some View {
        Section {
            Group {
                if let tab, let tabContent = information.first(where: {$0.id == tab}), !tabContent.content.isEmpty, tabContent.content.contains(where: { !hiddenItems.contains($0.id) }) {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: itemMinimumWidth, maximum: itemMaximumWidth))]) {
                        ForEach(tabContent.content, id: \.self) { item in
                            if !hiddenItems.contains(item.id) {
                                Button(action: {
                                    #if !os(macOS)
                                    if let image = nativeImages[item.id], let frame = imageFrames[item.id] {
                                        quickLookOnFocusItem = .init(
                                            image: image,
                                            title: .init(localized: tabContent.tabName),
                                            subtitle: .init(localized: item.title),
                                            imageFrame: frame
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
                                            WebImage(url: item.url) { image in
                                                image
                                                    .resizable()
                                                    .antialiased(true)
                                                    .aspectRatio(item.forceApplyRatio ? (item.ratio ?? tabContent.ratio) : nil, contentMode: .fit)
                                            } placeholder: {
                                                RoundedRectangle(cornerRadius: 10)
                                                    .fill(getPlaceholderColor())
                                                    .aspectRatio(item.ratio ?? tabContent.ratio, contentMode: .fit)
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
                                            .background {
                                                GeometryReader { geometry in
                                                    let frame = geometry.frame(in: .global)
                                                    Color.clear
                                                        .onChange(of: frame) {
                                                            imageFrames.updateValue(frame, forKey: item.id)
                                                        }
                                                }
                                            }
                                            HighlightableText(String(localized: item.title))
                                                .multilineTextAlignment(.center)
                                            Spacer(minLength: 0)
                                        }
                                    }
                                    .accessibilityAddTraits(.isImage)
                                })
                                .buttonStyle(.plain)
                                .buttonBorderShape(.roundedRectangle(radius: 20))
                                .imageContextMenu([.init(url: item.url, description: item.title)])
                            }
                        }
                    }
                } else {
                    DetailUnavailableView(title: "Details.arts.unavailable", symbol: "photo.on.rectangle.angled")
                }
            }
            .frame(maxWidth: infoContentMaxWidth)
        } header: {
            HStack {
                Text("Details.arts")
                    .font(.title2)
                    .bold()
                if information.count > 1 || !(information.first?.tabName.key.isEmpty ?? true) {
                    DetailSectionOptionPicker(selection: $tab, options: information.map(\.id), labels: information.reduce(into: [String?: String]()) { $0.updateValue(String(localized: $1.tabName), forKey: $1.id) })
                }
                Spacer()
            }
            .frame(maxWidth: 615)
            .detailSectionHeader()
            .onAppear {
                if tab == nil {
                    tab = information.first!.id
                }
            }
            #if os(iOS)
            .fullScreenCover(item: $quickLookOnFocusItem) { item in
                ImageLookView(image: item.image, title: item.title, subtitle: item.subtitle, imageFrame: item.imageFrame)
            }
            #elseif os(visionOS)
            .window(item: $quickLookOnFocusItem) { item in
                ImageLookView(image: item.image, title: item.title, subtitle: item.subtitle, imageFrame: item.imageFrame)
            }
            #endif
        }
    }
    
    struct ImageLookItem: Identifiable {
        var id = UUID()
        var image: PlatformImage
        var title: String
        var subtitle: String
        var imageFrame: CGRect
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
    var imageFrame: CGRect
    @Environment(\.dismiss) private var dismiss
    @State private var dismissingOffset = CGSize.zero
    @State private var dismissingScale: CGFloat = 1
    @State private var dismissingOpacity = 1.0
    @State private var imageOpacity = 1.0
    @State private var isShareViewPresented = false
    @State private var isFullScreen = false
    @State private var currentZoomScale: CGFloat = 1
    @State private var imageSourceFrame = CGRect()
    @State private var isCopied = false
    var body: some View {
        NavigationStack {
            VStack {
                _ZoomScrollView(current: $currentZoomScale) {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.high)
                        .antialiased(true)
                        .scaledToFit()
                        .background {
                            GeometryReader { geometry in
                                Color.clear
                                    .ignoresSafeArea()
                                    .onAppear {
                                        imageSourceFrame = geometry.frame(in: .global)
                                    }
                            }
                        }
                }
                .ignoresSafeArea()
                .offset(dismissingOffset)
                .scaleEffect(dismissingScale)
                .opacity(imageOpacity)
            }
            .background {
                Rectangle()
                    .fill(Color(.systemBackground))
                    .ignoresSafeArea()
                    .opacity(dismissingOpacity)
            }
            .onTapGesture {
                isFullScreen.toggle()
            }
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        guard currentZoomScale <= 1 else { return }
                        dismissingOffset = value.translation
                    }
                    .onChanged { value in
                        guard currentZoomScale <= 1 else { return }
                        dismissingScale = max(min(1.0 - value.translation.height * 0.001, 1), 0)
                    }
                    .onChanged { value in
                        guard currentZoomScale <= 1 else { return }
                        dismissingOpacity = max(min(1.0 - value.translation.height * 0.01, 1), 0)
                    }
                    .onEnded { value in
                        guard currentZoomScale <= 1 else { return }
                        if value.translation.height > 100 {
                            withAnimation {
                                dismissingOffset = .init(
                                    width: imageFrame.origin.x - imageSourceFrame.origin.x,
                                    height: imageFrame.origin.y - imageSourceFrame.origin.y
                                )
                                dismissingScale = imageFrame.width / imageSourceFrame.width
                                imageOpacity = 0
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                var transaction = Transaction()
                                transaction.disablesAnimations = true
                                withTransaction(transaction) {
                                    dismiss()
                                }
                            }
                        } else {
                            withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                                dismissingOffset = .zero
                                dismissingScale = 1
                                dismissingOpacity = 1
                            }
                        }
                    }
            )
            .sheet(isPresented: $isShareViewPresented) {
                _ImageShareView(image: image)
            }
            .toolbar {
                if !isFullScreen {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Details.arts.dismiss", systemImage: "xmark") {
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
                    ToolbarItemGroup(placement: .bottomBar) {
                        if !isCopied {
                            Button("Image.save.photos", systemImage: "photo.badge.plus") {
                                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                                didCopied()
                            }
                            Button("Image.copy.image", systemImage: "doc.on.doc") {
                                UIPasteboard.general.image = image
                                didCopied()
                            }
                            if #available(iOS 18.0, macOS 15.0, *) {
                                Button("Image.copy.subject", systemImage: "circle.dashed.rectangle") {
                                    Task {
                                        if let _data = image.pngData(), let result = await getImageSubject(_data) {
                                            UIPasteboard.general.image = .init(data: result)
                                            didCopied()
                                        }
                                    }
                                }
                            }
                        } else {
                            Image(systemName: .checkmark)
                        }
                    }
                    if #available(iOS 26.0, *) {
                        ToolbarSpacer(placement: .bottomBar)
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Button("Details.arts.share", systemImage: "square.and.arrow.up") {
                            isShareViewPresented = true
                        }
                    }
                }
            }
        }
        .statusBarHidden(isFullScreen)
        .animation(.spring(duration: 0.3, bounce: 0.15), value: isFullScreen)
        .presentationBackground(.clear)
    }
    
    func didCopied() {
        withAnimation {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                isCopied = false
            }
        }
    }
}
private struct _ZoomScrollView<Content: View>: UIViewRepresentable {
    var currentZoomScale: Binding<CGFloat>
    var minimumZoomScale: CGFloat = 1
    var maximumZoomScale: CGFloat = 5
    let hostingController: UIHostingController<Content>
    
    init(
        current: Binding<CGFloat>,
        minimumZoomScale: CGFloat = 1,
        maximumZoomScale: CGFloat = 5,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.currentZoomScale = current
        self.minimumZoomScale = minimumZoomScale
        self.maximumZoomScale = maximumZoomScale
        self.hostingController = .init(rootView: content())
    }
    
    let scrollView = UIScrollView()
    
    func makeUIView(context: Context) -> UIScrollView {
        let hostedView = hostingController.view!
        hostedView.backgroundColor = .clear
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
        
        scrollView.backgroundColor = .clear
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
        func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
            parent.currentZoomScale.wrappedValue = scale
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
#elseif os(visionOS) // os(iOS)
struct ImageLookView: View {
    var image: UIImage
    var title: String
    var subtitle: String
    var imageFrame: CGRect
    @Environment(\.dismiss) private var dismiss
    @Environment(SceneDelegate.self) private var sceneDelegate
    @State private var isShareViewPresented = false
    @State private var spatial3DImage: AnyObject?
    @State private var imageEntity = Entity()
    @State private var imageAspectRatio: CGFloat = 1
    @State private var component: (any Component)? // availability
    var body: some View {
        ZStack {
            if let component, #available(visionOS 26.0, *) {
                GeometryReader3D { geometry in
                    RealityView { content in
                        imageEntity.components.set(component)
                        if let aspectRatio = (component as! ImagePresentationComponent).aspectRatio(for: .mono) {
                            imageAspectRatio = CGFloat(aspectRatio)
                        }
                        let availableBounds = content.convert(geometry.frame(in: .local), from: .local, to: .scene)
                        scaleImagePresentationToFit(in: availableBounds)
                        content.add(imageEntity)
                    } update: { content in
                        let presentationScreenSize = (component as! ImagePresentationComponent).presentationScreenSize
                        guard presentationScreenSize != .zero else {
                            return
                        }
                        let originalPosition = imageEntity.position(relativeTo: nil)
                        imageEntity.setPosition(
                            .init(originalPosition.x, originalPosition.y, 0),
                            relativeTo: nil
                        )
                        let availableBounds = content.convert(geometry.frame(in: .local), from: .local, to: .scene)
                        scaleImagePresentationToFit(in: availableBounds)
                    }
                    .preferredSurroundingsEffect(.dark)
                    .onAppear {
                        guard let windowScene = sceneDelegate.windowScene else {
                            return
                        }
                        windowScene.requestGeometryUpdate(.Vision(resizingRestrictions: .uniform))
                    }
                    .onChange(of: imageAspectRatio) {
                        guard let windowScene = sceneDelegate.windowScene else {
                            return
                        }
                        
                        let windowSceneSize = windowScene.effectiveGeometry.coordinateSpace.bounds.size
                        
                        // width / height = aspect ratio
                        // Change ONLY the width to match the aspect ratio
                        let width = imageAspectRatio * windowSceneSize.height
                        
                        // Keep the height the same
                        let size = CGSize(width: width, height: UIProposedSceneSizeNoPreference)
                        
                        UIView.performWithoutAnimation {
                            // Update the scene size
                            windowScene.requestGeometryUpdate(.Vision(size: size))
                        }
                    }
                }
                .frame(depth: 2)
            } else {
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
            }
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.4, green: 0.4, blue: 0.4))
                            Label("Details.arts.dismiss", systemImage: "xmark")
                        }
                    }
                    .frame(width: 30, height: 30)
                    Spacer()
                    Menu {
                        Section {
                            Button("Image.save.photos", systemImage: "photo.badge.plus") {
                                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            }
                            Button("Image.copy.image", systemImage: "doc.on.doc") {
                                UIPasteboard.general.image = image
                            }
                            Button("Image.copy.subject", systemImage: "circle.dashed.rectangle") {
                                Task {
                                    if let _data = image.pngData(), let result = await getImageSubject(_data) {
                                        UIPasteboard.general.image = .init(data: result)
                                    }
                                }
                            }
                        }
                        Section {
                            Button("Details.arts.share", systemImage: "square.and.arrow.up") {
                                isShareViewPresented = true
                            }
                        }
                        if #available(visionOS 26.0, *) {
                            Section {
                                Button("Details.arts.create-spatial", systemImage: "spatial.capture") {
                                    Task {
                                        guard let spatial3DImage = spatial3DImage as? ImagePresentationComponent.Spatial3DImage else {
                                            return
                                        }
                                        guard var imagePresentationComponent = imageEntity.components[ImagePresentationComponent.self] else {
                                            return
                                        }
                                        // Set the desired viewing mode before generating so that it will trigger the
                                        // generation animation
                                        imagePresentationComponent.desiredViewingMode = .spatial3D
                                        imageEntity.components.set(imagePresentationComponent)
                                        try await spatial3DImage.generate()
                                        
                                        if let aspectRatio = imagePresentationComponent.aspectRatio(for: .spatial3D) {
                                            imageAspectRatio = CGFloat(aspectRatio)
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.4, green: 0.4, blue: 0.4))
                            Label("Details.arts.actions", systemImage: "ellipsis")
                        }
                    }
                    .menuStyle(.button)
                    .frame(width: 30, height: 30)
                }
                .labelStyle(.iconOnly)
                .buttonBorderShape(.circle)
                Spacer()
                HStack {
                    VStack(alignment: .leading) {
                        Text(title)
                            .font(.headline)
                            .fontWeight(.semibold)
                        Text(subtitle)
                            .font(.subheadline)
                    }
                    Spacer()
                }
            }
            .padding(30)
            .frame(depth: 1)
        }
        .ignoresSafeArea()
        .sheet(isPresented: $isShareViewPresented) {
            _ImageShareView(image: image)
        }
        .aspectRatio(imageAspectRatio, contentMode: .fit)
        .onAppear {
            Task {
                guard #available(visionOS 26.0, *) else { return }
                if let data = image.pngData(),
                   let source = CGImageSourceCreateWithData(data as CFData, nil) {
                    do {
                        let image = try await ImagePresentationComponent.Spatial3DImage(
                            imageSource: source
                        )
                        let c = ImagePresentationComponent(spatial3DImage: image)
                        component = c
                        spatial3DImage = image
                    } catch {
                        print(error)
                    }
                }
            }
        }
        .preference(key: RemoveWindowBackgroundPreference.self, value: true)
    }
    
    private func scaleImagePresentationToFit(in boundsInMeters: BoundingBox) {
        guard #available(visionOS 26.0, *) else { return }
        guard let component = component as? ImagePresentationComponent else {
            return
        }

        let presentationScreenSize = component.presentationScreenSize
        let scale = min(
            boundsInMeters.extents.x / presentationScreenSize.x,
            boundsInMeters.extents.y / presentationScreenSize.y
        )

        imageEntity.scale = SIMD3<Float>(scale, scale, 1.0)
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

@available(visionOS 26.0, *)
extension ImagePresentationComponent.Spatial3DImage: @unchecked @retroactive Sendable {}
#else // os(iOS)
struct ImageLookView: View {
    var image: NSImage
    var title: String
    var body: some View {
        GeometryReader { geometry in
            _ZoomScrollView(viewSize: geometry.size) {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .antialiased(true)
                    .scaledToFit()
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
        }
        .navigationTitle(title)
    }
}

private struct _ZoomScrollView<Content: View>: NSViewRepresentable {
    var viewSize: CGSize
    var minimumZoomScale: CGFloat = 1
    var maximumZoomScale: CGFloat = 5
    var content: Content
    
    init(
        viewSize: CGSize,
        minimumZoomScale: CGFloat = 1,
        maximumZoomScale: CGFloat = 5,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.viewSize = viewSize
        self.minimumZoomScale = minimumZoomScale
        self.maximumZoomScale = maximumZoomScale
        self.content = content()
    }
    
    let scrollView = NSScrollView()
    
    func makeNSView(context: Context) -> NSScrollView {
        let hostingController = NSHostingController(rootView: content)
        let hostingView = hostingController.view
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = NSColor.clear.cgColor
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        context.coordinator.hostingController = hostingController
        
        let containerView = NSView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.wantsLayer = true
        containerView.layer?.backgroundColor = NSColor.clear.cgColor
        containerView.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: containerView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            containerView.widthAnchor.constraint(equalToConstant: viewSize.width),
            containerView.heightAnchor.constraint(equalToConstant: viewSize.height)
        ])
        scrollView.documentView = containerView
        
        scrollView.backgroundColor = .clear
        scrollView.drawsBackground = false
        scrollView.minMagnification = minimumZoomScale
        scrollView.maxMagnification = maximumZoomScale
        scrollView.allowsMagnification = true
        
        return scrollView
    }
    func updateNSView(_ uiView: NSViewType, context: Context) {
        if let hostingController = context.coordinator.hostingController {
            hostingController.rootView = content
        }
        
        if let documentView = scrollView.documentView {
            NSLayoutConstraint.deactivate(documentView.constraints)
            NSLayoutConstraint.activate([
                documentView.widthAnchor.constraint(equalToConstant: viewSize.width),
                documentView.heightAnchor.constraint(equalToConstant: viewSize.height)
            ])
        }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var hostingController: NSHostingController<Content>?
    }
}
#endif // os(iOS)
