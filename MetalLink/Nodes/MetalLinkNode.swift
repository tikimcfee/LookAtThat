//
//  MetalLinkNode.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/7/22.
//

import MetalKit

class MetalLinkNode {
    var position: LFloat3 = .zero
    var scale: LFloat3 = LFloat3(1.0, 1.0, 1.0)
    var rotation: LFloat3 = .zero
    
    var children: [MetalLinkNode] = []
    
    func render(in sdp: inout SafeDrawPass) {
        children.forEach { $0.render(in: &sdp) }
        asRenderable?.doRender(in: &sdp)
    }
    
    func update(deltaTime: Float) {
        children.forEach { $0.update(deltaTime: deltaTime) }
    }
}

extension MetalLinkNode {
    func add(child: MetalLinkNode) {
        children.append(child)
    }
}

extension MetalLinkNode {
    var modelMatrix: matrix_float4x4 {
        // This is expensive.
        var matrix = matrix_identity_float4x4
        matrix.translate(vector: position)
        matrix.rotateAbout(axis: X_AXIS, by: rotation.x)
        matrix.rotateAbout(axis: Y_AXIS, by: rotation.y)
        matrix.rotateAbout(axis: Z_AXIS, by: rotation.z)
        matrix.scale(amount: scale)
        return matrix
    }
}

private extension MetalLinkNode {
    var asRenderable: MetalLinkRenderable? {
        self as? MetalLinkRenderable
    }
}
