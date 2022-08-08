//
//  Definitions.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import MetalKit

protocol MetalLinkShader {
    var link: MetalLink { get }
    var name: String { get }
    var functionName: String { get }
    var function: MTLFunction { get }
}

extension MetalLinkShader {
    func getFunction(_ link: MetalLink) -> MTLFunction {
        return link.defaultLibrary.makeFunction(name: functionName)!
    }
}
