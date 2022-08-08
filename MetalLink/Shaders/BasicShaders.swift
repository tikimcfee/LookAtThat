//
//  BasicShaders.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/7/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

class Basic_VertexShader: MetalLinkShader {
    let link: MetalLink
    var name = "Basic Vertex Shader"
    var functionName = BASIC_VERTEX_FUNCTION_NAME_Q
    lazy var function: MTLFunction = getFunction(link)
    
    init(_ link: MetalLink) {
        self.link = link
    }
}

class Basic_FragmentShader: MetalLinkShader {
    let link: MetalLink
    var name = "Basic Fragment Shader"
    var functionName = BASIC_FRAGMENT_FUNCTION_NAME_Q
    lazy var function: MTLFunction = getFunction(link)
    
    init(_ link: MetalLink) {
        self.link = link
    }
}
