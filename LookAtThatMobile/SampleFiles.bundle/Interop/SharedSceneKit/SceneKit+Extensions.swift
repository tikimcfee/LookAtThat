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
                      _ timing: CAMediaTimingFunction? = nil,
                      _ operation: () throws -> Void) {
    SCNTransaction.begin()
    SCNTransaction.animationTimingFunction =  timing ?? SCNTransaction.animationTimingFunction
    SCNTransaction.animationDuration =
        duration.map{ CFTimeInterval($0) }
            ?? SCNTransaction.animationDuration
    do {
        try operation()
    } catch {
        print("Cancelling transaction early:", error)
    }
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

public typealias Bounds = (min: SCNVector3, max: SCNVector3)
func BoundsWidth(_ bounds: Bounds) -> VectorFloat { bounds.max.x - bounds.min.x }
func BoundsHeight(_ bounds: Bounds) -> VectorFloat { bounds.max.y - bounds.min.y }
func BoundsLength(_ bounds: Bounds) -> VectorFloat { bounds.max.z - bounds.min.z }
func BoundsCenterWidth(_ bounds: Bounds) -> VectorFloat { BoundsWidth(bounds) / 2.0 + bounds.min.x }
func BoundsCenterHeight(_ bounds: Bounds) -> VectorFloat { BoundsHeight(bounds) / 2.0 + bounds.min.y }
func BoundsCenterLength(_ bounds: Bounds) -> VectorFloat { BoundsLength(bounds) / 2.0 + bounds.min.z }
func BoundsCenterPosition(_ bounds: Bounds) -> SCNVector3 {
    SCNVector3(
        x: BoundsCenterWidth(bounds),
        y: BoundsCenterHeight(bounds),
        z: BoundsCenterLength(bounds)
    )
}

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
    
    func pad(_ pad: VectorFloat) {
        minX -= pad
        minY -= pad
        minZ -= pad
        maxX += pad
        maxY += pad
    }
    
    var bounds: Bounds {
        return (
            min: SCNVector3(x: minX, y: minY, z: minZ),
            max: SCNVector3(x: maxX, y: maxY, z: maxZ)
        )
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

extension SCNVector3: Equatable {
    public static func == (_ l: Self, _ r: Self) -> Bool {
        return l.x == r.x
            && l.y == r.y
            && l.z == r.z
    }
}
