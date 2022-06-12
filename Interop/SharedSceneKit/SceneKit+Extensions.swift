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
func sceneTransactionSafe<T>(
    _ duration: Double? = nil,
    _ timing: CAMediaTimingFunctionName? = nil,
    _ operation: () -> T
) -> T {
    SCNTransaction.begin()
    
    SCNTransaction.animationTimingFunction =
        timing.map { CAMediaTimingFunction(name: $0) }
            ?? SCNTransaction.animationTimingFunction
    
    SCNTransaction.animationDuration =
        duration.map { CFTimeInterval($0) }
            ?? SCNTransaction.animationDuration
    
    let result = operation()
    
    SCNTransaction.commit()
    
    return result
}

func sceneTransaction(
    _ duration: Double? = nil,
    _ timing: CAMediaTimingFunctionName? = nil,
    _ operation: () throws -> Void
) {
    SCNTransaction.begin()
    
    SCNTransaction.animationTimingFunction =
    timing.map { CAMediaTimingFunction(name: $0) }
    ?? SCNTransaction.animationTimingFunction
    
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
    
    func bounds(convertedTo requestParent: SCNNode?) -> Bounds {
        let minVector = convertPosition(manualBoundingBox.min, to: requestParent)
        let maxVector = convertPosition(manualBoundingBox.max, to: requestParent)
        return (minVector, maxVector)
    }
    
    var boundsInParent: Bounds {
        let minVector = convertPosition(manualBoundingBox.min, to: parent)
        let maxVector = convertPosition(manualBoundingBox.max, to: parent)
        return (minVector, maxVector)
    }
    
    var boundsInWorld: Bounds {
        let minVector = convertPosition(manualBoundingBox.min, to: nil)
        let maxVector = convertPosition(manualBoundingBox.max, to: nil)
        return (minVector, maxVector)
    }
}

public typealias Bounds = (min: SCNVector3, max: SCNVector3)

class BoundsComputing {
    var didSetInitial: Bool = false
    var minX: VectorFloat = .infinity
    var minY: VectorFloat = .infinity
    var minZ: VectorFloat = .infinity
    
    var maxX: VectorFloat = -.infinity
    var maxY: VectorFloat = -.infinity
    var maxZ: VectorFloat = -.infinity
    
    func consumeBounds(_ bounds: Bounds) {
        didSetInitial = true
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
        guard didSetInitial else {
            print("Bounds were never set; returning safe default")
            return (min: SCNVector3Zero, max: SCNVector3Zero)
        }
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
    
    func translated(dX: VectorFloat = 0,
                    dY: VectorFloat = 0,
                    dZ: VectorFloat = 0) -> Self {
        position.x += dX
        position.y += dY
        position.z += dZ
        return self
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

// MARK: -- Global Scaling Defaults --

let DeviceScaleEnabled = false // Disabled because of switch to root geometry global scaling
let DeviceScaleRootEnabled = true // Enabled by default to take advantage of global relative measurements within a node

#if os(iOS)
let DeviceScaleRoot = VectorFloat(0.001)
let DeviceScaleRootInverse = VectorFloat(1000.0)
let DeviceScale = DeviceScaleEnabled ? VectorFloat(0.001) : 1.0
let DeviceScaleInverse = DeviceScaleEnabled ? VectorFloat(1000.0) : 1.0
#elseif os(macOS)
let DeviceScaleRoot = 1.0
let DeviceScaleRootInverse = 1.0
let DeviceScale = 1.0
let DeviceScaleInverse = 1.0
#endif

let DeviceScaleUnitVector = SCNVector3(x: 1.0, y: 1.0, z: 1.0)

let DeviceScaleVector = DeviceScaleEnabled
    ? SCNVector3(x: DeviceScale, y: DeviceScale, z: DeviceScale)
    : DeviceScaleUnitVector

let DeviceScaleVectorInverse = DeviceScaleEnabled
    ? SCNVector3(x: DeviceScaleInverse, y: DeviceScaleInverse, z: DeviceScaleInverse)
    : DeviceScaleUnitVector

let DeviceScaleRootVector = DeviceScaleRootEnabled
    ? SCNVector3(x: DeviceScaleRoot, y: DeviceScaleRoot, z: DeviceScaleRoot)
    : DeviceScaleUnitVector
