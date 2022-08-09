//
//  MetalLinkMemory.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import simd

protocol MemoryLayoutSizable {
    static func memSize(of count: Int) -> Int
    static func memStride(of count: Int) -> Int
}

extension MemoryLayoutSizable {
    static var memSize: Int {
        MemoryLayout<Self>.size
    }
    
    static var memStride: Int {
        MemoryLayout<Self>.stride
    }
}

extension MemoryLayoutSizable {
    static func memSize(of count: Int) -> Int {
        memSize * count
    }
    
    static func memStride(of count: Int) -> Int {
        memStride * count
    }
}

extension LFloat3: MemoryLayoutSizable { }
extension LFloat4: MemoryLayoutSizable { }
extension Float: MemoryLayoutSizable { }
extension Int: MemoryLayoutSizable { }
extension Vertex: MemoryLayoutSizable { }
