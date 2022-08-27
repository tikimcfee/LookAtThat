import Foundation
import SceneKit

public extension CGSize {
    var deviceScaled: CGSize {
        CGSize(width: width * DeviceScale.cg, height: height * DeviceScale.cg)
    }
}

func BoundsWidth(_ bounds: Bounds) -> VectorFloat { abs(bounds.max.x - bounds.min.x) }
func BoundsHeight(_ bounds: Bounds) -> VectorFloat { abs(bounds.max.y - bounds.min.y) }
func BoundsLength(_ bounds: Bounds) -> VectorFloat { abs(bounds.max.z - bounds.min.z) }

public typealias Bounds = (
    min: LFloat3,
    max: LFloat3
)

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
            return (min: .zero, max: .zero)
        }
        return (
            min: LFloat3(x: minX, y: minY, z: minZ),
            max: LFloat3(x: maxX, y: maxY, z: maxZ)
        )
    }
}

extension MetalLinkNode {

    func translate(dX: Float = 0,
                   dY: Float = 0,
                   dZ: Float = 0) {
        position.x += dX
        position.y += dY
        position.z += dZ
    }
    
    func translated(dX: Float = 0,
                    dY: Float = 0,
                    dZ: Float = 0) -> Self {
        position.x += dX
        position.y += dY
        position.z += dZ
        return self
    }
    
    func apply(_ modifier: @escaping (Self) -> Void) -> Self {
        laztrace(#fileID,#function,modifier)
        modifier(self)
        return self
    }
    
    @discardableResult
    func withDeviceScale() -> Self {
        scale = LFloat3(x: DeviceScale, y: DeviceScale, z: DeviceScale)
        return self
    }
    
    @discardableResult
    func withDeviceScaleInverse() -> Self {
        scale = LFloat3(x: DeviceScale, y: DeviceScale, z: DeviceScale)
        return self
    }
}

// MARK: -- Global Scaling Defaults --

let DeviceScaleEnabled = false // Disabled because of switch to root geometry global scaling
let DeviceScaleRootEnabled = true // Enabled by default to take advantage of global relative measurements within a node

#if os(iOS)
let DeviceScaleRoot = Float(0.001)
let DeviceScaleRootInverse = Float(1000.0)
let DeviceScale = DeviceScaleEnabled ? Float(0.001) : 1.0
let DeviceScaleInverse = DeviceScaleEnabled ? Float(1000.0) : 1.0
#elseif os(macOS)
let DeviceScaleRoot = Float(1.0)
let DeviceScaleRootInverse = Float(1.0)
let DeviceScale = Float(1.0)
let DeviceScaleInverse = Float(1.0)
#endif

let DeviceScaleUnitVector = LFloat3(x: 1.0, y: 1.0, z: 1.0)

let DeviceScaleVector = DeviceScaleEnabled
    ? LFloat3(x: DeviceScale, y: DeviceScale, z: DeviceScale)
    : DeviceScaleUnitVector

let DeviceScaleVectorInverse = DeviceScaleEnabled
    ? LFloat3(x: DeviceScaleInverse, y: DeviceScaleInverse, z: DeviceScaleInverse)
    : DeviceScaleUnitVector

let DeviceScaleRootVector = DeviceScaleRootEnabled
    ? LFloat3(x: DeviceScaleRoot, y: DeviceScaleRoot, z: DeviceScaleRoot)
    : DeviceScaleUnitVector
