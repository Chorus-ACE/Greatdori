//===---*- Greatdori! -*---------------------------------------------------===//
//
// Extensions.swift
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

// (In Alphabetical Order)

import Vision
import System
import DoriKit
import Network
import SwiftUI
import BackgroundAssets
import SDWebImageSwiftUI
import UniformTypeIdentifiers
import CoreImage.CIFilterBuiltins

// MARK: Array
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: Color
extension Color {
    func toHex() -> String? {
#if os(macOS)
        let nativeColor = NSColor(self).usingColorSpace(.deviceRGB)
        guard let color = nativeColor else { return nil }
#else
        let color = UIColor(self)
#endif
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
#if os(macOS)
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
#else
        guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
#endif
        
        return String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(red * 255)),
            lroundf(Float(green * 255)),
            lroundf(Float(blue * 255))
        )
    }
    
    func hue(factor: CGFloat) -> Color {
        return modifyHSB { (h, s, b, a) in
            let newHue = (h * factor).truncatingRemainder(dividingBy: 1.0)
            return (newHue, s, b, a)
        }
    }
    
    func saturation(factor: CGFloat) -> Color {
        return modifyHSB { (h, s, b, a) in
            (h, min(max(s * factor, 0), 1), b, a)
        }
    }
    
    func brightness(factor: CGFloat) -> Color {
        return modifyHSB { (h, s, b, a) in
            (h, s, min(max(b * factor, 0), 1), a)
        }
    }
    
    private func modifyHSB(_ transform: (CGFloat, CGFloat, CGFloat, CGFloat) -> (CGFloat, CGFloat, CGFloat, CGFloat)) -> Color {
#if canImport(UIKit)
        let uiColor = UIColor(self)
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let (newH, newS, newB, newA) = transform(h, s, b, a)
        return Color(UIColor(hue: newH, saturation: newS, brightness: newB, alpha: newA))
#elseif canImport(AppKit)
        let nsColor = NSColor(self).usingColorSpace(.deviceRGB) ?? .black
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        nsColor.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        let (newH, newS, newB, newA) = transform(h, s, b, a)
        return Color(NSColor(hue: newH, saturation: newS, brightness: newB, alpha: newA))
#else
        return self
#endif
    }
    
}

// MARK: Date
extension Date {
    public func corrected() -> Date? {
        if self.timeIntervalSince1970 >= 3786879600 {
            return nil
        } else {
            return self
        }
    }
}

extension DoriAPI.LocalizedData<Set<DoriFrontend.Card.ExtendedCard.Source>> {
    public enum CardSource {
        case event, gacha, loginCampaign
    }
    
    public func containsSource(from source: CardSource) -> Bool {
        for locale in DoriLocale.allCases {
            for item in Array(self.forLocale(locale) ?? Set()) {
                switch item {
                case .event:
                    if source == .event { return true }
                case .gacha:
                    if source == .gacha { return true }
                case .login:
                    if source == .loginCampaign { return true }
                default: continue
                }
            }
        }
        return false
    }
}


// MARK: Int
extension Int?: @retroactive Identifiable {
    public var id: Int? { self }
}


// MARK: LocalizedStringResource
extension LocalizedStringResource: Hashable {
    public static func == (lhs: LocalizedStringResource, rhs: LocalizedStringResource) -> Bool {
        lhs.key == rhs.key && lhs.table == rhs.table
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(key)
        hasher.combine(table)
    }
}


// MARK: Optional
extension Optional {
    var id: Self { self }
}

// MARK: View
public extension View {
    @ViewBuilder
    func hidden(_ isHidden: Bool = true) -> some View {
        if isHidden {
            self.hidden()
        } else {
            self
        }
    }
    
