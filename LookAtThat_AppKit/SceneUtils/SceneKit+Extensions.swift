import Foundation
import SceneKit

func lockedSceneTransaction(_ operation: () -> Void) {
    SCNTransaction.lock()
    SCNTransaction.begin()
    operation()
    SCNTransaction.commit()
    SCNTransaction.unlock()
}

func sceneTransaction(_ duration: Int? = nil, _ operation: () -> Void, ) {
    SCNTransaction.begin()
    SCNTransaction.animationDuration =
        duration.map{ CFTimeInterval($0) }
            ?? SCNTransaction.animationDuration
    operation()
    SCNTransaction.commit()
}

public extension SCNGeometry {
    var lengthX: CGFloat { return boundingBox.max.x - boundingBox.min.x }
    var lengthY: CGFloat { return boundingBox.max.y - boundingBox.min.y }
    var lengthZ: CGFloat { return boundingBox.max.z - boundingBox.min.z }
    var centerX: CGFloat { return lengthX / 2 }
    var centerY: CGFloat { return lengthY / 2 }
    var centerZ: CGFloat { return lengthZ / 2 }
    var centerPosition: SCNVector3 { return SCNVector3(x: centerX, y: centerY, z: centerZ) }

    func deepCopy() -> SCNGeometry {
        let clone = copy() as! SCNGeometry
        clone.materials = materials.map{ $0.copy() as! SCNMaterial }
        return clone
    }
}

public extension SCNNode {
    var lengthX: CGFloat {
        return boundingBox.max.x - boundingBox.min.x
    }

    var lengthY: CGFloat {
        return boundingBox.max.y - boundingBox.min.y
    }

    var lengthZ: CGFloat {
        return boundingBox.max.z - boundingBox.min.z
    }

    func chainLinkTo(to target: SCNNode) {
        let distance = SCNDistanceConstraint(target: target)
        distance.maximumDistance = target.lengthX
        distance.minimumDistance = target.lengthX
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
    func translated(dX: CGFloat = 0, dY: CGFloat = 0, dZ: CGFloat = 0) -> SCNVector3 {
        return SCNVector3(x: x + dX,
                          y: y + dY,
                          z: z + dZ)
    }
}
