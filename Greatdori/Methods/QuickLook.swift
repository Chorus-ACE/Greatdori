//===---*- Greatdori! -*---------------------------------------------------===//
//
// QuickLook.swift
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
import QuickLook
#if os(macOS)
import QuickLookUI
#endif

#if os(iOS)
struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    class Coordinator: NSObject, QLPreviewControllerDataSource {
        let url: URL
        init(url: URL) { self.url = url }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}
#else
class PreviewController: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    var fileURLs: [URL] = []
    
    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        fileURLs.count
    }
    
    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem {
        fileURLs[index] as QLPreviewItem
    }
    
    func showPanel(startingAt index: Int? = nil) {
        if let panel = QLPreviewPanel.shared() {
            panel.dataSource = self
            panel.delegate = self
            panel.reloadData()
            if let index, !fileURLs.isEmpty {
                let clamped = max(0, min(index, fileURLs.count - 1))
                panel.currentPreviewItemIndex = clamped
            }
            panel.makeKeyAndOrderFront(nil)
        }
    }
}
#endif

