//
//  MetalLinkExtensions.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/13/22.
//

import MetalKit

extension MTLTexture {
    var simdSize: LFloat2 {
        LFloat2(Float(width), Float(height))
    }
}

struct UnitSize {
    static func from(_ source: LFloat2) -> LFloat2 {
        let unitWidth = 1 / source.x
        let unitHeight = 1 / source.y
        return LFloat2(min(source.x * unitHeight, 1),
                       min(source.y * unitWidth, 1))
    }
}

extension LFloat2 {
    var coordString: String { "(\(x), \(y))" }
}
