//===---*- Greatdori! -*---------------------------------------------------===//
//
// GreatdoriApp.swift
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

import Combine
import DoriKit
import SDWebImage
import SDWebImageSVGCoder
import SwiftUI
import UserNotifications
@_spi(Advanced) import SwiftUIIntrospect
#if os(iOS)
import UIKit
import BackgroundTasks
#else
import AppKit
#endif


// MARK: System Orientation
#if os(macOS)
let isMACOS = true
#else
let isMACOS = false
#endif

#if APP_STORE
let isComplyingWithAppStore = true
#else
let isComplyingWithAppStore = false
#endif

// MARK: GreatdoriApp (@main)
@main
struct GreatdoriApp: App {
    init() {
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    #if os(macOS)
    @NSApplicationDelegateAdaptor var appDelegate: AppDelegate
    #else
    @UIApplicationDelegateAdaptor var appDelegate: AppDelegate
    #endif
    @Environment(\.openWindow) var openWindow
    @Environment(\.scenePhase) var scenePhase
    @AppStorage("EnableRulerOverlay") var enableRulerOverlay = false
    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                if enableRulerOverlay {
                    DebugRulerOverlay()
                }
            }
            .onOpenURL { url in
                _handleURL(url)
            }
        }
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button(action: {
                    openWindow(id: "Secchi")
                }, label: {
                    Label("Settings.prompt", systemImage: "gear")
                })
                .keyboardShortcut(",", modifiers: .command)
            }
//            CommandGroup(after: .newItem) {
//                Button(action: {
////                    openWindow(id: "New")
//                    // TODO: Create Zeile Project
//                }, label: {
//                    Label("Zeile.menu-bar.new", systemImage: "plus")
//                })
//                .keyboardShortcut("N", modifiers: .command)
//            }
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .background:
                break
            case .inactive:
                break
            case .active:
                #if os(iOS)
                UNUserNotificationCenter.current().setBadgeCount(0)
                UIApplication.shared.registerForRemoteNotifications()
                #else
                NSApplication.shared.registerForRemoteNotifications()
                #endif
            @unknown default: break
            }
        }
        
        #if os(macOS)
        Window("Settings", id: "Secchi") {
            SettingsView()
        }
        #endif
        
        DocumentGroup {
            ZeileProjectDocument(emptyWithName: "Untitled.zeileproj")
        } editor: { config in
            ZeileEditorMainView(document: config.document)
        }
        .commands {
            ZeileEditorCommands()
        }
        
        WindowGroup("Window.zeile-story-viewer", id: "ZeileStoryViewer", for: ZeileStoryViewerWindowData.self) { $data in
            ZeileStoryViewerView(data: data)
        }
        .commandsRemoved()
        .handlesExternalEvents(matching: [".zir", ".sar"])
        
        WindowGroup("Window", id: "AnyWindow", for: AnyWindowData.self) { $data in
            if let data, data.isValid {
                _AnyWindowView(data: data)
            }
        }
        .commandsRemoved()
    }
}
private struct _AnyWindowView: View {
    var data: AnyWindowData
    @Environment(\.dismissWindow) private var dismissWindow
    @State private var dismissTimer: Timer?
    var body: some View {
        unsafe UnsafePointer<() -> AnyView>(bitPattern: data.content)!.pointee()
            .onAppear {
                dismissTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                    if unsafe !UnsafePointer<Binding<Bool>>(bitPattern: data.isPresented)!.pointee.wrappedValue {
                        dismissWindow()
                        dismissTimer?.invalidate()
                    }
                }
            }
            .onDisappear {
                dismissTimer?.invalidate()
                unsafe UnsafePointer<Binding<Bool>>(bitPattern: data.isPresented)!.pointee.wrappedValue = false
                if let ptrOnDismiss = unsafe data.onDismiss {
                    unsafe UnsafePointer<() -> Void>(bitPattern: ptrOnDismiss)!.pointee()
                }
            }
        #if os(macOS)
            .introspect(.window, on: .macOS(.v14...)) { window in
                window.isRestorable = false
            }
        #endif
    }
}

