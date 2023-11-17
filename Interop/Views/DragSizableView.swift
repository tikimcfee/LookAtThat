//
//  DragSizableView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/14/22.
//

import SwiftUI

struct DragSizableViewState: Codable, Equatable {
    var contentBounds: CGSize = .zero
    var offset = CGPoint(x: 0, y: 0)
    var lastOffset = CGPoint(x: 0, y: 0)
    
    mutating func updateDrag(
        _ value: DragGesture.Value,
        _ isFinal: Bool
    ) {
        offset.x = lastOffset.x + value.translation.width
        offset.y = lastOffset.y + value.translation.height
        if isFinal {
            lastOffset = offset
        }
    }
}

struct DragSizableModifer: ViewModifier {
    // TODO: If you sant to save window position, make this owned by the invoker
    @Binding var state: DragSizableViewState
    let onDragEnded: () -> Void
    
    @ViewBuilder
    public func body(content: Content) -> some View {
        rootPositionableView(content)
            .offset(x: state.offset.x, y: state.offset.y)
    }
    
    func rootPositionableView(_ wrappedContent: Content) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            dragBar.frame(maxWidth: state.contentBounds.width)
            wrappedContent.onSizeChanged(DraggableViewSize.self) {
                guard state.contentBounds != $0 else { return }
                state.contentBounds = $0
            }
            dragBar.frame(maxWidth: state.contentBounds.width)
        }
    }
    
    var dragBar: some View {
        Color.gray.opacity(0.8)
            .frame(maxHeight: 16)
            .highPriorityGesture(
                DragGesture(
                    minimumDistance: 1.0,
                    coordinateSpace: .global
                )
                .onChanged { value in
                    state.updateDrag(value, false)
                }
                .onEnded { value in
                    state.updateDrag(value, true)
                    onDragEnded()
                }
            )
    }
}
