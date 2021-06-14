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
public extension SCNNode {
    
    private var cacheKey: BoundsKey {
        /*
         This is pretty dangerous, but I need something more unique than an Int, apparently.
         The String gives me a chance to use a UUID, but the code also uses it to store
         info for looking up across SceneKit. Soo... we just stick a UUID.string into the name
         if there isn't already one, or append one to make it unique. This also means if someone
         updates the name, we lose the UUID, and the only guard is a length check.
         */
        if let hasName = name {
            if hasName.count < uuidLength {
                name = hasName + UUID().uuidString
            }
        } else {
            name = UUID().uuidString
        }
        return name!
    }
    
    class BoundsCaching {
        private static var boundsCache: [BoundsKey: Bounds] = [:]
        
        public static func Clear() {
            boundsCache.removeAll()
        }
        
        internal static func getOrUpdate(_ node: SCNNode) -> Bounds {
            boundsCache[node.cacheKey] ?? Update(node)
        }
        
        internal static func Update(_ node: SCNNode) -> Bounds {
            let box = node.computeBoundingBox()
            boundsCache[node.cacheKey] = box
            return box
        }
    }
    
    internal func computeBoundingBox() -> Bounds {
        childNodes.reduce(into: BoundsComputing()) { result, node in
            var safeBox = node.manualBoundingBox
            safeBox.min = convertPosition(safeBox.min, from: node)
            safeBox.max = convertPosition(safeBox.max, from: node)
            result.consumeBounds(safeBox)
        }.bounds
    }
}

public extension SCNNode {
    private var manualBoundingBox: Bounds {
        childNodes.isEmpty
            ? boundingBox
            : BoundsCaching.getOrUpdate(self)
    }
    
    var lengthX: VectorFloat {
        let box = manualBoundingBox
        return box.max.x - box.min.x
    }
    
    var lengthY: VectorFloat {
        let box = manualBoundingBox
        return box.max.y - box.min.y
    }
    
    var lengthZ: VectorFloat {
        let box = manualBoundingBox
        return box.max.z - box.min.z
    }
    
    func chainLinkTo(to target: SCNNode) {
        let distance = SCNDistanceConstraint(target: target)
        distance.maximumDistance = target.lengthX.cg
        distance.minimumDistance = target.lengthX.cg
        self.constraints = {
            var list = constraints ?? []
            list.append(distance)
            return list
        }()
    }
    
    func addWireframeBox() {
        let debugBox = SCNBox()
        debugBox.firstMaterial?.diffuse.contents = NSUIColor.clear
        geometry = debugBox
    }
}
