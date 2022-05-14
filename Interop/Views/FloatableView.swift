//
//  FloatableView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/14/22.
//

import SwiftUI

enum GlobalWindowKey: String, Identifiable, Hashable {
    case twoDimensionalEditor = "2D Editor"
    case fileBrowser = "File Browser"
    var id: String { rawValue }
    var title: String { rawValue }
}

class FloatableViewState: ObservableObject {
    enum Mode {
        case displayedAsWindow
        case displayedAsSibling
    }
    @Published var currentMode: Mode = .displayedAsSibling
    func dismissWindow(for key: GlobalWindowKey) {
        GlobablWindowDelegate.instance.dismissWindow(for: key)
    }
}

struct FloatableView<Inner: View>: View {
    @StateObject var state = FloatableViewState()
    
    let windowKey: GlobalWindowKey
    let resizableAsSibling: Bool
    let innerViewBuilder: () -> Inner
    
    init(
        windowKey: GlobalWindowKey,
        resizableAsSibling: Bool,
        @ViewBuilder innerViewBuilder: @escaping () -> Inner
    ) {
        self.windowKey = windowKey
        self.resizableAsSibling = resizableAsSibling
        self.innerViewBuilder = innerViewBuilder
        
    }
    
    var body: some View {
        switch state.currentMode {
        case .displayedAsSibling:
            VStack(alignment: .trailing) {
                switchModeButton()
                if resizableAsSibling {
                    innerViewBuilder().modifier(DragSizableModifer())
                } else {
                    innerViewBuilder()
                }
            }
        case .displayedAsWindow:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func switchModeButton() -> some View {
        switch state.currentMode {
        case .displayedAsSibling:
            Button("Make window", action: {
                state.currentMode = .displayedAsWindow
                displayNewBuilderInstance()
            })
        case .displayedAsWindow:
            Button("Dock view", action: {
                state.currentMode = .displayedAsSibling
                state.dismissWindow(for: windowKey)
            })
        }
    }
    
    func displayNewBuilderInstance() {
        VStack(alignment: .trailing) {
            switchModeButton()
            innerViewBuilder()
        }.openInWindow(key: windowKey, sender: self)
    }
}

// TODO: This should be somewhere inside the app delegate state window state,
// or better yet just use the WindowGroup API..
// but that thing looks incredibly dense for what I need right now,
// which is just a window that pops up and can move and stuff.
private class GlobablWindowDelegate: NSObject, NSWindowDelegate {
    static let instance = GlobablWindowDelegate()
    
    private var knownWindowMap = BiMap<GlobalWindowKey, NSWindow>()
    
    override private init() {
        super.init()
    }
    
    func window(for key: GlobalWindowKey, _ makeWindow: () -> NSWindow) -> NSWindow {
        knownWindowMap[key] ?? {
            let newWindow = makeWindow()
            register(key, newWindow)
            return newWindow
        }()
    }
    
    private func register(_ key: GlobalWindowKey, _ window: NSWindow) {
        knownWindowMap[key] = window
        window.delegate = self
    }
    
    func dismissWindow(for key: GlobalWindowKey) {
        knownWindowMap[key]?.close()
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

extension View {
    
    @discardableResult
    func openInWindow(key: GlobalWindowKey, sender: Any?) -> NSWindow {
        let window = GlobablWindowDelegate.instance.window(
            for: key, { makeNewWindow(for: key) }
        )
        window.contentView = NSHostingView(rootView: self)
        window.makeKeyAndOrderFront(sender)
        return window
    }

    private func makeNewWindow(for key: GlobalWindowKey) -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 600),
            styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = key.title
        
        // THIS IS CRITICAL!
        // The window lifecycle is fragile here, and the window
        // can and will crash if it is immediately released on close.
        // Allow it to stick around long enough for the willClose notification
        // to come around and then clear the store then.
        window.isReleasedWhenClosed = false
        
        return window
    }
}
