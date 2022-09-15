//
//  MetalLinkModels.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/8/22.
//

import simd
import Metal

// MARK: - Bridging header extensions

// TODO: Find a nice way to push this into bridging header
struct Vertex {
    var position: LFloat3
    var uvTextureIndex: TextureIndex /* (left, top, width, height) */
}

extension SceneConstants: MemoryLayoutSizable { }

extension BasicModelConstants: MemoryLayoutSizable { }

extension VirtualParentConstants: MemoryLayoutSizable, BackingIndexed {
    mutating func reset() {
        modelMatrix = matrix_identity_float4x4
        bufferIndex = .zero
    }
}

extension InstancedConstants: MemoryLayoutSizable, BackingIndexed {
    mutating func reset() {
        modelMatrix = matrix_identity_float4x4
        textureDescriptorU = .zero
        textureDescriptorV = .zero
        instanceID = .zero
        addedColor = .zero
        parentIndex = .zero
        bufferIndex = .zero
    }
}

// MARK: - Extensions

extension Vertex {
    var positionString: String {
        "(\(position.x), \(position.y), \(position.z))"
    }
}

extension MetalLinkInstancedObject {
    class State {
        var time: Float = 0
    }
}

extension MetalLinkObject {
    class State {
        var time: Float = 0
    }
}
