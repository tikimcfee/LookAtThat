//
//  ShaderLibrary.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

class ShaderLibrary {
    private lazy var vertexShaders = VertexShadersCache(link)
    private lazy var fragmentShaders = FragmentShadersCache(link)
    
    let link: MetalLink
    init (link: MetalLink) {
        self.link = link
    }
    
    subscript(_ vertexType: MetalLinkVertexShaderType) -> MetalLinkShader? {
        vertexShaders[vertexType]
    }
    
    subscript(_ fragmentType: MetalLinkFragmentShaderType) -> MetalLinkShader? {
        fragmentShaders[fragmentType]
    }
}

private class VertexShadersCache: LockingCache<MetalLinkVertexShaderType, MetalLinkShader?> {
    let link: MetalLink
    
    init(_ link: MetalLink) {
        self.link = link
        super.init()
    }
    
    override func make(_ key: Key, _ store: inout [Key : Value]) -> MetalLinkShader? {
        return try? key.make(link)
    }
}

private class FragmentShadersCache: LockingCache<MetalLinkFragmentShaderType, MetalLinkShader> {
    let link: MetalLink
    
    init(_ link: MetalLink) {
        self.link = link
        super.init()
    }
    
    override func make(_ key: Key, _ store: inout [Key : Value]) -> MetalLinkShader {
        return try! key.make(link)
    }
}
