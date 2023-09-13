//  LookAtThat_AppKit
//
//  Created on 9/13/23.
//

import SwiftUI

// MARK: - PreferenceKey, Size

public protocol CGSizePreferenceKey: PreferenceKey where Value == CGSize {}

public extension CGSizePreferenceKey {
    static func reduce(value _: inout CGSize, nextValue: () -> CGSize) {
        _ = nextValue()
    }
}

public extension View {
    func onSizeChanged<Key: CGSizePreferenceKey>(
        _ key: Key.Type,
        perform action: @escaping (CGSize) -> Void) -> some View
    {
        self.background(GeometryReader { geo in
            Color.clear
                .preference(key: Key.self, value: geo.size)
        })
        .onPreferenceChange(key) { value in
            action(value)
        }
    }
}

// MARK: - Shared Keys

struct DraggableViewSize: CGSizePreferenceKey {
    static var defaultValue: CGSize = .zero
}
