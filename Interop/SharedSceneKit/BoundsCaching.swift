//
//  SceneKit+BoundsCaching.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation
import SceneKit

typealias BoundsKey = String
let uuidLength = UUID().uuidString.count

// MARK: Bounds caching
class BoundsCaching {
    private static var boundsCache = ConcurrentDictionary<BoundsKey, Bounds>()
    private static let BoundsZero: Bounds = (min: .zero, max: .zero)
    
    public static func Clear() {
        boundsCache.removeAll()
    }
    
    internal static func getOrUpdate(_ node: MetalLinkNode) -> Bounds {
        var bounds: Bounds?
        bounds = boundsCache[node.boundsCacheKey]
        guard let cached = bounds else {
            return Update(node)
        }
        return cached
    }
    
    internal static func Update(_ node: MetalLinkNode) -> Bounds {
        let box = node.computeBoundingBox()
        boundsCache[node.boundsCacheKey] = box
        return box
    }
    
    internal static func Set(_ node: MetalLinkNode, _ bounds: Bounds) {
        boundsCache[node.boundsCacheKey] = bounds
    }
    
    internal static func ClearRoot(_ root: MetalLinkNode) {
        root.enumerateChildren { node in
            boundsCache[node.boundsCacheKey] = nil
        }
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
        
        return computing.bounds
    }
}

extension MetalLinkNode {
    
    var manualBoundingBox: Bounds {
        return BoundsCaching.getOrUpdate(self)
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

func BoundsWidth(_ bounds: Bounds) -> VectorFloat { abs(bounds.max.x - bounds.min.x) }
func BoundsHeight(_ bounds: Bounds) -> VectorFloat { abs(bounds.max.y - bounds.min.y) }
func BoundsLength(_ bounds: Bounds) -> VectorFloat { abs(bounds.max.z - bounds.min.z) }

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
