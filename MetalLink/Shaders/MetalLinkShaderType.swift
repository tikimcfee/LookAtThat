//
//  CoreShadersTypes.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/7/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

enum MetalLinkShaderType {
    case BasicVertex
    case BasicFragment
    
    case InstancedVertex
    case InstancedFragment
    
    var name: String {
        switch self {
        case .BasicVertex:
            return "Basic Vertex Shader"
        case .InstancedVertex:
            return "Instanced Vertex Shader"
            
        case .BasicFragment:
            return "Basic Fragment Shader"
        case .InstancedFragment:
            return "Instanced Fragment Shader"
        }
    }
    
    var functionName: String {
        switch self {
        case .BasicVertex:
            return BASIC_VERTEX_FUNCTION_NAME_Q
        case .BasicFragment:
            return BASIC_FRAGMENT_FUNCTION_NAME_Q
        
        case .InstancedVertex:
            return INSTANCED_VERTEX_FUNCTION_NAME_Q
        case .InstancedFragment:
            return INSTANCED_FRAGMENT_FUNCTION_NAME_Q
        }
    }
    
    func getFunction(_ link: MetalLink) -> MTLFunction {
        link.defaultLibrary.makeFunction(name: functionName)!
    }
}
