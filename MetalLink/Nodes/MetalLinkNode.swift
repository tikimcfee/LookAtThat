//
//  MetalLinkNode.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/7/22.
//

import MetalKit

class MetalLinkNode {
    private lazy var currentModel = matrix_cached_float4x4(update: self.buildModelMatrix)
    
    var children: [MetalLinkNode] = []
    
    var position: LFloat3 = .zero
        { didSet { currentModel.dirty() } }
    
    var scale: LFloat3 = LFloat3(1.0, 1.0, 1.0)
        { didSet { currentModel.dirty() } }
    
    var rotation: LFloat3 = .zero
        { didSet { currentModel.dirty() } }
    
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
        currentModel.get()
    }
    
    private func buildModelMatrix() -> matrix_float4x4 {
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

struct matrix_cached_float4x4 {
    private(set) var rebuildModel = true // implicit rebuild on first call
    private(set) var currentModel = matrix_identity_float4x4
    
    let update: () -> matrix_float4x4
    
    mutating func dirty() { rebuildModel = true }
    
    mutating func get() -> matrix_float4x4 {
        guard rebuildModel else { return currentModel }
        rebuildModel = false
        currentModel = update()
        return currentModel
    }
}

struct Cached<T> {
    private(set) var rebuildModel = true // implicit rebuild on first call
    var current: T
    
    let update: () -> T
    
    mutating func dirty() { rebuildModel = true }
    
    mutating func get() -> T {
        guard rebuildModel else { return current }
        rebuildModel = false
        current = update()
        return current
    }
}
