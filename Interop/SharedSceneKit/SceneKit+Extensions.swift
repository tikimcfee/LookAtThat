import Foundation
import SceneKit

func lockedSceneTransaction(_ operation: () -> Void) {
    SCNTransaction.lock()
    SCNTransaction.begin()
    operation()
    SCNTransaction.commit()
    SCNTransaction.unlock()
}

func sceneTransaction(_ duration: Int? = nil,
                      _ operation: () -> Void) {
    SCNTransaction.begin()
    SCNTransaction.animationDuration =
        duration.map{ CFTimeInterval($0) }
            ?? SCNTransaction.animationDuration
    operation()
    SCNTransaction.commit()
}

public extension SCNGeometry {
    var lengthX: VectorFloat { return boundingBox.max.x - boundingBox.min.x }
    var lengthY: VectorFloat { return boundingBox.max.y - boundingBox.min.y }
    var lengthZ: VectorFloat { return boundingBox.max.z - boundingBox.min.z }
    var centerX: VectorFloat { return lengthX / 2 }
    var centerY: VectorFloat { return lengthY / 2 }
    var centerZ: VectorFloat { return lengthZ / 2 }
    var centerPosition: SCNVector3 { return SCNVector3(x: centerX, y: centerY, z: centerZ) }

    func deepCopy() -> SCNGeometry {
        let clone = copy() as! SCNGeometry
        clone.materials = materials.map{ $0.copy() as! SCNMaterial }
        return clone
    }
}

typealias Bounds = (min: SCNVector3, max: SCNVector3)

class BoundsComputing {
    var minX: VectorFloat = 0
    var minY: VectorFloat = 0
    var minZ: VectorFloat = 0
    
    var maxX: VectorFloat = 0
    var maxY: VectorFloat = 0
    var maxZ: VectorFloat = 0
    
    func consumeBounds(_ bounds: Bounds) {
        minX = min(bounds.min.x, minX)
        minY = min(bounds.min.y, minY)
        minZ = min(bounds.min.z, minZ)
        
        maxX = max(bounds.max.x, maxX)
        maxY = max(bounds.max.y, maxY)
        maxZ = max(bounds.max.z, maxZ)
    }
    
    var bounds: Bounds {
        return (
            min: SCNVector3(x: minX, y: minY, z: minZ),
            max: SCNVector3(x: maxX, y: maxY, z: maxZ)
        )
    }
}

typealias BoundsKey = Int

public extension SCNNode {
    private var cacheKey: BoundsKey { hashValue % childNodes.hashValue }
    
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
    
    private var manualBoundingBox: Bounds {
        childNodes.isEmpty
            ? boundingBox
            : BoundsCaching.getOrUpdate(self)
    }
    
    internal func computeBoundingBox() -> Bounds {
        childNodes.reduce(into: BoundsComputing()) { result, node in
            var safeBox = node.manualBoundingBox
            safeBox.min = convertPosition(safeBox.min, from: node)
            safeBox.max = convertPosition(safeBox.max, from: node)
            result.consumeBounds(safeBox)
        }.bounds
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

extension SCNVector3 {
    func translated(dX: VectorFloat = 0,
                    dY: VectorFloat = 0,
                    dZ: VectorFloat = 0) -> SCNVector3 {
        return SCNVector3(x: x + dX,
                          y: y + dY,
                          z: z + dZ)
    }

    func scaled(scaleX: VectorFloat = 1.0,
                scaleY: VectorFloat = 1.0,
                scaleZ: VectorFloat = 1.0) -> SCNVector3 {
        return SCNVector3(x: x * scaleX,
                          y: y * scaleY,
                          z: z * scaleZ)
    }
}
