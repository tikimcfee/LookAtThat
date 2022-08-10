//
//  CubeNode.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/9/22.
//

import MetalKit

func randomFloat(_ range: Range<Float> = (0..<1)) -> Float { Float.random(in: range) }

class CubeNode: MetalLinkObject {
    init(link: MetalLink) throws {
        try super.init(link, mesh: link.meshes[.Cube])
    }
    
    private var _time: Float = 0
    private func time(_ dT: Float) -> Float { _time += dT; return _time }
    override func update(deltaTime dT: Float) {
//        rotation = LFloat3(cos(time(dT)),
//                           sin(time(dT)),
//                           1)
        super.update(deltaTime: dT)
    }
}

// ----------------------------------

private extension SIMD3 where Scalar == Int {
    var volume: Int { x * y * z }
}

class CubeCollection: MetalLinkInstancedObject {
    let size: SIMD3<Int>
    
    init(link: MetalLink, size: SIMD3<Int>) throws {
        self.size = size
        try super.init(link, mesh: link.meshes[.Cube], initialCount: size.volume)
        setupNodes()
    }
    
    func setupNodes() {
        let halfX = Float(size.x / 2)
        let halfY = Float(size.y / 2)
        let halfZ = Float(size.z / 2)
        
        var index = 0
        let count = instances.count
        
        setColor(LFloat4(0.34, 0.11, 0.22, 1.0))
        
        for x in stride(from: -halfX, to: halfX, by: 1.0) {
            for y in stride(from: -halfY, to: halfY, by: 1.0) {
                for z in stride(from: -halfZ, to: halfZ, by: 1.0) {
                    if index >= count { return }
                    instances[index].position = LFloat3(x, y, z)
                    instances[index].scale = LFloat3(repeating: 1.0 / Float(size.x + 3))
                    index += 1
                }
            }
        }
    }
    
    private var _time: Float = 0
    private func time(_ dT: Float) -> Float { _time += dT; return _time }
    
    override func update(deltaTime dT: Float) {
        let halfX = Float(size.x / 2)
        let halfY = Float(size.y / 2)
        let halfZ = Float(size.z / 2)
        
        var index = 0
        let count = instances.count
        
        for x in stride(from: -halfX, to: halfX, by: 1.0) {
            for y in stride(from: -halfY, to: halfY, by: 1.0) {
                for z in stride(from: -halfZ, to: halfZ, by: 1.0) {
                    if index >= count { return }
                    instances[index].rotation.x -= dT * 2
                    instances[index].rotation.y -= dT * 2
                    index += 1
                }
            }
        }
        super.update(deltaTime: dT)
    }
}
