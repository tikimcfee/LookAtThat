//
//  AppDelegate.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/11/20.
//

import Cocoa
import SwiftUI
import SwiftGlyphs

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
//        __ENABLE_TRACE_LOG_WRITES__()
        
        let rootWindow = makeRootWindow()
        GlobablWindowDelegate.instance.registerRootWindow(rootWindow)
        rootWindow.contentView = makeRootContentView()
        rootWindow.makeKeyAndOrderFront(nil)
        window = rootWindow
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    func testingCherrierView() -> Bool {
        CommandLine.arguments.contains("cherrier-test")
    }
}

extension AppDelegate {
    func makeRootContentView() -> NSView {
        let contentView = MacAppRootView()
            .environmentObject(MultipeerConnectionManager.shared)
            .onAppear { self.onRootViewAppeared() }
            .onDisappear { self.onRootViewDisappeared() }
        
        return NSHostingView(rootView: contentView)
    }
    
    func makeRootWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1440, height: 1024),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("Main Window")
        return window
    }
}

extension AppDelegate {
    func __ENABLE_TRACE_LOG_WRITES__() {
        fatalError("YOU SHALL NOT TRACE")
    }
    
    private func onRootViewAppeared() {
        // Set initial state on appearance
        GlobalInstances.fileBrowser.loadRootScopeFromDefaults()
        GlobalInstances.gridStore.gridInteractionState.setupStreams()
        GlobalInstances.defaultRenderer.renderDelegate = GlobalInstances.swiftGlyphsRoot
    }
    
    private func onRootViewDisappeared() {
        URL.dumpAndDescopeAllKnownBookmarks()
    }
}
