//
//  CubeCollection.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/10/22.
//

import MetalKit

// ----------------------------------


class CubeCollection: MetalLinkInstancedObject {
    let size: SIMD3<Int>
    
    init(link: MetalLink, size: SIMD3<Int>) throws {
        self.size = size
        try super.init(link, mesh: link.meshes[.Cube], initialCount: size.volume)
        setupNodes()
    }
    
    func setupNodes() {
        let sX = Float(size.x)
        let sY = Float(size.y)
        let sZ = Float(size.z)
        let halfX = sX / 2
        let halfY = sY / 2
        let halfZ = sZ / 2
        
        var index = 0
        let count = instancedNodes.count
        
        setColor(LFloat4(0.34, 0.11, 0.22, 1.0))
        
        for x in stride(from: -halfX, to: halfX, by: 1.0) {
            for y in stride(from: -halfY, to: halfY, by: 1.0) {
                for z in stride(from: -halfZ, to: halfZ, by: 1.0) {
                    if index >= count { return }
                    instancedConstants[index].color = LFloat4(
                        (z+halfZ) / sZ,
                        (y+halfY) / sY,
                        (x+halfX) / sX,
                        1
                    )
                    instancedNodes[index].position = LFloat3(x, y, z)
                    instancedNodes[index].scale = LFloat3(repeating: 3.0 / Float(size.x))
                    index += 1
                }
            }
        }
    }
    
    private var _time: Float = 0
    private func time(_ dT: Float) -> Float { _time += dT; return _time }
    
    override func update(deltaTime dT: Float) {
//        let halfX = Float(size.x / 2)
//        let halfY = Float(size.y / 2)
//        let halfZ = Float(size.z / 2)
//        
//        var index = 0
//        let count = instancedNodes.count
//        
//        for x in stride(from: -halfX, to: halfX, by: 1.0) {
//            for y in stride(from: -halfY, to: halfY, by: 1.0) {
//                for z in stride(from: -halfZ, to: halfZ, by: 1.0) {
//                    if index >= count { return }
//                    instancedNodes[index].rotation.x -= dT * 2
//                    instancedNodes[index].rotation.y -= dT * 2
//                    index += 1
//                }
//            }
//        }
        
        rotation.x -= dT / 2
        rotation.y -= dT / 2
        
        rebuildBuffer = true
        super.update(deltaTime: dT)
    }
    
    override func performJITInstanceBufferUpdate(_ node: MetalLinkNode) {
        node.rotation.x -= 0.0167 * 2
        node.rotation.y -= 0.0167 * 2
    }
}
