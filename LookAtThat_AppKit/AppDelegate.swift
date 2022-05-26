//
//  AppDelegate.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/11/20.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
//        __ENABLE_STARTUP_LOG_WRITES__()
        
        let contentView = MacAppRootView()
            .environmentObject(MultipeerConnectionManager.shared)
            .environmentObject(TapObserving.shared)
            .onAppear { self.onRootViewAppeared() }
            .onDisappear { self.onRootViewDisappeared() }
        
        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1440, height: 1024),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
}

extension AppDelegate {
    func __ENABLE_STARTUP_LOG_WRITES__() {
        print("\n\n\t\t!!!! Tracing is enabled !!!!\n\n\t\tPrepare your cycles!\n\n")
        TracingRoot.shared.setupTracing()
    }
    
    private func onRootViewAppeared() {
        // Set initial state on appearance
        CodePagesController.shared.fileBrowser.loadRootScopeFromDefaults()
    }
    
    private func onRootViewDisappeared() {
        URL.dumpAndDescopeAllKnownBookmarks()
    }
}
