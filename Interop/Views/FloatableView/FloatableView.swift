//
//  FloatableView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/14/22.
//

import SwiftUI

struct FloatableView<Inner: View>: View {
    enum Mode {
        case displayedAsWindow
        case displayedAsSibling
    }
    
    @State var displayMode: FloatableView.Mode = .displayedAsSibling
    let windowKey: GlobalWindowKey
    var resizableAsSibling: Bool = false
    let innerViewBuilder: () -> Inner
    
    var body: some View {
        makePlatformBody()
    }
}

extension FloatableView {
    @ViewBuilder
    func makePlatformBody() -> some View {
    #if os(iOS)
        if resizableAsSibling {
            innerViewBuilder().modifier(DragSizableModifer())
        } else {
            innerViewBuilder()
        }
    #elseif os(macOS)
        switch displayMode {
        case .displayedAsSibling where resizableAsSibling:
            VStack(alignment: .trailing, spacing: 0) {
                switchModeButton()
                innerViewBuilder().modifier(DragSizableModifer())
            }
        case .displayedAsSibling:
            VStack(alignment: .trailing, spacing: 0) {
                switchModeButton()
                innerViewBuilder()
            }
        case .displayedAsWindow:
            Spacer()
                .onAppear { performUndock() }
                .onDisappear { performDock() }
        }
    #endif
    }
}

#if os(macOS)
private extension FloatableView {
    var delegate: GlobablWindowDelegate { GlobablWindowDelegate.instance }
    
    @ViewBuilder
    func switchModeButton() -> some View {
        switch displayMode {
        case .displayedAsSibling:
            Button("Undock", action: {
                displayMode = .displayedAsWindow
            }).padding(2)
        case .displayedAsWindow:
            Button("Dock", action: {
                displayMode = .displayedAsSibling
            }).padding(2)
        }
    }
    
    func performUndock() {
        guard !delegate.windowIsDisplayed(for: windowKey) else { return }
        displayWindowWithNewBuilderInstance()
    }
    
    func performDock() {
        delegate.dismissWindow(for: windowKey)
    }
    
    func displayWindowWithNewBuilderInstance() {
        VStack(alignment: .trailing, spacing: 0) {
            switchModeButton()
            innerViewBuilder()
        }.openInWindow(key: windowKey, sender: self)
    }
}
#endif
