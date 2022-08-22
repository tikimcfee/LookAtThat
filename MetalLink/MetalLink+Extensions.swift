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

extension MTLBuffer {
    func boundPointer<T>(as type: T.Type, count: Int) -> UnsafeMutablePointer<T> {
        contents().bindMemory(to: type.self, capacity: count)
    }
}

extension MetalLink {
    func makeBuffer<T: MemoryLayoutSizable>(
        of type: T.Type, count: Int
    ) throws -> MTLBuffer {
        guard let buffer = device.makeBuffer(
            length: type.memStride(of: count),
            options: []
        ) else { throw CoreError.noBufferAvailable }
        buffer.label = String(describing: type)
        return buffer
    }
}
