//===---*- Greatdori! -*---------------------------------------------------===//
//
// ViewModifiers.swift
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

// MARK: [IMPORTANT] Only put modifiers in here if it's compilcated enough.
// MARK: If feature may have full function without additional structures, then it should go to `Extensions.swift`

import BackgroundAssets
import DoriKit
import SDWebImageSwiftUI
import SwiftUI
import System
import UniformTypeIdentifiers
import Vision

extension View {
    @ViewBuilder
    func withSystemBackground(isActive: Bool? = nil) -> some View {
        self.modifier(SystemBackgroundModifier(isActive: isActive))
    }
}
private struct SystemBackgroundModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    var isActive: Bool?
    func body(content: Content) -> some View {
        if isMACOS || !(isActive ?? ((UserDefaults.standard.value(forKey: "customGroupBoxVersion") as? Int) == 2)) {
            content
        } else {
            #if os(iOS)
            content
                .background(Color(.systemGroupedBackground))
            #endif
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
                            let destination = downloadsFolder.appending(path: info.url.lastPathComponent)
                            if (try? await info.resolvedData()?.write(to: destination)) != nil {
                                DistributedNotificationCenter.default.post(
                                    name: .init("com.apple.DownloadFileFinished"),
                                    object: destination.resolvingSymlinksInPath().path
                                )
                            }
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
                    forEachImageInfo("Image.copy.link", systemImage: "doc.on.doc") { info in
                        #if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(info.url.absoluteString, forType: .string)
                        #else
                        UIPasteboard.general.string = info.url.absoluteString
                        #endif
                    }
                    forEachImageInfo("Image.copy.image", systemImage: "doc.on.doc") { info in
                        Task {
                            if let data = await info.resolvedData() {
                                #if os(macOS)
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setData(data, forType: .png)
                                #else
                                UIPasteboard.general.image = .init(data: data)
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
                                    if !UserDefaults.standard.bool(forKey: "Adv_PreferSystemVisionModel") {
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
        #if !os(iOS)
        modifier(_AnyWindowModifier(isPresented: isPresented, onDismiss: onDismiss, content: content))
        #else
        sheet(isPresented: isPresented, onDismiss: onDismiss) {
            NavigationStack(root: content)
        }
        #endif
    }
    func window<Content: View, Item: Identifiable>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        #if !os(iOS)
        modifier(_AnyWindowModifier(isPresented: .init { item.wrappedValue != nil } set: { !$0 ? (item.wrappedValue = nil) : () }, onDismiss: onDismiss) {
            item.wrappedValue != nil ? content(item.wrappedValue!) : nil
        })
        #else
        sheet(item: item, onDismiss: onDismiss) { item in
            NavigationStack {
                content(item)
            }
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

#if os(visionOS)
extension View {
    func immersiveSpace<Content: View>(
        isPresented: Binding<Bool>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        modifier(_AnyImmersiveSpaceModifier(isPresented: isPresented, onDismiss: onDismiss, content: content))
    }
    func immersiveSpace<Content: View, Item: Identifiable>(
        item: Binding<Item?>,
        onDismiss: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (Item) -> Content
    ) -> some View {
        modifier(_AnyImmersiveSpaceModifier(isPresented: .init { item.wrappedValue != nil } set: { !$0 ? (item.wrappedValue = nil) : () }, onDismiss: onDismiss) {
            item.wrappedValue != nil ? content(item.wrappedValue!) : nil
        })
    }
}
private struct _AnyImmersiveSpaceModifier<V: View>: ViewModifier {
    var isPresented: Binding<Bool>
    var onDismiss: (() -> Void)?
    var content: () -> V
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
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
                    Task {
                        unsafe await openImmersiveSpace(
                            id: "AnyImmersiveSpace",
                            value: AnyImmersiveSpaceData(
                                isPresented: Int(bitPattern: ptrIsPresented),
                                content: Int(bitPattern: ptrContent),
                                onDismiss: ptrOnDismiss != nil ? Int(bitPattern: ptrOnDismiss.unsafelyUnwrapped) : nil
                            )
                        )
                    }
                }
            }
    }
}
struct AnyImmersiveSpaceData: Hashable, Codable {
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
#endif // os(visionOS)

extension WebImage {
    func upscale<Result: View>(@ViewBuilder layout: @escaping (Image) -> Result) -> some View {
        _ImageUpscaleView(imageView: self, layout: layout)
    }
}
private struct _ImageUpscaleView<V: View, Result: View>: View {
    var imageView: WebImage<V>
    var layout: (Image) -> Result
    @AppStorage("Adv_UseImageUpscaler") private var useImageUpscaler = false
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
                    if #available(iOS 26.0, macOS 26.0, visionOS 26.0, *) {
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
                            #if !os(macOS)
                            sourceImage = .init(uiImage: image)
                            #else
                            sourceImage = .init(nsImage: image)
                            #endif
                        }
                        Task.detached {
                            do {
                                let _model: MLModel
                                if let compiledModel = UserDefaults.standard.string(forKey: "UpscalerCompiledModel"),
                                   FileManager.default.fileExists(atPath: NSHomeDirectory() + "/tmp/\(compiledModel)") {
                                    _model = try .init(contentsOf: .init(filePath: NSHomeDirectory() + "/tmp/\(compiledModel)"))
                                } else {
                                    let packageURL: URL
                                    if let url = UserDefaults.standard.url(forKey: "UpscalerPackage"),
                                       FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) {
                                        packageURL = url
                                    } else {
                                        let assetPack = try await AssetPackManager.shared.assetPack(withID: "Upscaler-Model")
                                        try await AssetPackManager.shared.ensureLocalAvailability(of: assetPack)
                                        packageURL = try AssetPackManager.shared.url(for: "Upscaler.mlpackage")
                                    }
                                    let newURL = try await MLModel.compileModel(at: packageURL)
                                    UserDefaults.standard.set(newURL.lastPathComponent, forKey: "UpscalerCompiledModel")
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
                                    #if !os(macOS)
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

extension View {
    func scrollDisablesPopover(_ isEnabled: Bool = true) -> some View {
        ModifiedContent(content: self, modifier: ScrollDisablePopoverModifier(isEnabled: isEnabled))
    }
}
private struct ScrollDisablePopoverModifier: ViewModifier {
    var isEnabled: Bool
    @State private var disablesPopover = false
    func body(content: Content) -> some View {
        if #available(iOS 18.0, macOS 15.0, *) {
            content
                .environment(\.disablePopover, disablesPopover)
                .onScrollPhaseChange { _, newPhase in
                    if isEnabled {
                        disablesPopover = newPhase != .idle
                    }
                }
                .onChange(of: isEnabled) {
                    if !isEnabled {
                        disablesPopover = false
                    }
                }
        } else {
            content
        }
    }
}
extension EnvironmentValues {
    @Entry var disablePopover: Bool = false
}

extension View {
    func onActivationChange(
        eager: Bool = false,
        perform action: @escaping (_ isActive: Bool) -> Void
    ) -> some View {
        modifier(ActivationChangeModifier(eager: eager, action: action))
    }
}
private struct ActivationChangeModifier: ViewModifier {
    var eager: Bool
    var action: (Bool) -> Void
    @Environment(\.scenePhase) private var scenePhase
    #if os(macOS)
    @Environment(\.appearsActive) private var appearsActive
    #endif
    
    func body(content: Content) -> some View {
        content
            #if os(macOS)
            .onChange(of: appearsActive) {
                action(appearsActive)
            }
            #else
            .onChange(of: scenePhase) {
                if scenePhase == .active {
                    action(true)
                } else if scenePhase == (eager ? .inactive : .background) {
                    action(false)
                }
            }
            #endif
    }
}

extension View {
    func _variadic<V: View>(@ViewBuilder process: @escaping (_VariadicView.Children) -> V) -> some View {
        modifier(VariadicModifier(process: process))
    }
}
private struct VariadicModifier<V: View>: ViewModifier {
    var process: (_VariadicView.Children) -> V
    func body(content: Content) -> some View {
        _VariadicView.Tree(Root(process: process)) {
            content
        }
    }
    
    private struct Root<Result: View>: _VariadicView_MultiViewRoot {
        var process: (_VariadicView.Children) -> Result
        func body(children: _VariadicView.Children) -> some View {
            process(children)
        }
    }
}
