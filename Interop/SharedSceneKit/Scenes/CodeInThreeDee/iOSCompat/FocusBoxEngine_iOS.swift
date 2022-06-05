//
//  FocusBoxEngineiOS.swift
//  LookAtThatMobile
//
//  Created by Ivan Lugo on 12/18/21.
//

import Foundation
import SceneKit

struct FocusBoxEngineiOS: FocusBoxLayoutEngine {
    private let userShim = FocusBoxUserEngineiOS()
    private let defaultShim = FocusBoxDefaultEngineiOS()
    
    func onSetBounds(_ container: FBLEContainer, _ newValue: Bounds) {
        switch container.box.layoutMode {
        case .userStack:
            userShim.onSetBounds(container, newValue)
        case .stacked:
            defaultShim.onSetBounds(container, newValue)
        case .horizontal:
            defaultShim.onSetBounds(container, newValue)
        case .cylinder:
            defaultShim.onSetBounds(container, newValue)
        }
    }
    
    func layout(_ container: FBLEContainer) {
        switch container.box.layoutMode {
        case .userStack:
            userShim.layout(container)
        case .stacked:
            defaultShim.layout(container)
        case .horizontal:
            defaultShim.layout(container)
        case .cylinder:
            defaultShim.layout(container)
        }
    }
}

private struct FocusBoxUserEngineiOS: FocusBoxLayoutEngine {
    func onSetBounds(_ container: FBLEContainer, _ newValue: Bounds) {
        // Set the size of the box to match
        let length: VectorFloat = 2.0 * DeviceScale
        let pad: VectorFloat = 32.0 * DeviceScale
        let halfPad: VectorFloat = pad / 2.0
        
        container.rootGeometry.width = (BoundsWidth(newValue) + pad).cg
        container.rootGeometry.height = (BoundsHeight(newValue) + pad).cg
        container.rootGeometry.length = length.cg
        
        let rootWidth = container.rootGeometry.width.vector
        let rootHeight = container.rootGeometry.height.vector
        
        /// translate geometry:
        /// 1. so it's top-left-front is at (0, 0, 1/2 length)
        /// 2. so it's aligned with the bounds of the grids themselves.
        /// Note: this math assumes nothing has been moved from the origin
        /// Note: -1.0 as multiple is explicit to remain compatiable between iOS macOS; '-' operand isn't universal
        let translateX = -1.0 * rootWidth / 2.0 - newValue.min.x + halfPad
        let translateY = rootHeight / 2.0 - newValue.max.y - halfPad
        let translateZ = -1.0 * (newValue.min.z - halfPad)
        
        container.geometryNode.pivot = SCNMatrix4MakeTranslation(
            translateX, translateY, translateZ
        )
    }
    
    func layout(_ container: FBLEContainer) {
        guard let first = container.box.bimap[0] else {
            print("No depth-0 grid to start layout")
            return
        }
        
//        let xLengthPadding: VectorFloat = 8.0 * DeviceScale
        let zLengthPadding: VectorFloat = 8.0 * DeviceScale
        
        container.box.snapping.iterateOver(first, direction: .forward) { previous, current, _ in
            if let previous = previous {
                current.measures
                    .setTop(previous.measures.top - previous.measures.lengthY / 2.0 + current.measures.lengthY / 2.0)
                    .alignedCenterX(previous)
                    .setFront(previous.measures.back - zLengthPadding)
//                current.rootNode.scale = SCNVector3(DeviceScale / 2, DeviceScale / 2, DeviceScale / 2)
            } else {
                current.zeroedPosition()
//                current.rootNode.scale = SCNVector3(DeviceScale, DeviceScale, DeviceScale)
            }
        }
    }
}

private struct FocusBoxDefaultEngineiOS: FocusBoxLayoutEngine {
    let xLengthPadding: VectorFloat = 8.0 * DeviceScale
    let zLengthPadding: VectorFloat = 150.0 * DeviceScale
    
    func onSetBounds(_ container: FBLEContainer, _ newValue: Bounds) {
        // Set the size of the box to match
        let pad: VectorFloat = 32.0 * DeviceScale
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
        sceneTransaction {
            switch container.box.layoutMode {
            case .horizontal:
                horizontalLayout(container)
            case .stacked:
                stackLayout(container)
            case .userStack:
                print("ERROR - iOS user stack in the wrong engine!")
            case .cylinder:
                cylinderLayout(container)
            }
        }
        
        func cylinderLayout(_ container: FBLEContainer) {
            let allGrids = container.box.bimap.keysToValues.keys
            let gridCount = allGrids.count
            let allChildFoci = container.box.childFocusBimap.keysToValues.keys
            let childCount = allChildFoci.count
            
            let twoPi = 2.0 * VectorVal.pi
            let gridRadians = twoPi / VectorVal(gridCount)
            let gridRadianStride = stride(from: 0.0, to: twoPi, by: gridRadians)
            let fileBounds = BoundsComputing()
            zip(allGrids, gridRadianStride).forEach { grid, radians in
                let magnitude = VectorVal(16.0)
                let dX = cos(radians) * magnitude
                let dZ = -(sin(radians) * magnitude)
                
                // translate dY unit vector along z-axis, rotating the unit circle along x
                grid.zeroedPosition()
                grid.rootNode.translate(dX: dX, dZ: dZ)
                grid.rootNode.eulerAngles.y = radians
                fileBounds.consumeBounds(grid.rootNode.boundingBox)
            }
            
            let finalGridBounds = fileBounds.bounds
            let childRadians = twoPi / VectorVal(childCount)
            let childRadianStride = stride(from: 0.0, to: twoPi, by: childRadians)
            
            zip(allChildFoci, childRadianStride).forEach { focus, radians in
                let magnitude = VectorVal(400.0)
                let dX =  (cos(radians) * (magnitude + finalGridBounds.max.x))
                let dY = finalGridBounds.min.y - 16.0
                let dZ = -(sin(radians) * (magnitude + finalGridBounds.max.x))
                
                // translate dY unit vector along z-axis, rotating the unit circle along x
                focus.rootNode.position = SCNVector3Zero
                focus.rootNode.translate(
                    dX: dX,
                    dY: dY,
                    dZ: dZ
                )
                focus.rootNode.eulerAngles.y = radians
            }
        }
    }
    
    func horizontalLayout(_ container: FBLEContainer) {
        guard let first = container.box.bimap[0] else {
            print("No depth-0 grid to start layout")
            return
        }
        
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
    
    func stackLayout(_ container: FBLEContainer) {
        guard let first = container.box.bimap[0] else {
            print("No depth-0 grid to start layout")
            return
        }
        
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
