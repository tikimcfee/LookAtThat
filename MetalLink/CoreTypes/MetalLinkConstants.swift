//
//  MetalLinkModels.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/8/22.
//

import simd

struct SceneConstants: MemoryLayoutSizable {
    var viewMatrix = matrix_identity_float4x4
    var projectionMatrix = matrix_identity_float4x4
    var pointerMatrix = matrix_identity_float4x4
}
