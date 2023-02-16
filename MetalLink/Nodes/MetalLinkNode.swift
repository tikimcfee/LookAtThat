//
//  MetalLinkNode.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/7/22.
//

import MetalKit
import Combine

class ObservableMatrix: ObservableObject {
    typealias ModelMatrix = matrix_float4x4
    typealias Publisher = AnyPublisher<ObservableMatrix.ModelMatrix, Never>
    
    @Published var matrix: ModelMatrix = matrix_identity_float4x4
    lazy var sharedObservable: Publisher = $matrix.share().eraseToAnyPublisher()
}

class MetalLinkNode: Measures {
    
    private let currentModel = ObservableMatrix()
    lazy var eventBag = Set<AnyCancellable>()
    var modelEvents: ObservableMatrix.Publisher {
        currentModel.sharedObservable
    }
    
    lazy var nodeId = UUID().uuidString

    var parent: MetalLinkNode?
        { didSet { rebuildModelMatrix(includeChildren: true) } }
    
    var children: [MetalLinkNode] = []
        { didSet { rebuildModelMatrix(includeChildren: true) } }
    
    // MARK: - Model params
    
    var position: LFloat3 = .zero
        { didSet {
            rebuildModelMatrix(includeChildren: true)
        } }
    
    var scale: LFloat3 = LFloat3(1.0, 1.0, 1.0)
        { didSet {
            rebuildModelMatrix(includeChildren: true)
            BoundsCaching.Set(self, nil)
        } }
    
    var rotation: LFloat3 = .zero
        { didSet {
            rebuildModelMatrix(includeChildren: true)
        } }
    
    // MARK: - Overridable Measures
    
    var hasIntrinsicSize: Bool { false }
    var contentSize: LFloat3 { .zero }
    var contentOffset: LFloat3 { .zero }
    
    // MARK: Bounds / Position
    
    var bounds: Bounds {
        let rectPos = rectPos
        return (
            min: rectPos.min + position,
            max: rectPos.max + position
        )
    }

    var rectPos: Bounds {
        if let cached = BoundsCaching.get(self) { return cached }
        let box = computeBoundingBox(convertParent: true)
        BoundsCaching.Set(self, box)
        return box
    }
    
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
            print("[\(child.nodeId)] parent already set to [\(parent.nodeId)]")
        }
        child.parent = self
    }
    
    func remove(child: MetalLinkNode) {
        children.removeAll(where: { $0.nodeId == child.nodeId })
        child.parent = nil
    }
    
    func enumerateChildren(_ action: (MetalLinkNode) -> Void) {
        for child in children {
            action(child)
            child.enumerateChildren(action)
        }
    }
    
    func bindToModelEvents(_ action: @escaping (ObservableMatrix.ModelMatrix) -> Void) {
        modelEvents.sink {
            action($0)
        }
        .store(in: &eventBag)
    }
    
    func bindAsVirtualParentOf(_ node: MetalLinkNode) {
        modelEvents.sink { _ in
            node.rebuildModelMatrix()
        }
        .store(in: &eventBag)
    }
}

extension MetalLinkNode: Hashable, Equatable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(nodeId)
    }
    
    static func == (_ left: MetalLinkNode, _ right: MetalLinkNode) -> Bool {
        return left.nodeId == right.nodeId
    }
}

extension MetalLinkNode {
    func rebuildModelMatrix(includeChildren: Bool = false) {
        currentModel.matrix = buildModelMatrix()
    }
    
    var modelMatrix: matrix_float4x4 {
        // ***********************************************************************************
        // TODO: build matrix hack
        // I've lost sight of exactly how the rebuild process works. When modelMatrix is called,
        // it causes a parent matrix calculation storm all the way to the hierarchy. We want that,
        // but it's expensive.
        //
        // The new currenModel() thing is a fine change in terms of cleanliness, but it's not
        // what I intended. I had hoped I could hook in to an immediate parent and update from it.
        // That's kinda happening, except it really only effects the virtual buffer update which
        // points into it directly from CodeGrid. I want to replace that with a direct sync to the
        // buffer on the collection. This means that observers get updates (the node parent buffer),
        // and Node.modelMatrix can be called at any time to get the same computation. The trick is
        // the observable doesn't always hold the latest value because.. bad code.
        //
        // How do I fix the buildModelMatrix() problem? Do I just leave it for now and wait for
        // performance problems again? Probably. Feels like I'm too tired to come up with more
        // clever stuff, and this whole thing is on the verge of being abandoned anyway. I just
        // want to see stuff in space to help my brain understand things. I guess if I had tried
        // harder earlier to learn the fundamentals with tools that hide this stuff I'd be better off.
        // But this whole thing kept me fascinated, but that is starting to die down to a slog.
        // It's fun but.. I hope it lasts.
        //
        // ... anyway. Matrices.
        // ***********************************************************************************
        return buildModelMatrix()
        
//        return currentModel.matrix
        
//        var matrix = currentModel.matrix
//        if let parentMatrix = parent?.modelMatrix {
//            matrix = matrix_multiply(parentMatrix, matrix)
//        }
//        return matrix
    }
    
    private func buildModelMatrix() -> matrix_float4x4 {
        // This is expensive.
        var matrix = matrix_identity_float4x4
        matrix.translate(vector: position)
        matrix.rotateAbout(axis: X_AXIS, by: rotation.x)
        matrix.rotateAbout(axis: Y_AXIS, by: rotation.y)
        matrix.rotateAbout(axis: Z_AXIS, by: rotation.z)
        matrix.scale(amount: scale)
        if let parentMatrix = parent?.modelMatrix {
            matrix = matrix_multiply(parentMatrix, matrix)
        }
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
