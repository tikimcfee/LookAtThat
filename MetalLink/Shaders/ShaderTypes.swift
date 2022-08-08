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
    
    func make(_ link: MetalLink) throws -> MetalLinkShader {
        switch self {
        case .BasicVertex:
            return Basic_VertexShader(link)
        }
    }
}

enum MetalLinkFragmentShaderType {
    case BasicFragment
    
    func make(_ link: MetalLink) throws -> MetalLinkShader {
        switch self {
        case .BasicFragment:
            return Basic_FragmentShader(link)
        }
    }
}