    // MARK: inverseMask
    public func inverseMask<Mask: View>(
        @ViewBuilder _ mask: () -> Mask,
        alignment: Alignment = .center
    ) -> some View {
        self.mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    mask().blendMode(.destinationOut)
                }
        }
    }
    
    // MARK: onFrameChange
    /// Performs action when frame of attached view changes.
    ///
    /// ```swift
    /// struct MyView: View {
    ///     var body: some View {
    ///         MyView()
    ///             .onFrameChange { geometry in
    ///                 print(geometry)
    ///             }
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter action: The action to perform.
    /// - Returns: A view that triggers `action` when its frame changes.
    func onFrameChange(perform action: @escaping (_ geometry: GeometryProxy) -> Void) -> some View {
        background(
            GeometryReader { geometry in
                Color.clear
                    .onAppear {
                        action(geometry)
                    }
                    .onChange(of: geometry.size) {
                        action(geometry)
                    }
            }
        )
    }
    
    // MARK: withSystemBackground
    @ViewBuilder
    func withSystemBackground() -> some View {
#if os(iOS)
        self
            .background(Color(.systemGroupedBackground))
#else
        self
#endif
    }
    
    // MARK: wrapIf
    /// Wraps a view into a specific container when `condition` is `true`.
    ///
    /// Use this modifier to conditionally wrap a view into a container.
    /// ```swift
    /// struct MyView: View {
    ///     @State private var navigatable = false
    ///     var body: some View {
    ///         List {
    ///             Button("Switch Navigatability") {
    ///                 navigatable.toggle()
    ///             }
    ///             NavigationLink("Navigate", destination: { /* some view... */ })
    ///         }
    ///         .wrapIf(navigatable) { content in
    ///             NavigationStack { content }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Note: When the condition changes, SwiftUI redraws the whole contained view.
    ///
    /// - Parameters:
    ///   - condition: Whether to wrap the view into the specific container.
    ///   - container: Wrapping container which makes sence when `condition` is `true`.
    /// - Returns: A view that wrapped into the specific container when `condition` is `true`.
    @ViewBuilder
    func wrapIf(_ condition: Bool, @ViewBuilder in container: (Self) -> some View) -> some View {
        if condition {
            container(self)
        } else {
            self
        }
    }
    
    /// Wraps a view into a specific container when `condition` is `true`,
    /// and wraps it into the other container when `condition` is `false`.
    ///
    /// ```swift
    /// struct MyView: View {
    ///     @State private var appearance = false
    ///     var body: some View {
    ///         Button("Switch Appearance") {
    ///             appearance.toggle()
    ///         }
    ///         .wrapIf(appearance) { content in
    ///             VStack { content }
    ///         } else: { content in
    ///             List { content }
    ///         }
    ///     }
    /// }
    /// ```
    ///
    /// - Note: When the condition changes, SwiftUI redraws the whole contained view.
    ///
    /// - Parameters:
    ///   - condition: Whether to wrap the view into the `true` container or the `false` container.
    ///   - container: Wrapping container which makes sence when `condition` is `true`.
    ///   - elseContainer: Wrapping container which makes sence when `condition` is `false`.
    /// - Returns: A view that wrapped into the `true` container when `condition` is `true`, vice versa.
    @ViewBuilder
    func wrapIf(_ condition: Bool, @ViewBuilder in container: (Self) -> some View, @ViewBuilder else elseContainer: (Self) -> some View) -> some View {
        if condition {
            container(self)
        } else {
            elseContainer(self)
        }
    }
}

// MARK: NetworkMonitor
final class NetworkMonitor: Sendable {
    @MainActor static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @MainActor private(set) var isConnected: Bool = false
    @MainActor private(set) var connectionType: NWInterface.InterfaceType?
    
    private init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
                
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .wiredEthernet
                } else {
                    self.connectionType = nil
                }
            }
        }
        monitor.start(queue: queue)
    }
}

struct EmptyContainer<Content: View>: View {
    var content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }
    
    var body: some View {
        content()
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

extension MutableCollection {
    @_transparent
    func swappedAt(_ i: Self.Index, _ j: Self.Index) -> Self {
        var copy = self
        copy.swapAt(i, j)
        return copy
    }
}

extension View {
    func scrollDisablesMultilingualTextPopover(_ isEnabled: Bool = true) -> some View {
        ModifiedContent(content: self, modifier: ScrollDisableMultilingualTextPopoverModifier(isEnabled: isEnabled))
    }
}
private struct ScrollDisableMultilingualTextPopoverModifier: ViewModifier {
    var isEnabled: Bool
    @State private var disablesPopover = false
    func body(content: Content) -> some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            content
                .environment(\._multilingualTextDisablePopover, disablesPopover)
                .onScrollPhaseChange { _, newPhase in
                    disablesPopover = newPhase != .idle
                }
        } else {
            content
        }
    }
}
extension EnvironmentValues {
    @Entry var _multilingualTextDisablePopover: Bool = false
}

