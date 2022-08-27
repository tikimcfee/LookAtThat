//
//  BoundsComputing.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/26/22.
//

import Foundation

public typealias Bounds = (
    min: LFloat3,
    max: LFloat3
)

class BoundsComputing {
    var didSetInitial: Bool = false
    var minX: VectorFloat = .infinity
    var minY: VectorFloat = .infinity
    var minZ: VectorFloat = .infinity
    
    var maxX: VectorFloat = -.infinity
    var maxY: VectorFloat = -.infinity
    var maxZ: VectorFloat = -.infinity
    
    func consumeBounds(_ bounds: Bounds) {
        didSetInitial = true
        minX = min(bounds.min.x, minX)
        minY = min(bounds.min.y, minY)
        minZ = min(bounds.min.z, minZ)
        
        maxX = max(bounds.max.x, maxX)
        maxY = max(bounds.max.y, maxY)
        maxZ = max(bounds.max.z, maxZ)
    }
    
    func consumeNodeSet(
        _ nodes: Set<MetalLinkNode>,
        convertingTo node: MetalLinkNode?
    ) {
        for node in nodes {
            consumeBounds(
                node.boundsInParent
            )
        }
    }
    
    func pad(_ pad: VectorFloat) {
        minX -= pad
        minY -= pad
        minZ -= pad
        
        maxX += pad
        maxY += pad
        maxZ += pad
    }
    
    var bounds: Bounds {
        guard didSetInitial else {
            print("Bounds were never set; returning safe default")
            return (min: .zero, max: .zero)
        }
        return (
            min: LFloat3(x: minX, y: minY, z: minZ),
            max: LFloat3(x: maxX, y: maxY, z: maxZ)
        )
    }
}

func BoundsWidth(_ bounds: Bounds) -> VectorFloat { abs(bounds.max.x - bounds.min.x) }
func BoundsHeight(_ bounds: Bounds) -> VectorFloat { abs(bounds.max.y - bounds.min.y) }
func BoundsLength(_ bounds: Bounds) -> VectorFloat { abs(bounds.max.z - bounds.min.z) }
func BoundsSize(_ bounds: Bounds) -> LFloat3 {
    LFloat3(BoundsWidth(bounds), BoundsHeight(bounds), BoundsLength(bounds))
}
