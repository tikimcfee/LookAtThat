//
//  FocusBoxLayoutMacOS.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/18/21.
//

import Foundation
import SceneKit

class FocusBoxLayoutMacOS: FocusBoxLayoutEngine {
    func onSetBounds(_ container: FBLEContainer, _ newValue: Bounds) {
        // Set the size of the box to match
        let pad: VectorFloat = 32.0
        let halfPad: VectorFloat = pad / 2.0
        
        container.rootGeometry.width = (BoundsWidth(newValue) + pad).cg
        container.rootGeometry.height = (BoundsHeight(newValue) + pad).cg
        container.rootGeometry.length = (BoundsLength(newValue) + pad).cg
        
        let rootWidth = container.rootGeometry.width.vector
        let rootHeight = container.rootGeometry.height.vector
        
        /// translate geometry:
        /// 1. so it's top-left-front is at (0, 0, 1/2 length)
        /// 2. so it's aligned with the bounds of the grids themselves.
        /// Note: this math assumes nothing has been moved from the origin
        /// Note: -1.0 as multiple is explicit to remain compatiable between iOS macOS; '-' operand isn't universal
        let translateX = -1.0 * rootWidth / 2.0 - newValue.min.x + halfPad
        let translateY = rootHeight / 2.0 - newValue.max.y - halfPad
        let translateZ = -newValue.min.z / 2.0
        
        container.geometryNode.pivot = SCNMatrix4MakeTranslation(
            translateX, translateY, translateZ
        )
    }
    
    func layout(_ container: FBLEContainer) {
        guard let first = container.box.bimap[0] else {
            print("No depth-0 grid to start layout")
            return
        }
        
        let xLengthPadding: VectorFloat = 8.0
        let zLengthPadding: VectorFloat = 150.0
        
        sceneTransaction {
            switch container.box.layoutMode {
            case .horizontal:
                horizontalLayout()
            case .stacked:
                stackLayout()
            }
        }
        
        func horizontalLayout() {
            container.box.snapping.iterateOver(first, direction: .right) { previous, current, _ in
                if let previous = previous {
                    current.measures
                        .setTop(previous.measures.top)
                        .setLeading(previous.measures.trailing + xLengthPadding)
                        .setBack(previous.measures.back)
                } else {
                    current.zeroedPosition()
                }
            }
        }
        
        func stackLayout() {
            container.box.snapping.iterateOver(first, direction: .forward) { previous, current, _ in
                if let previous = previous {
                    current.measures
                        .setTop(previous.measures.top)
                        .alignedCenterX(previous)
                        .setBack(previous.measures.back - zLengthPadding)
                } else {
                    current.zeroedPosition()
                }
            }
        }
    }
}