//MARK: AppDelegate
#if os(macOS)
class AppDelegate: NSObject, NSApplicationDelegate {
    @Environment(\.locale) var locale
    @AppStorage("IsFirstLaunch") var isFirstLaunch = true
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        SDImageCodersManager.shared.addCoder(SDImageSVGCoder.shared)
        
//        if isFirstLaunch {
//            DoriAPI.preferredLocale = switch locale.language {
//            case let x where x.hasCommonParent(with: .init(identifier: "ja-JP")): .jp
//            case let x where x.hasCommonParent(with: .init(identifier: "en-US")): .en
//            case let x where x.isEquivalent(to: .init(identifier: "zh-TW")): .tw
//            case let x where x.hasCommonParent(with: .init(identifier: "zh-CN")): .cn
//            case let x where x.hasCommonParent(with: .init(identifier: "ko-KO")): .kr
//            default: .jp
//            }
//            isFirstLaunch = false
//        }
        
        // Don't say lazy
        _ = NetworkMonitor.shared
        
        initializeISV_ABTest()
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        if let url = urls.first {
            _handleURL(url)
        }
    }
    
    func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UserDefaults.standard.set(deviceToken, forKey: "RemoteNotifDeviceToken")
    }
}
#else
class AppDelegate: NSObject, UIApplicationDelegate {
    @Environment(\.locale) var locale
    @AppStorage("IsFirstLaunch") var isFirstLaunch = true
    
    static var orientationLock = UIInterfaceOrientationMask.portrait
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        SDImageCodersManager.shared.addCoder(SDImageSVGCoder.shared)
        
//        if isFirstLaunch {
//            DoriAPI.preferredLocale = switch locale.language {
//            case let x where x.hasCommonParent(with: .init(identifier: "ja-JP")): .jp
//            case let x where x.hasCommonParent(with: .init(identifier: "en-US")): .en
//            case let x where x.isEquivalent(to: .init(identifier: "zh-TW")): .tw
//            case let x where x.hasCommonParent(with: .init(identifier: "zh-CN")): .cn
//            case let x where x.hasCommonParent(with: .init(identifier: "ko-KO")): .kr
//            default: .jp
//            }
//            isFirstLaunch = false
//        }
        
        // Don't say lazy
        _ = NetworkMonitor.shared
        
        initializeISV_ABTest()
        
        return true
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        _handleURL(url)
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        UserDefaults.standard.set(deviceToken, forKey: "RemoteNotifDeviceToken")
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}
#endif

@MainActor let _showRootViewSubject = PassthroughSubject<AnyView, Never>()
func rootShowView(@ViewBuilder content: () -> some View) {
    let view = AnyView(content())
    DispatchQueue.main.async {
        _showRootViewSubject.send(view)
    }
}
extension View {
    func handlesExternalView() -> some View {
        modifier(_ExternalViewHandlerModifier())
    }
}
private struct _ExternalViewHandlerModifier: ViewModifier {
    @State private var presentingView: AnyView?
    @State private var isViewPresented = false
    @State private var isVisible = false
    func body(content: Content) -> some View {
        content
            .navigationDestination(isPresented: $isViewPresented) {
                presentingView
            }
            .onAppear {
                isVisible = true
            }
            .onDisappear {
                isVisible = false
            }
            .onReceive(_showRootViewSubject) { view in
                if isVisible {
                    presentingView = view
                    isViewPresented = true
                }
            }
    }
}

private func initializeISV_ABTest() {
    if UserDefaults.standard.integer(forKey: "ISVStyleTestFlag") == 0 {
        let flag = Bool.random()
        UserDefaults.standard.set(flag ? 1 : 2, forKey: "ISVStyleTestFlag")
        UserDefaults.standard.set(flag, forKey: "ISVAlwaysFullScreen")
    }
    if !UserDefaults.standard.bool(forKey: "ISVTestInitialSubmit") {
        Task {
            let flag = UserDefaults.standard.integer(forKey: "ISVStyleTestFlag")
            let key = flag == 1 ? "ISVPreferAlwaysFullScreen" : "ISVPreferPreviewable"
            if await submitStats(key: key, action: true /* +1 */) {
                UserDefaults.standard.set(true, forKey: "ISVTestInitialSubmit")
            }
        }
    }
}

@MainActor
class NotificationDelegate: NSObject, @MainActor UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