extension WebImage {
    func imageContextMenu<V: View>(
        url: URL,
        description: LocalizedStringResource? = nil,
        otherContentAt placement: _ImageContextMenuModifier<V>.ContentPlacement = .start,
        @ViewBuilder otherContent: @escaping () -> V = { EmptyView() }
    ) -> some View {
        _WebImageContentMenuWrapperView(
            content: self,
            url: url,
            description: description,
            otherContentPlacement: placement,
            otherContent: otherContent
        )
    }
    
    private struct _WebImageContentMenuWrapperView<V: View>: View {
        var content: WebImage
        var url: URL
        var description: LocalizedStringResource?
        var otherContentPlacement: _ImageContextMenuModifier<V>.ContentPlacement
        var otherContent: (() -> V)?
        @State private var info: _ImageContextMenuModifier<V>.ImageInfo?
        var body: some View {
            content
                .onSuccess { _, data, _ in
                    info = .init(url: url, data: data, description: description)
                }
                .modifier(
                    _ImageContextMenuModifier(
                        imageInfo: info != nil ? [info!] : [],
                        otherContentPlacement: otherContentPlacement,
                        otherContent: otherContent
                    )
                )
        }
    }
}
extension View {
    func imageContextMenu<V: View>(
        _ info: [_ImageContextMenuModifier<V>.ImageInfo],
        otherContentAt placement: _ImageContextMenuModifier<V>.ContentPlacement = .start,
        @ViewBuilder otherContent: @escaping () -> V = { EmptyView() }
    ) -> some View {
        self
            .modifier(_ImageContextMenuModifier(imageInfo: info, otherContentPlacement: placement, otherContent: otherContent))
    }
}
struct _ImageContextMenuModifier<V: View>: ViewModifier {
    @State var imageInfo: [ImageInfo]
    var otherContentPlacement: ContentPlacement
    var otherContent: (() -> V)?
    @State private var isFileExporterPresented = false
    @State private var exportingImageDocument: _ImageFileDocument?
    func body(content: Content) -> some View {
        content
            .contextMenu {
                if otherContentPlacement == .start, let otherContent {
                    otherContent()
                }
                Section {
                    #if os(macOS)
                    forEachImageInfo("Image.save.download", systemImage: "square.and.arrow.down") { info in
                        Task {
                            guard let downloadsFolder = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first else { return }
                            try? await info.resolvedData()?.write(to: downloadsFolder.appending(path: info.url.lastPathComponent))
                        }
                    }
                    forEachImageInfo("Image.save.as", systemImage: "square.and.arrow.down") { info in
                        Task {
                            if let data = await info.resolvedData() {
                                exportingImageDocument = .init(data: data)
                                isFileExporterPresented = true
                            }
                        }
                    }
                    #endif
                    #if os(iOS)
                    // FIXME: Unavailable in macOS...
                    forEachImageInfo("Image.save.photos", systemImage: "photo.badge.plus") { info in
                        Task {
                            if let data = await info.resolvedData(), let image = UIImage(data: data) {
                                UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                            }
                        }
                    }
                    #endif
                }
                Section {
                    forEachImageInfo("Image.copy.link", systemImage: "document.on.document") { info in
                        #if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(info.url.absoluteString, forType: .string)
                        #else
                        UIPasteboard.general.string = info.url.absoluteString
                        #endif
                    }
                    forEachImageInfo("Image.copy.image", systemImage: "document.on.document") { info in
                        Task {
                            if let data = await info.resolvedData() {
                                #if os(macOS)
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setData(data, forType: .png)
                                #else
                                UIPasteboard.general.image = .init(data: data)!
                                #endif
                            }
                        }
                    }
                    if #available(iOS 18.0, macOS 15.0, *) {
                        forEachImageInfo("Image.copy.subject", systemImage: "circle.dashed.rectangle") { info in
                            DispatchQueue(label: "com.memz233.Greatdori.Fetch-Trimmed-Image", qos: .userInitiated).async {
                                Task {
                                    var subjectImageData: Data? = nil
                                    var onlineImageFetchSucceeded = false
                                    if !UserDefaults.standard.bool(forKey: "preferSystemVisionModel") {
                                        subjectImageData = try? Data(contentsOf: URL(string: info.url.absoluteString.replacingOccurrences(of: "card", with: "trim"))!)
                                        onlineImageFetchSucceeded = subjectImageData != nil
                                    }
                                    
                                    if !onlineImageFetchSucceeded {
                                        if let data = await info.resolvedData() {
                                            subjectImageData = await getImageSubject(data)
                                        }
                                    }
                                    
                                    if let subjectImageData {
#if os(macOS)
                                        NSPasteboard.general.clearContents()
                                        NSPasteboard.general.setData(subjectImageData, forType: .png)
#else
                                        UIPasteboard.general.image = .init(data: subjectImageData)
#endif
                                    } else {
                                        print("Subject Fetch Failed")
                                    }
                                }
                            }
                        }
                    }
                }
                Section {
                    // Since `ShareLink` is not a button,
                    // we can't use `forEachImageInfo` here
                    if imageInfo.count > 1 {
                        Menu("Image.share", systemImage: "square.and.arrow.up") {
                            ForEach(imageInfo, id: \.self) { info in
                                ShareLink(info.description ?? "Image.image", item: info.url)
                            }
                        }
                    } else if let info = imageInfo.first {
                        ShareLink("Image.share", item: info.url)
                    }
                }
                if otherContentPlacement == .end, let otherContent {
                    otherContent()
                }
            }
            .fileExporter(isPresented: $isFileExporterPresented, document: exportingImageDocument, contentType: .image) { _ in
                exportingImageDocument = nil
            }
            .onAppear {
                for (index, info) in imageInfo.enumerated() where info.data == nil {
                    Task {
                        imageInfo[index].data = await info.resolvedData()
                    }
                }
            }
    }
    
    @ViewBuilder
    private func forEachImageInfo(
        _ titleKey: LocalizedStringResource,
        systemImage: String,
        action: @escaping (ImageInfo) -> Void
    ) -> some View {
        if imageInfo.count > 1 {
            Menu(titleKey, systemImage: systemImage) {
                ForEach(imageInfo, id: \.self) { info in
                    Button(info.description ?? "Image.image") {
                        action(info)
                    }
                }
            }
        } else if let info = imageInfo.first {
            Button(titleKey, systemImage: systemImage) {
                action(info)
            }
        }
    }
    
    enum ContentPlacement {
        case start
        case end
    }
    struct ImageInfo: Hashable, Sendable {
        var url: URL
        var data: Data?
        var description: LocalizedStringResource?
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(url)
            hasher.combine(data)
            if let description {
                hasher.combine(String(localized: description))
            }
        }
        
        func resolvedData() async -> Data? {
            if let data {
                return data
            }
            return await withCheckedContinuation { continuation in
                DispatchQueue(label: "com.memz233.Greatdori.Resolve-Image-From-URL", qos: .userInitiated).async {
                    let data = try? Data(contentsOf: url)
                    continuation.resume(returning: data)
                }
            }
        }
    }
}
struct _ImageFileDocument: FileDocument {
    static let readableContentTypes: [UTType] = [.image]
    
