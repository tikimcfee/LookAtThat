//
//  MetalLinkNode+Measures.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/26/22.
//

import Foundation
import Metal

extension MetalLinkNode {
    var boundsWidth: VectorFloat { abs(manualBoundingBox.max.x - manualBoundingBox.min.x) }
    var boundsHeight: VectorFloat { abs(manualBoundingBox.max.y - manualBoundingBox.min.y) }
    var boundsLength: VectorFloat { abs(manualBoundingBox.max.z - manualBoundingBox.min.z) }
    
    var boundsCenterWidth: VectorFloat { boundsWidth / 2.0 + manualBoundingBox.min.x }
    var boundsCenterHeight: VectorFloat { boundsHeight / 2.0 + manualBoundingBox.min.y }
    var boundsCenterLength: VectorFloat { boundsLength / 2.0 + manualBoundingBox.min.z }
    
    var boundsCenterPosition: LFloat3 {
        let vector = LFloat3(
            x: boundsCenterWidth,
            y: boundsCenterHeight,
            z: boundsCenterLength
        )
        return convertPositionToParent(vector)
    }
    
    var boundsInParent: Bounds {
        let minVector = convertPositionToParent(manualBoundingBox.min)
        let maxVector = convertPositionToParent(manualBoundingBox.max)
        return (minVector, maxVector)
    }
    
    var boundsInWorld: Bounds {
        let minVector = convertPosition(manualBoundingBox.min, to: nil)
        let maxVector = convertPosition(manualBoundingBox.max, to: nil)
        return (minVector, maxVector)
    }
}

extension MetalLinkNode {
    func convertPositionToParent(_ convertTarget: LFloat3) -> LFloat3 {
        return (parent?.position ?? .zero) + convertTarget
    }
    
    func convertPosition(_ convertTarget: LFloat3, to final: MetalLinkNode?) -> LFloat3 {
        var position = position
        var nodeParent = parent
        while !(nodeParent == final || nodeParent == nil) {
            position += nodeParent?.position ?? .zero
            nodeParent = nodeParent?.parent
        }
        // Stopped at 'final'; add the final position manually
        position += final?.position ?? .zero
                    
        return position
    }
    
    var worldPosition: LFloat3 {
        get {
            var finalPosition: LFloat3 = position
            var nodeParent = parent
            while let parent = nodeParent {
                finalPosition += parent.position
                nodeParent = parent.parent
            }
            return finalPosition
        }
        set {
            var finalPosition: LFloat3 = newValue
            var nodeParent = parent
            while let parent = nodeParent {
                finalPosition += parent.position
                nodeParent = parent.parent
            }
            position = finalPosition
        }
    }
    
    var worldLeading: VectorFloat {
        get { worldPosition.x - abs(manualBoundingBox.min.x) }
    }
    var worldTrailing: VectorFloat {
        get { worldPosition.x + abs(manualBoundingBox.max.x) }
    }
    var worldTop: VectorFloat {
        get { worldPosition.y + abs(manualBoundingBox.max.y) }
    }
    var worldBottom: VectorFloat {
        get { worldPosition.y - abs(manualBoundingBox.min.y) }
    }
    var worldFront: VectorFloat {
        get { worldPosition.z + abs(manualBoundingBox.max.z) }
    }
    var worldBack: VectorFloat {
        get { worldPosition.z - abs(manualBoundingBox.min.z) }
    }
    
    var worldBoundsMin: LFloat3 {
        LFloat3(worldLeading, worldBottom, worldBack)
    }
    
    var worldBoundsMax: LFloat3 {
        LFloat3(worldTrailing, worldTop, worldFront)
    }
    
    var worldBounds: Bounds {
        (min: worldBoundsMin, max: worldBoundsMax)
    }
}
