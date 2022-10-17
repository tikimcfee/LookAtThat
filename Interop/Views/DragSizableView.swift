//
//  DragSizableView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/14/22.
//

import SwiftUI

extension DragSizableViewState {
    struct Offset {
        var current: CGSize = .zero
        var last: CGSize = .zero
    }
    
    enum ResizeCorner: CaseIterable {
        case topLeft
        case botLeft
        case topRight
        case botRight
    }
}

class DragSizableViewState: ObservableObject {
    @Published var rootPositionOffsetLast: CGSize = .zero
    @Published var rootPositionOffset: CGSize = .zero
    @Published var resizeOffets = [ResizeCorner: Offset]()
    
    private var sumOffsetWidth: CGFloat {
        resizeOffets.reduce(into: CGFloat(0.0)) { total, pair in
            total += pair.value.current.width
        }
    }
    
    private var sumOffsetHeight: CGFloat {
        resizeOffets.reduce(into: CGFloat(0.0)) { total, pair in
            total += pair.value.current.height
        }
    }
    
    func updateDrag(
        _ translation: CGSize,
        _ isFinal: Bool
    ) {
        rootPositionOffset = translation + rootPositionOffsetLast
        if isFinal {
            rootPositionOffsetLast = rootPositionOffset
        }
    }
    
    func updateResize(
        _ corner: ResizeCorner,
        _ translation: CGSize,
        _ isFinal: Bool
    ) {
        var newResizeOffset = resizeOffets[corner, default: Offset()]
        switch corner {
        case .topLeft:
            newResizeOffset.current = translation.negated() + newResizeOffset.last
            rootPositionOffset = translation + rootPositionOffsetLast
            
        case .topRight:
            newResizeOffset.current = translation.negatedHeight() + newResizeOffset.last
            rootPositionOffset.height = translation.height + rootPositionOffsetLast.height
            
        case .botLeft:
            newResizeOffset.current = translation.negatedWidth() + newResizeOffset.last
            rootPositionOffset.width = translation.width + rootPositionOffsetLast.width
            
        case .botRight:
            newResizeOffset.current = translation + newResizeOffset.last
        }
        if isFinal {
            newResizeOffset.last = newResizeOffset.current
            rootPositionOffsetLast = rootPositionOffset
        }
        resizeOffets[corner] = newResizeOffset
    }
    
    func offsetWidth(original: CGSize) -> CGFloat {
        let total = original.width + sumOffsetWidth
        return total
    }
    
    func offsetHeight(original: CGSize) -> CGFloat {
        let total = original.height + sumOffsetHeight
        return total
    }
}

struct DragSizableModifer: ViewModifier {
    // TODO: If you sant to save window position, make this owned by the invoker
    @StateObject var state = DragSizableViewState()
    let buttonHeight = 16.0
    
    @ViewBuilder
    public func body(content: Content) -> some View {
        GeometryReader { reader in
            rootPositionableView(content)
                .frame(
                    width: max(0, state.offsetWidth(original: reader.size)),
                    height: max(0, state.offsetHeight(original: reader.size))
                )
                .offset(state.rootPositionOffset)
        }
    }
    
    func rootPositionableView(_ wrappedContent: Content) -> some View {
        VStack(alignment: .trailing, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                dragBar
                HStack {
                    resizeBox(.topLeft)
                    Spacer()
                    resizeBox(.topRight)
                }
            }
            wrappedContent
            ZStack(alignment: .topTrailing) {
                dragBar
                HStack {
                    resizeBox(.botLeft)
                    Spacer()
                    resizeBox(.botRight)
                }
            }
        }
    }
    
    func resizeBox(_ target: DragSizableViewState.ResizeCorner) -> some View {
        cornerView(target)
            .font(.headline)
            .fontWeight(.bold)
            .frame(width: buttonHeight, height: buttonHeight)
            .background(Color.gray)
            .highPriorityGesture(
                DragGesture(
                    minimumDistance: 1,
                    coordinateSpace: .global
                ).onChanged {
                    state.updateResize(target, $0.translation, false)
                }.onEnded {
                    state.updateResize(target, $0.translation, true)
                }
            )
    }
    
    func cornerView(_ target: DragSizableViewState.ResizeCorner) -> Text {
        switch target {
        case .topLeft:
            return Text("⎡")
        case .topRight:
            return Text("⎤")
        case .botLeft:
            return Text("⎣")
        case .botRight:
            return Text("⎦")
        }
    }
    
    var dragBar: some View {
        Color.gray.opacity(0.8)
            .frame(maxHeight: buttonHeight)
            .highPriorityGesture(
                DragGesture(
                    minimumDistance: 1,
                    coordinateSpace: .global
                ).onChanged {
                    state.updateDrag($0.translation, false)
                }.onEnded {
                    state.updateDrag($0.translation, true)
                }
            )
    }
}

extension CGSize: AdditiveArithmetic {
    public static func - (lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width - rhs.width,
                      height: lhs.height - rhs.height)
    }
    
    public static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        return CGSize(width: lhs.width + rhs.width,
                      height: lhs.height + rhs.height)
    }
    
    public func negated() -> CGSize {
        CGSize(width: width * -1, height: height * -1)
    }
    
    public func negatedWidth() -> CGSize {
        CGSize(width: width * -1, height: height)
    }
    
    public func negatedHeight() -> CGSize {
        CGSize(width: width, height: height * -1)
    }
}
