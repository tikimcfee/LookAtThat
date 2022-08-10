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
