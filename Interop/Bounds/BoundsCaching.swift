//
//  SceneKit+BoundsCaching.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation
import SceneKit

//typealias BoundsKey = String
typealias BoundsKey = MetalLinkNode

// MARK: Bounds caching
class BoundsCaching {
    private static var boundsCache = ConcurrentDictionary<BoundsKey, Bounds>()
    private static let BoundsZero: Bounds = (min: .zero, max: .zero)
    
    public static func Clear() {
        boundsCache.removeAll()
    }
    
    internal static func getOrUpdate(_ node: MetalLinkNode) -> Bounds {
        var bounds: Bounds?
        bounds = boundsCache[node]
        guard let cached = bounds else {
            return Update(node)
        }
        return cached
    }
    
    internal static func Update(_ node: MetalLinkNode) -> Bounds {
        let box = node.computeBoundingBox()
        boundsCache[node] = box
        return box
    }
    
    internal static func Set(_ node: MetalLinkNode, _ bounds: Bounds) {
        boundsCache[node] = bounds
    }
    
    internal static func ClearRoot(_ root: MetalLinkNode) {
        boundsCache[root] = nil
        root.enumerateChildren { node in
            boundsCache[node] = nil
        }
    }
}
