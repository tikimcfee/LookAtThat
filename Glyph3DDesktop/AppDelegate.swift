//
//  AppDelegate.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 9/11/20.
//

import Cocoa
import SwiftUI
import SwiftGlyph

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    static var shared: AppDelegate {
        return NSApp.delegate as! AppDelegate
    }
    
    var willTerminate = false
    
    override init() {
        super.init()
    }
    
    var window: NSWindow?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        let rootWindow = makeRootWindow()
        GlobalWindowDelegate.instance.registerRootWindow(rootWindow)
        rootWindow.contentView = makeRootContentView()
        rootWindow.makeKeyAndOrderFront(nil)
        window = rootWindow
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
        GlobalWindowDelegate.instance.isTerminating = true
    }
    
    func testingCherrierView() -> Bool {
        CommandLine.arguments.contains("cherrier-test")
    }
}

extension AppDelegate {
    func makeRootContentView() -> NSView {
        let rootDemoView = SwiftGlyphDemoView()
        return NSHostingView(rootView: rootDemoView)
    }
    
    func makeRootWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1440, height: 1024),
            styleMask: [.titled, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false
        )
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("Main Window")
        return window
    }
}
