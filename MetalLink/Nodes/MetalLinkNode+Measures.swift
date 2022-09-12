//
//  MetalLinkNode+Measures.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/26/22.
//

import Foundation
import Metal

extension MetalLinkNode {
    func convertPosition(_ convertTarget: LFloat3, to final: MetalLinkNode?) -> LFloat3 {
        var position: LFloat3 = convertTarget
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
        get { worldPosition.x - abs(bounds.min.x) }
    }
    var worldTrailing: VectorFloat {
        get { worldPosition.x + abs(bounds.max.x) }
    }
    var worldTop: VectorFloat {
        get { worldPosition.y + abs(bounds.max.y) }
    }
    var worldBottom: VectorFloat {
        get { worldPosition.y - abs(bounds.min.y) }
    }
    var worldFront: VectorFloat {
        get { worldPosition.z + abs(bounds.max.z) }
    }
    var worldBack: VectorFloat {
        get { worldPosition.z - abs(bounds.min.z) }
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
