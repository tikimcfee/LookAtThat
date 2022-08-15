//
//  MetalLinkModels.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/8/22.
//

import simd

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

extension MetalLinkInstancedObject {
    struct InstancedConstants: MemoryLayoutSizable {
        var modelMatrix = matrix_identity_float4x4
        
        var textureDescriptorU = LFloat4.zero
        var textureDescriptorV = LFloat4.zero
    }
    
    class State {
        var time: Float = 0
    }
}

extension MetalLinkObject {
    struct Constants: MemoryLayoutSizable {
        var modelMatrix = matrix_identity_float4x4
        var color = LFloat4.zero;
        var textureIndex = TextureIndex.zero;
    }
    
    class State {
        var time: Float = 0
    }
}

// MARK: - Extensions

extension Vertex {
    var positionString: String {
        "(\(position.x), \(position.y), \(position.z))"
    }
}
