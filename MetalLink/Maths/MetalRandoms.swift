//
//  MetalRandoms.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/10/22.
//

import simd

extension LFloat4 {
    static func random_color() -> LFloat4 {
        LFloat4(Float.random(in: 0..<1),
                Float.random(in: 0..<1),
                Float.random(in: 0..<1),
                1)
    }
}
