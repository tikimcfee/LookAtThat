//
//  FocusBoxLayoutMacOS.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/18/21.
//

import Foundation
import SceneKit

class FocusBoxEngineMacOS: FocusBoxLayoutEngine {
    var xLengthPadding: VectorFloat = 8.0
    var zLengthPadding: VectorFloat = 196.0
    
    func onSetBounds(_ container: FBLEContainer, _ newValue: Bounds) {
        defaultOnSetBounds(container, newValue)
    }
    
    func layout(_ container: FBLEContainer) {
        sceneTransaction {
            switch container.box.layoutMode {
            case .horizontal:
                guard let first = container.box.bimap[0] else { return }
                horizontalLayout(first, container)
            case .stacked:
                guard let first = container.box.bimap[0] else { return }
                stackLayout(first, container)
            case .userStack:
                guard let first = container.box.bimap[0] else { return }
                userLayout(first, container)
            case .cylinder:
                defaultCylinderLayout(container)
            }
        }
    }
    
    func userLayout(
        _ first: CodeGrid,
        _ container: FBLEContainer
    ) {
        container.box.snapping.iterateOver(first, direction: .forward) { previous, current, _ in
            if let previous = previous {
                current.measures
                    .setTop(previous.measures.top)
                    .alignedCenterX(previous)
                    .setBack(previous.measures.back - self.zLengthPadding)
            } else {
                current.zeroedPosition()
            }
        }
    }
    
    func stackLayout(
        _ first: CodeGrid,
        _ container: FBLEContainer
    ) {
        container.box.snapping.iterateOver(first, direction: .forward) { previous, current, _ in
            if let previous = previous {
                current.measures
                    .setTop(previous.measures.top)
                    .setLeading(previous.measures.leading)
                    .setBack(previous.measures.front + self.zLengthPadding)
            } else {
                current.zeroedPosition()
            }
        }
    }
    
    func horizontalLayout(
        _ first: CodeGrid,
        _ container: FBLEContainer
    ) {
        container.box.snapping.iterateOver(first, direction: .right) { previous, current, _ in
            if let previous = previous {
                current.measures
                    .setTop(previous.measures.top)
                    .setLeading(previous.measures.trailing + self.xLengthPadding)
                    .setBack(previous.measures.back)
            } else {
                current.zeroedPosition()
            }
        }
    }
}
