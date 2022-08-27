//
//  MetalLinkNode+Bounds.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/26/22.
//

import Foundation

extension MetalLinkNode {
    var manualBoundingBox: Bounds {
//        return BoundsCaching.getOrUpdate(self)
        return computeBoundingBox()
    }
    
    var lengthX: VectorFloat {
        let box = manualBoundingBox
        return abs(box.max.x - box.min.x)
    }
    
    var lengthY: VectorFloat {
        let box = manualBoundingBox
        return abs(box.max.y - box.min.y)
    }
    
    var lengthZ: VectorFloat {
        let box = manualBoundingBox
        return abs(box.max.z - box.min.z)
    }
    
    var centerX: VectorFloat {
        let box = manualBoundingBox
        return lengthX / 2.0 + box.min.x
    }
    
    var centerY: VectorFloat {
        let box = manualBoundingBox
        return lengthY / 2.0 + box.min.y
    }
    
    var centerZ: VectorFloat {
        let box = manualBoundingBox
        return lengthZ / 2.0 + box.min.z
    }
    
    var centerPosition: LFloat3 {
        return LFloat3(x: centerX, y: centerY, z: centerZ)
    }
}

extension MetalLinkNode {
    var boundsCacheKey: BoundsKey {
        return nodeId
    }
    
    func computeBoundingBox() -> Bounds {
        let computing = BoundsComputing()
        
        enumerateChildren { childNode in
            var safeBox = childNode.manualBoundingBox
            safeBox.min = convertPositionToParent(safeBox.min)
            safeBox.max = convertPositionToParent(safeBox.max)
            computing.consumeBounds(safeBox)
        }
        
        if let sizable = self as? ContentSizing {
            let size = sizable.size
            let min = LFloat3(position.x,
                              position.y - size.y,
                              position.z - size.z)
            let max = LFloat3(position.x + size.x,
                              position.y,
                              position.z)
//            print("min", min, "max", max)
            computing.consumeBounds((
                min: min,
                max: max
            ))
        }
        
        return computing.bounds
    }
}
