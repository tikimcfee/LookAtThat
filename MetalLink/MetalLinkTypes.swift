//
//  MetalLinkTypes.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import Foundation

struct Vertex {
    var position: LFloat3
    var color: LFloat4
    var textureCoordinate: LFloat2 = .zero
}

typealias LFloat2 = SIMD2<Float>
typealias LFloat3 = SIMD3<Float>
typealias LFloat4 = SIMD4<Float>
