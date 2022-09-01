import Foundation
import SceneKit

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
