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

extension simd_float4x4 {
    init(orthographicProjectionWithLeft left: Float, top: Float, right: Float, bottom: Float, near: Float, far: Float) {
        let xs = 2 / (right - left)
        let ys = 2 / (top - bottom)
        let zs = 1 / (near - far)
        let tx = (left + right) / (left - right)
        let ty = (top + bottom) / (bottom - top)
        let tz = near / (near - far)
        self.init(columns: (simd_float4(xs,  0,  0, 0),
                            simd_float4( 0, ys,  0, 0),
                            simd_float4( 0,  0, zs, 0),
                            simd_float4(tx, ty, tz, 1)))
    }
}
