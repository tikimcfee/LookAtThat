//
//  MetalLinkModels.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/8/22.
//

import simd
import Metal

struct Vertex {
    var position: LFloat3
    var uvTextureIndex: TextureIndex /* (left, top, width, height) */
}

struct SceneConstants: MemoryLayoutSizable {
    var totalTotalGameTime = Float.zero
    var viewMatrix = matrix_identity_float4x4
    var projectionMatrix = matrix_identity_float4x4
    var pointerMatrix = matrix_identity_float4x4
}

struct InstancedConstants: MemoryLayoutSizable, BackingIndexed {
    var modelMatrix = matrix_identity_float4x4
    var textureDescriptorU = LFloat4.zero
    var textureDescriptorV = LFloat4.zero
    
    var instanceID: InstanceIDType = .zero
    var addedColor: LFloat4 = .zero
    var parentIndex: UInt = .zero
    var bufferIndex: UInt = .zero
    
    mutating func reset() {
        self = InstancedConstants()
    }
}

extension MetalLinkInstancedObject {
    class State {
        var time: Float = 0
    }
}

struct Constants: MemoryLayoutSizable {
    var modelMatrix = matrix_identity_float4x4
    var color = LFloat4.zero;
    var textureIndex = TextureIndex.zero;
}

extension MetalLinkObject {
    class State {
        var time: Float = 0
    }
}

struct ParentConstants: MemoryLayoutSizable {
    let modelMatrix = matrix_identity_float4x4
}

// MARK: - Extensions

extension Vertex {
    var positionString: String {
        "(\(position.x), \(position.y), \(position.z))"
    }
}
