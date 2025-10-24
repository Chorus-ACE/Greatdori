//===---*- Greatdori! -*---------------------------------------------------===//
//
// Network.swift
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

import Network
import Foundation

final class NetworkMonitor: Sendable {
    @MainActor static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @MainActor private var currentPath: NWPath?
    
    @MainActor var isConnected: Bool {
        currentPath?.status == .satisfied
    }
    @MainActor var connectionType: NWInterface.InterfaceType? {
        if let path = currentPath {
            if path.usesInterfaceType(.wifi) {
                .wifi
            } else if path.usesInterfaceType(.cellular) {
                .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                .wiredEthernet
            } else {
                nil
            }
        } else {
            nil
        }
    }
    @MainActor var preferConstrained: Bool {
        if let path = currentPath {
            connectionType == .cellular || path.isExpensive || path.isConstrained
        } else {
            false
        }
    }
    
    private init() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.currentPath = path
            }
        }
        monitor.start(queue: queue)
    }
}
