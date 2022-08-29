//
//  MetalLinkNode.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/7/22.
//

import MetalKit

class MetalLinkNode {
    private lazy var currentModel = matrix_cached_float4x4(update: self.buildModelMatrix)
    lazy var nodeId = UUID().uuidString
    
    var parent: MetalLinkNode?
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
    
    func add(child: MetalLinkNode) {
        children.append(child)
        if let parent = child.parent {
            print("[\(nodeId)] parent already set to [\(parent.nodeId)]")
        }
        child.parent = self
    }
    
    func enumerateChildren(_ action: (MetalLinkNode) -> Void) {
        for child in children {
            action(child)
            child.enumerateChildren(action)
        }
    }
}

extension MetalLinkNode: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(nodeId)
//        hasher.combine(position)
//        hasher.combine(rotation)
//        hasher.combine(scale)
    }
    
    static func == (_ left: MetalLinkNode, _ right: MetalLinkNode) -> Bool {
        return left.nodeId == right.nodeId
//            && left.position == right.position
//            && left.rotation == right.rotation
//            && left.scale == right.scale
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

class Cached<T> {
    private(set) var builtInitial = false
    private(set) var willRebuild = true   // implicit rebuild on first call
    private var current: T
    var update: () -> T
    
    init(current: T, update: @escaping () -> T) {
        self.current = current
        self.update = update
    }
    
    func dirty() { willRebuild = true }

    func get() -> T {
        guard willRebuild else { return current }
        builtInitial = true
        willRebuild = false
        current = update()
        return current
    }
}
