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

    internal static func get(_ node: MetalLinkNode) -> Bounds? {
        return boundsCache[node]
    }
    
    internal static func Set(_ node: MetalLinkNode, _ bounds: Bounds?) {
        boundsCache[node] = bounds
    }
    
    internal static func ClearRoot(_ root: MetalLinkNode) {
        boundsCache[root] = nil
        root.enumerateChildren { node in
            boundsCache[node] = nil
        }
    }
}
