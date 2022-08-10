//
//  TriangleShape.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//

import Combine
import MetalKit

class TwoETimeRoot: MetalLinkReader {
    let link: MetalLink
    
    lazy var root = RootNode(
        DebugCamera(link: link)
    )
    
    init(link: MetalLink) throws {
        self.link = link
        try setup3()
    }
    
    func delegatedEncode(in sdp: inout SafeDrawPass) {
        root.update(deltaTime: 1.0 / Float(link.view.preferredFramesPerSecond))
        root.render(in: &sdp)
    }
}

extension TwoETimeRoot {
    func setup3() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        let (min, max) = (-3, 3)
        let length = (min..<max)
        let count = Float(length.count)
        let halfCount = count / 2.0 // iterate from left to right, left/right symmetry
        
        for x in length {
            let xPos = Float(x) + 0.5
            for y in length {
                let yPos = Float(y) + 0.5
                for z in length {
                    let zPos = Float(z) + 0.5
                    let cube = try CubeNode(link: link)
                    cube.position = LFloat3(xPos / halfCount, yPos / halfCount, zPos / halfCount)
                    cube.scale = LFloat3(repeating: 1 / (count + 10))
                    root.add(child: cube)
                }
            }
        }
    }
    
    func setup2() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        let node = try CubeNode(link: link)
        node.setColor(LFloat4(0.12, 0.67, 0.23, 1.0))
        root.add(child: node)
    }
    
    func setup() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        let (min, max) = (-10, 10)
        let length = (min..<max)
        let count = Float(length.count)
        let halfCount = count / 2.0 // iterate from left to right, left/right symmetry
        for x in length {
            let x = Float(x)
            for y in length {
                let y = Float(y)
                
                let node = try ArrowNode(link)
                node.position = LFloat3(
                    (x + 0.5) / halfCount,
                    (y + 0.5) / halfCount,
                    1
                )
                node.scale = LFloat3(repeating: 1 / count)
                root.add(child: node)
            }
        }
    }
}
