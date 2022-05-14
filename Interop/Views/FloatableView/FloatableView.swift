//
//  FloatableView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/14/22.
//

import SwiftUI

class FloatableViewState: ObservableObject {
    enum Mode {
        case displayedAsWindow
        case displayedAsSibling
    }
    @Published var currentMode: Mode = .displayedAsSibling
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
    #endif
    }
}

#if os(macOS)
extension FloatableViewState {
    func dismissWindow(for key: GlobalWindowKey) {
        GlobablWindowDelegate.instance.dismissWindow(for: key)
    }
}

extension FloatableView {
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
#endif
