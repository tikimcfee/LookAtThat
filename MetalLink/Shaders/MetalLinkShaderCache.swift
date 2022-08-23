//
//  ShaderLibrary.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

class MetalLinkShaderCache {
    let link: MetalLink
    private lazy var shaderFunctionCache = ShaderFunctionCache(link)
    
    init (link: MetalLink) {
        self.link = link
    }
    
    subscript(_ vertexType: MetalLinkShaderType) -> MTLFunction {
        shaderFunctionCache[vertexType]
    }
}

private class ShaderFunctionCache: LockingCache<MetalLinkShaderType, MTLFunction> {
    let link: MetalLink
    
    init(_ link: MetalLink) {
        self.link = link
        super.init()
    }
    
    override func make(_ key: Key, _ store: inout [Key : Value]) -> Value {
        key.getFunction(link)
    }
}
