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
        private static var boundsCacheLocking = LockingCache<BoundsKey, Bounds>()
        private static var boundsCache: [BoundsKey: Bounds] = [:]
        private static let BoundsZero: Bounds = (min: SCNVector3Zero, max: SCNVector3Zero)
        
        public static func Clear() {
            boundsCache.removeAll()
        }
        
        internal static func getOrUpdate(_ node: SCNNode, presentation: Bool) -> Bounds {
            var bounds: Bounds?
            boundsCacheLocking.lockAndDo { cache in
                bounds = cache[node.cacheKey]
            }
            guard let cached = bounds else {
                return Update(node, presentation)
            }
            return cached
        }
        
        internal static func Update(_ node: SCNNode, _ presentation: Bool) -> Bounds {
            let box = node.computeBoundingBox(presentation)
            boundsCacheLocking.lockAndDo { cache in
                cache[node.cacheKey] = box
            }
            return box
        }
        
        internal static func ClearRoot(_ root: SCNNode) {
            boundsCacheLocking.lockAndDo { cache in
                root.enumerateHierarchy { node, _ in
                    cache[node.cacheKey] = nil
                }
            }
        }
    }
    
    func computeBoundingBox(_ presentation: Bool) -> Bounds {
        childNodes.reduce(into: BoundsComputing()) { result, node in
            var safeBox = presentation
                ? node.manualPresentationBoundingBox
                : node.manualBoundingBox
            safeBox.min = convertPosition(safeBox.min, from: node)
            safeBox.max = convertPosition(safeBox.max, from: node)
            result.consumeBounds(safeBox)
        }.bounds
    }
}

public extension SCNNode {
    var manualBoundingBox: Bounds {
        childNodes.isEmpty
            ? boundingBox
            : BoundsCaching.getOrUpdate(self, presentation: false)
    }
    
    var manualPresentationBoundingBox: Bounds {
        childNodes.isEmpty
            ? presentation.boundingBox
            : BoundsCaching.getOrUpdate(presentation, presentation: true)
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
    
    var centerX: VectorFloat {
        return lengthX / 2.0
    }
    
    var centerY: VectorFloat {
        return lengthY / 2.0
    }
    
    var centerZ: VectorFloat {
        return lengthZ / 2.0
    }
    
    var centerPosition: SCNVector3 {
        return SCNVector3(x: centerX, y: centerY, z: centerZ)
    }
    
    func chainLinkTo(to target: SCNNode) {
        let distance = SCNDistanceConstraint(target: target)
        let orientation = SCNTransformConstraint.orientationConstraint(
            inWorldSpace: true,
            with: { node, quaternion in target.orientation }
        )
        distance.maximumDistance = target.lengthX.cg
        distance.minimumDistance = target.lengthX.cg
        addConstraint(distance)
        addConstraint(orientation)
    }
    
    func chainLinkZDepth(to target: SCNNode, depth: VectorFloat) {
        let position = SCNTransformConstraint.positionConstraint(
            inWorldSpace: true,
            with: { node, position in
                node.position.translated(dZ: depth)
            }
        )
        addConstraint(position)
    }
    
    func addConstraint(_ constraint: SCNConstraint) {
        var list = constraints ?? []
        guard list.first(where: { $0 === constraint}) == nil else { return }
        list.append(constraint)
        constraints = list
    }
    
    func removeConstraint(_ constraint: SCNConstraint) {
        constraints?.removeAll(where: { $0 === constraint })
    }
    
    func addWireframeBox() {
        let debugBox = SCNBox()
        debugBox.firstMaterial?.diffuse.contents = NSUIColor.clear
//        debugBox.width = 10
//        debugBox.height = 10
//        debugBox.length = 10
        geometry = debugBox
    }
    
    func addWireframePoint() {
        let debugBox = SCNSphere()
        debugBox.firstMaterial?.diffuse.contents = NSUIColor.lightGray
        debugBox.radius = 10
        geometry = debugBox
    }
}
