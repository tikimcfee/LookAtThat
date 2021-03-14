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


public extension SCNNode {
    private typealias Bounds = (min: SCNVector3, max: SCNVector3)
    private static var boundsCache: [Int: Bounds] = [:]
    private static func makeNewBounds() -> Bounds { (min: SCNVector3(), max: SCNVector3()) }
    
    private var manualBoundingBox: Bounds {
        if childNodes.count == 0 {
            return boundingBox
        }
        
        if let bounds = Self.boundsCache[hashValue] {
            return bounds
        }
        
        let computedBox = childNodes.reduce(into: Self.makeNewBounds()) { result, node in
            var safeBox = node.manualBoundingBox
            safeBox.min = convertPosition(safeBox.min, from: node)
            safeBox.max = convertPosition(safeBox.max, from: node)
            
            result.min.x = min(safeBox.min.x, result.min.x)
            result.min.y = min(safeBox.min.y, result.min.y)

            result.max.x = max(safeBox.max.x, result.max.x)
            result.max.y = max(safeBox.max.y, result.max.y)
        }
        
        Self.boundsCache[hashValue] = computedBox
        
        return computedBox
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
