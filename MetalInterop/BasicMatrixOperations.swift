//
//  BasicMatrixOperations.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/11/22.
//
import simd

extension float4x4 {
    init(scaleBy s: Float) {
        self.init(float4(s, 0, 0, 0),
                  float4(0, s, 0, 0),
                  float4(0, 0, s, 0),
                  float4(0, 0, 0, 1))
    }
    
    init(rotationAbout axis: float3, by angleRadians: Float) {
        let x = axis.x, y = axis.y, z = axis.z
        let c = cosf(angleRadians)
        let s = sinf(angleRadians)
        let t = 1 - c
        self.init(float4( t * x * x + c,     t * x * y + z * s, t * x * z - y * s, 0),
                  float4( t * x * y - z * s, t * y * y + c,     t * y * z + x * s, 0),
                  float4( t * x * z + y * s, t * y * z - x * s,     t * z * z + c, 0),
                  float4(                 0,                 0,                 0, 1))
    }
    
    init(translationBy t: float3) {
        self.init(float4(   1,    0,    0, 0),
                  float4(   0,    1,    0, 0),
                  float4(   0,    0,    1, 0),
                  float4(t[0], t[1], t[2], 1))
    }
    
    init(perspectiveProjectionFov fovRadians: Float, aspectRatio aspect: Float, nearZ: Float, farZ: Float) {
        let yScale = 1 / tan(fovRadians * 0.5)
        let xScale = yScale / aspect
        let zRange = farZ - nearZ
        let zScale = -(farZ + nearZ) / zRange
        let wzScale = -2 * farZ * nearZ / zRange
        
        let xx = xScale
        let yy = yScale
        let zz = zScale
        let zw = Float(-1)
        let wz = wzScale
        
        self.init(float4(xx,  0,  0,  0),
                  float4( 0, yy,  0,  0),
                  float4( 0,  0, zz, zw),
                  float4( 0,  0, wz,  0))
    }
}

//import simd
//
////private typealias SIMD4<Float> = SIMD4<Float>
//
//extension float4x4 {
//    init(scaleBy s: Float) {
//        self.init(SIMD4<Float>(s, 0, 0, 0),
//                  SIMD4<Float>(0, s, 0, 0),
//                  SIMD4<Float>(0, 0, s, 0),
//                  SIMD4<Float>(0, 0, 0, 1))
//    }
//
//    init(rotationAbout axis: SIMD3<Float>,
//         by angleRadians: Float) {
//        let x = axis.x, y = axis.y, z = axis.z
//        let c = cosf(angleRadians)
//        let s = sinf(angleRadians)
//        let t = 1 - c
//        self.init(SIMD4<Float>( t * x * x + c,     t * x * y + z * s, t * x * z - y * s, 0),
//                  SIMD4<Float>( t * x * y - z * s, t * y * y + c,     t * y * z + x * s, 0),
//                  SIMD4<Float>( t * x * z + y * s, t * y * z - x * s,     t * z * z + c, 0),
//                  SIMD4<Float>(                 0,                 0,                 0, 1))
//    }
//
//    init(translationBy t: SIMD3<Float>) {
//        self.init(SIMD4<Float>(   1,    0,    0, 0),
//                  SIMD4<Float>(   0,    1,    0, 0),
//                  SIMD4<Float>(   0,    0,    1, 0),
//                  SIMD4<Float>(t[0], t[1], t[2], 1))
//    }
//
//    init(perspectiveProjectionFov fovRadians: Float,
//         aspectRatio aspect: Float,
//         nearZ: Float,
//         farZ: Float) {
//        let yScale = 1 / tan(fovRadians * 0.5)
//        let xScale = yScale / aspect
//        let zRange = farZ - nearZ
//        let zScale = -(farZ + nearZ) / zRange
//        let wzScale = -2 * farZ * nearZ / zRange
//
//        let xx = xScale
//        let yy = yScale
//        let zz = zScale
//        let zw = Float(-1)
//        let wz = wzScale
//
//        self.init(SIMD4<Float>(xx,  0,  0,  0),
//                  SIMD4<Float>( 0, yy,  0,  0),
//                  SIMD4<Float>( 0,  0, zz, zw),
//                  SIMD4<Float>( 0,  0, wz,  0))
//    }
//}
