//
//  GlobalWindowDelegate.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/14/22.
//

import SwiftUI

// TODO: just use the WindowGroup API..
class GlobablWindowDelegate: NSObject, NSWindowDelegate {
    static let instance = GlobablWindowDelegate()
    
    private var knownWindowMap = BiMap<GlobalWindowKey, NSWindow>()
    private var rootWindow: NSWindow?
    
    override private init() {
        super.init()
    }
    
    func registerRootWindow(_ window: NSWindow) {
        self.rootWindow = window
    }
    
    func windowIsDisplayed(for key: GlobalWindowKey) -> Bool {
        knownWindowMap[key]?.isVisible == true
    }
    
    func window(
        for key: GlobalWindowKey,
        _ makeWindow: @autoclosure () -> NSWindow) -> NSWindow {
        knownWindowMap[key] ?? {
            let newWindow = makeWindow()
            register(key, newWindow)
            return newWindow
        }()
    }
    
    func dismissWindow(for key: GlobalWindowKey) {
        knownWindowMap[key]?.close()
    }
    
    private func register(_ key: GlobalWindowKey, _ window: NSWindow) {
        knownWindowMap[key] = window
        rootWindow?.addChildWindow(window, ordered: .above)
        window.delegate = self
    }
    
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else {
            print("Missing window on close!", notification)
            return
        }
        print("Window closing:", knownWindowMap[window]?.rawValue ?? "<No known key!>", "->", window.title)
        knownWindowMap[window] = nil
    }
}
