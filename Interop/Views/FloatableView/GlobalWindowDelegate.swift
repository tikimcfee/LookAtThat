//
//  GlobalWindowDelegate.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/14/22.
//

import SwiftUI

// TODO: just use the WindowGroup API..

enum GlobalWindowKey: String, Identifiable, Hashable {
    case twoDimensionalEditor = "2D Editor"
    case fileBrowser = "File Browser"
    case viewPanels = "View Panels"
    var id: String { rawValue }
    var title: String { rawValue }
}

class GlobablWindowDelegate: NSObject, NSWindowDelegate {
    static let instance = GlobablWindowDelegate()
    
    private var knownWindowMap = BiMap<GlobalWindowKey, NSWindow>()
    
    override private init() {
        super.init()
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