    var imageData: Data
    
    init(data imageData: Data) {
        self.imageData = imageData
    }
    init(configuration: ReadConfiguration) throws {
        if let data = configuration.file.regularFileContents {
            imageData = data
        } else {
            throw CocoaError(.fileReadUnknown)
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        .init(regularFileWithContents: imageData)
    }
}

extension View {
    func window<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        #if os(macOS)
        modifier(_AnyWindowModifier(isPresented: isPresented, onDismiss: onDismiss, content: content))
        #else
        sheet(isPresented: isPresented, onDismiss: onDismiss) {
            NavigationStack(root: content)
        }
        #endif
    }
}
private struct _AnyWindowModifier<V: View>: ViewModifier {
    var isPresented: Binding<Bool>
    var onDismiss: (() -> Void)?
    var content: () -> V
    @Environment(\.openWindow) private var openWindow
    func body(content body: Content) -> some View {
        body
            .onChange(of: isPresented.wrappedValue, initial: true) {
                if isPresented.wrappedValue {
                    let ptrIsPresented = UnsafeMutablePointer<Binding<Bool>>.allocate(capacity: 1)
                    unsafe ptrIsPresented.initialize(to: isPresented)
                    var ptrOnDismiss: UnsafeMutablePointer<() -> Void>?
                    if let onDismiss {
                        unsafe ptrOnDismiss = .allocate(capacity: 1)
                        unsafe ptrOnDismiss.unsafelyUnwrapped.initialize(to: onDismiss)
                    }
                    let ptrContent = UnsafeMutablePointer<() -> AnyView>.allocate(capacity: 1)
                    unsafe ptrContent.initialize {
                        AnyView(content())
                    }
                    unsafe openWindow(
                        id: "AnyWindow",
                        value: AnyWindowData(
                            isPresented: Int(bitPattern: ptrIsPresented),
                            content: Int(bitPattern: ptrContent),
                            onDismiss: ptrOnDismiss != nil ? Int(bitPattern: ptrOnDismiss.unsafelyUnwrapped) : nil
                        )
                    )
                }
            }
    }
}
struct AnyWindowData: Hashable, Codable {
    @unsafe var isPresented: Int // Binding<Bool>
    @unsafe var content: Int // () -> AnyView
    @unsafe var onDismiss: Int? // () -> Void
    
