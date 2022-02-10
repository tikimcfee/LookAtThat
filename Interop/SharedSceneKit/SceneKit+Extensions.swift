import Foundation
import SceneKit

//@inlinable
func lockedSceneTransaction(_ operation: () -> Void) {
    SCNTransaction.lock()
    SCNTransaction.begin()
    operation()
    SCNTransaction.commit()
    SCNTransaction.unlock()
}

//@inlinable
func sceneTransaction(
    _ duration: Int? = nil,
    _ timing: CAMediaTimingFunction? = nil,
    _ operation: () throws -> Void
) {
    SCNTransaction.begin()
    SCNTransaction.animationTimingFunction =  timing ?? SCNTransaction.animationTimingFunction
    SCNTransaction.animationDuration =
        duration.map { CFTimeInterval($0) }
            ?? SCNTransaction.animationDuration
    do {
        try operation()
    } catch {
        print("Cancelling transaction early:", error)
    }
    SCNTransaction.commit()
}

public extension SCNGeometry {
    var lengthX: VectorFloat { return abs(boundingBox.max.x - boundingBox.min.x) }
    var lengthY: VectorFloat { return abs(boundingBox.max.y - boundingBox.min.y) }
    var lengthZ: VectorFloat { return abs(boundingBox.max.z - boundingBox.min.z) }
    var centerX: VectorFloat { return boundingBox.min.x + lengthX / 2 }
    var centerY: VectorFloat { return boundingBox.min.y + lengthY / 2 }
    var centerZ: VectorFloat { return boundingBox.min.z + lengthZ / 2 }
    var centerPosition: SCNVector3 { return SCNVector3(x: centerX, y: centerY, z: centerZ) }

    func deepCopy() -> SCNGeometry {
        let clone = copy() as! SCNGeometry
        clone.materials = materials.map{ $0.copy() as! SCNMaterial }
        return clone
    }
}

public extension CGSize {
    var deviceScaled: CGSize {
        CGSize(width: width * DeviceScale.cg, height: height * DeviceScale.cg)
    }
}

func BoundsWidth(_ bounds: Bounds) -> VectorFloat { abs(bounds.max.x - bounds.min.x) }
func BoundsHeight(_ bounds: Bounds) -> VectorFloat { abs(bounds.max.y - bounds.min.y) }
func BoundsLength(_ bounds: Bounds) -> VectorFloat { abs(bounds.max.z - bounds.min.z) }

extension SCNNode {
    var boundsWidth: VectorFloat { abs(manualBoundingBox.max.x - manualBoundingBox.min.x) }
    var boundsHeight: VectorFloat { abs(manualBoundingBox.max.y - manualBoundingBox.min.y) }
    var boundsLength: VectorFloat { abs(manualBoundingBox.max.z - manualBoundingBox.min.z) }
    
    var boundsCenterWidth: VectorFloat { boundsWidth / 2.0 + manualBoundingBox.min.x }
    var boundsCenterHeight: VectorFloat { boundsHeight / 2.0 + manualBoundingBox.min.y }
    var boundsCenterLength: VectorFloat { boundsLength / 2.0 + manualBoundingBox.min.z }
    
    var boundsCenterPosition: SCNVector3 {
        let vector = SCNVector3(
            x: boundsCenterWidth,
            y: boundsCenterHeight,
            z: boundsCenterLength
        )
        return convertPosition(vector, to: parent)
    }
}

public typealias Bounds = (min: SCNVector3, max: SCNVector3)
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
        maxZ += pad
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

extension SCNNode {

    func translate(dX: VectorFloat = 0,
                   dY: VectorFloat = 0,
                   dZ: VectorFloat = 0) {
        position.x += dX
        position.y += dY
        position.z += dZ
    }
    
    func materialMultiply(_ any: Any?) {
        geometry?.firstMaterial?.multiply.contents = any
    }
    
    func simdTranslate(dX: VectorFloat = 0, dY: VectorFloat = 0, dZ: VectorFloat = 0) {
        simdPosition += simdWorldRight * Float(dX)
        simdPosition += simdWorldUp * Float(dY)
        simdPosition += simdWorldFront * Float(dZ)
    }
    
    func apply(_ modifier: @escaping (SCNNode) -> Void) -> SCNNode {
        laztrace(#fileID,#function,modifier)
        modifier(self)
        return self
    }
    
    @discardableResult
    func addingChild(_ child: CodeGrid) -> SCNNode {
        addChildNode(child.rootNode)
        return self
    }
    
    @discardableResult
    func addingChild(_ child: SCNNode) -> SCNNode {
        addChildNode(child)
        return self
    }
    
    @discardableResult
    func withDeviceScale() -> SCNNode {
        scale = SCNVector3(x: DeviceScale, y: DeviceScale, z: DeviceScale)
        return self
    }
    
    @discardableResult
    func withDeviceScaleInverse() -> SCNNode {
        scale = SCNVector3(x: DeviceScaleInverse, y: DeviceScaleInverse, z: DeviceScaleInverse)
        return self
    }
}

#if os(iOS)
let DeviceScale = VectorFloat(0.001)
let DeviceScaleInverse = VectorFloat(1000.0)
#elseif os(macOS)
let DeviceScale = 1.0
let DeviceScaleInverse = 1.0
#endif
