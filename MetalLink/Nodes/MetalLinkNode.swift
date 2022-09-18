//
//  MetalLinkNode.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/7/22.
//

import MetalKit

class MetalLinkNode: Measures {
    
    private lazy var currentModel = matrix_cached_float4x4(update: self.buildModelMatrix)
    lazy var nodeId = UUID().uuidString
    
    var parent: MetalLinkNode?
        { didSet { setDirty(includeChildren: true) } }
    
    var children: [MetalLinkNode] = []
        { didSet { setDirty(includeChildren: true) } }
    
    // MARK: - Model params
    
    var position: LFloat3 = .zero
        { didSet { setDirty(includeChildren: true) } }
    
    var scale: LFloat3 = LFloat3(1.0, 1.0, 1.0)
        { didSet { setDirty(includeChildren: true) } }
    
    var rotation: LFloat3 = .zero
        { didSet { setDirty(includeChildren: true) } }
    
    // MARK: - Overridable Measures
    
    var hasIntrinsicSize: Bool { false }
    var contentSize: LFloat3 { .zero }
    var contentOffset: LFloat3 { .zero }
    
    // MARK: Bounds / Position
    
    var bounds: Bounds {
//        let bounds = BoundsCaching.getOrUpdate(self)
//        return bounds
        return computeBoundingBox()
    }

//    var rectPos: Bounds {
//        return computeBoundingBox(convertParent: false)
//    }
    
    var lengthX: VectorFloat {
        let box = bounds
        return abs(box.max.x - box.min.x)
    }
    
    var lengthY: VectorFloat {
        let box = bounds
        return abs(box.max.y - box.min.y)
    }
    
    var lengthZ: VectorFloat {
        let box = bounds
        return abs(box.max.z - box.min.z)
    }
    
    var centerX: VectorFloat {
        let box = bounds
        return lengthX / 2.0 + box.min.x
    }
    
    var centerY: VectorFloat {
        let box = bounds
        return lengthY / 2.0 + box.min.y
    }
    
    var centerZ: VectorFloat {
        let box = bounds
        return lengthZ / 2.0 + box.min.z
    }
    
    var centerPosition: LFloat3 {
        return LFloat3(x: centerX, y: centerY, z: centerZ)
    }
    
    // MARK: Rendering
    
    func render(in sdp: inout SafeDrawPass) {
        for child in children {
            child.render(in: &sdp)
        }
        asRenderable?.doRender(in: &sdp)
    }
    
    func update(deltaTime: Float) {
        children.forEach { $0.update(deltaTime: deltaTime) }
    }
    
    // MARK: Children
    
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
    
    func attachBufferChanges(_ onChange: @escaping (matrix_float4x4) -> Void) {
        let existing = currentModel.update
        currentModel.update = {
            let result = existing()
            onChange(result)
            return result
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
    var willUpdate: Bool { currentModel.rebuildModel }
    
    func setDirty(includeChildren: Bool = false) {
//        BoundsCaching.ClearRoot(self)
        currentModel.dirty()
        guard includeChildren else { return }
        children.forEach { $0.setDirty() }
    }
    
    var modelMatrix: matrix_float4x4 {
        var matrix = currentModel.get()
        if let parentMatrix = parent?.modelMatrix {
            matrix = matrix_multiply(parentMatrix, matrix)
        }
        return matrix
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
    
    var update: () -> matrix_float4x4
    
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
