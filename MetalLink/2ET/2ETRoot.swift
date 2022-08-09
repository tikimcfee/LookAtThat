//
//  TriangleShape.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import Foundation
import MetalKit

class TwoETimeRoot: MetalLinkReader {
    let link: MetalLink
    var meshes: MeshLibrary
    
    let linkObject: MetalLinkObject
    
    init(link: MetalLink) throws {
        self.link = link
        
        let library = MeshLibrary(link)
        self.meshes = library
        self.linkObject = try library.makeObject(.Quad)
        
        setup()
    }
    
    func delegatedEncode(in sdp: inout SafeDrawPass) {
        linkObject.update(deltaTime: 0.05)
        linkObject.render(in: &sdp)
    }
}

extension TwoETimeRoot {
    func setup() {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)   
    }
}