    var _hash: Int
    
    init(isPresented: Int, content: Int, onDismiss: Int? = nil) {
        unsafe self.isPresented = isPresented
        unsafe self.content = content
        unsafe self.onDismiss = onDismiss
        self._hash = isPresented.hashValue & content.hashValue
        if let h = onDismiss?.hashValue {
            _hash &= h
        }
    }
    
    var isValid: Bool {
        var h = unsafe isPresented.hashValue & content.hashValue
        if let _h = unsafe onDismiss?.hashValue {
            h &= _h
        }
        return h == _hash
    }
}

extension WebImage {
    func upscale<Result: View>(@ViewBuilder layout: @escaping (Image) -> Result) -> some View {
        _ImageUpscaleView(imageView: self, layout: layout)
    }
}
private struct _ImageUpscaleView<V: View, Result: View>: View {
    var imageView: WebImage<V>
    var layout: (Image) -> Result
    @AppStorage("UseImageUpscaler") private var useImageUpscaler = false
    @State private var sourceImage: Image?
    @State private var upscaledImage: Image?
    var body: some View {
        if let sourceImage, let upscaledImage {
            layout(upscaledImage)
                .visualEffect { content, geometry in
                    content
                        .colorEffect(ShaderLibrary.upscaledImageFix(.image(sourceImage), .boundingRect))
                }
        } else {
            imageView
                .onSuccess { image, data, _ in
                    if #available(iOS 26.0, macOS 26.0, *) {
                        guard useImageUpscaler else { return }
                        if ProcessInfo.processInfo.isLowPowerModeEnabled
                            || ProcessInfo.processInfo.thermalState.rawValue > 2 {
                            return
                        }
                        #if !os(macOS)
                        guard let data = data ?? image.pngData() else { return }
                        #else
                        guard let data = data ?? image.tiffRepresentation else { return }
                        #endif
                        DispatchQueue.main.async {
                            #if os(iOS)
                            sourceImage = .init(uiImage: image)
                            #else
                            sourceImage = .init(nsImage: image)
                            #endif
                        }
                        Task.detached {
                            do {
                                let assetPack = try await AssetPackManager.shared.assetPack(withID: "Upscaler-Model")
                                try await AssetPackManager.shared.ensureLocalAvailability(of: assetPack)
                                let packageURL = try AssetPackManager.shared.url(for: "Upscaler.mlpackage")
                                let _model: MLModel
                                if let compiledModel = UserDefaults.standard.url(forKey: "UpscalerCompiledModel"),
                                   FileManager.default.fileExists(atPath: compiledModel.path(percentEncoded: false)) {
                                    _model = try .init(contentsOf: compiledModel)
                                } else {
                                    let newURL = try await MLModel.compileModel(at: packageURL)
                                    UserDefaults.standard.set(newURL, forKey: "UpscalerCompiledModel")
                                    _model = try .init(contentsOf: newURL)
                                }
                                let model = try VNCoreMLModel(for: _model)
                                let request = VNCoreMLRequest(model: model)
                                request.imageCropAndScaleOption = .scaleFill
                                let handler = VNImageRequestHandler(data: data)
                                try handler.perform([request])
                                if let buffer = request.results?.compactMap({ $0 as? VNPixelBufferObservation }).first?.pixelBuffer {
                                    let image = CIImage(cvImageBuffer: buffer)
                                    let context = CIContext()
                                    guard let sourceImage = CIImage(data: data) else { return }
                                    guard let cgImage = context.createCGImage(image, from: image.extent) else { return }
                                    #if os(iOS)
                                    upscaledImage = .init(uiImage: .init(cgImage: cgImage))
                                    #else
                                    upscaledImage = .init(nsImage: .init(cgImage: cgImage, size: image.extent.size))
                                    #endif
                                }
                            } catch {
                                print(error)
                            }
                        }
                    }
                }
        }
    }
}
