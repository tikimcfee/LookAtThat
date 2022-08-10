//
//  CoreShadersTypes.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/7/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

enum MetalLinkVertexShaderType {
    case BasicVertex
    case InstancedVertex
    
    func make(_ link: MetalLink) throws -> MetalLinkShader {
        switch self {
        case .BasicVertex:
            return Basic_VertexShader(link)
        case .InstancedVertex:
            return Instanced_VertexShader(link)
        }
    }
}

enum MetalLinkFragmentShaderType {
    case BasicFragment
    case InstancedFragment
    
    func make(_ link: MetalLink) throws -> MetalLinkShader {
        switch self {
        case .BasicFragment:
            return Basic_FragmentShader(link)
        case .InstancedFragment:
            return Instanced_FragmentShader(link)
        }
    }
}
