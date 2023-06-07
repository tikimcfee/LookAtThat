//
//  SceneKit+BoundsCaching.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation
import SceneKit
import MetalLink
import BitHandling

//typealias BoundsKey = String
public typealias BoundsKey = MetalLinkNode

// MARK: Bounds caching
public class BoundsCaching {
    private static var boundsCache = ConcurrentDictionary<BoundsKey, Bounds>()
    private static let BoundsZero: Bounds = (min: .zero, max: .zero)
    
    public static func Clear() {
        boundsCache.removeAll()
    }

    public static func get(_ node: MetalLinkNode) -> Bounds? {
        return boundsCache[node]
    }
    
    public static func Set(_ node: MetalLinkNode, _ bounds: Bounds?) {
        boundsCache[node] = bounds
    }
    
    internal static func ClearRoot(_ root: MetalLinkNode) {
        boundsCache[root] = nil
        root.enumerateChildren { node in
            boundsCache[node] = nil
        }
    }
}
