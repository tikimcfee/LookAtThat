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
    
    let root = MetalLinkNode()
    
    init(link: MetalLink) throws {
        self.link = link
        self.meshes = MeshLibrary(link)
        
        try setup()
    }
    
    func delegatedEncode(in sdp: inout SafeDrawPass) {
        root.update(deltaTime: 1.0 / Float(link.view.preferredFramesPerSecond))
        root.render(in: &sdp)
    }
}

class RootNode: MetalLinkNode {
    
}

extension TwoETimeRoot {
    func setup() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        let (min, max) = (-20, 20)
        let length = (min..<max)
        let count = Float(length.count)
        let halfCount = count / 2.0 // iterate from left to right, left/right symmetry
        for x in length {
            let x = Float(x)
            for y in length {
                let y = Float(y)
                
                let quad = try meshes.makeObject(.Quad)
                quad.position = LFloat3(
                    (x + 0.5) / halfCount,
                    (y + 0.5) / halfCount,
                    1
                )
                quad.scale = LFloat3(repeating: 1 / count)
                root.add(child: quad)
            }
        }
    }
}
