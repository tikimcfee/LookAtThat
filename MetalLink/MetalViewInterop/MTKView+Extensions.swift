//
//  MetalLinkMTKExtensions.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

extension MTKView {
    var defaultOrthographicProjection: simd_float4x4 {
        simd_float4x4(orthographicProjectionWithLeft: 0.0,
                      top: 0.0,
                      right: Float(drawableSize.width),
                      bottom: Float(drawableSize.height),
                      near: 0.0,
                      far: 1.0)
    }
}
