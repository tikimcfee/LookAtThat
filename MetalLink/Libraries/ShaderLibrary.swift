//
//  ShaderLibrary.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

class ShaderLibrary {
    private var vertexShaders = [MetalLinkVertexShaderType: MetalLinkShader]()
    private var fragmentShaders = [MetalLinkFragmentShaderType: MetalLinkShader]()
    
    let link: MetalLink
    init (link: MetalLink) {
        self.link = link
    }
    
    subscript(_ vertexType: MetalLinkVertexShaderType) -> MetalLinkShader? {
        if let shader = vertexShaders[vertexType] { return shader }
        
        do {
            let newShader = try vertexType.make(link)
            vertexShaders[vertexType] = newShader
            return newShader
        } catch {
            print(error)
            return nil
        }
    }
    
    subscript(_ fragmentType: MetalLinkFragmentShaderType) -> MetalLinkShader? {
        if let shader = fragmentShaders[fragmentType] { return shader }
        
        do {
            let newShader = try fragmentType.make(link)
            fragmentShaders[fragmentType] = newShader
            return newShader
        } catch {
            print(error)
            return nil
        }
    }
}

