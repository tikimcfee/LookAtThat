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
    
    lazy var linkNodeCache = LinkNodeCache(link: link)
    
    lazy var root = RootNode(
        DebugCamera(link: link)
    )
    
    init(link: MetalLink) throws {
        self.link = link
        try setup7()
    }
    
    func delegatedEncode(in sdp: inout SafeDrawPass) {
        let dT =  1.0 / Float(link.view.preferredFramesPerSecond)
        
//        root.children.forEach {
//            $0.rotation.x -= dT * 2
//            $0.rotation.y -= dT * 2
//        }
        
        root.update(deltaTime: dT)
        root.render(in: &sdp)
    }
}

enum MetalGlyphError: String, Error {
    case noBitmaps
}

extension TwoETimeRoot {
    func setup7() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        let collection = try GlyphCollection(
            link: link,
            text: "The quick brown fox jumps over the lazy dog."
        )
        root.add(child: collection)
    }
    
    func setup6() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        let cacheKeys = ">🥸 Hello there, Metal."
            .map { GlyphCacheKey("\($0)", .red) }
        
        func doHello(at yStart: Float = 0.0) {
            var xOffset = Float(0.0)
            var last: LinkNode?
            cacheKeys
                .compactMap { self.linkNodeCache.create($0) }
                .map { node -> LinkNode in
                    xOffset += (last?.quad.width ?? 0) / 2.0 + node.quad.width / 2.0
//                    print("g:[\(node.key.glyph)]")
                    node.position.z -= 5
                    node.position.x += xOffset
                    node.position.y = yStart
                    last = node
                    return node
                }
                .forEach {
                    self.root.add(child: $0)
                }
        }
        
        stride(from: 0.0, to: 3, by: 1).forEach {
            doHello(at: -1 * $0)
        }
    }
    
    func setup5() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        let quadNode = try MetalLinkObject(link, mesh: link.meshes[.Quad])
        quadNode.position.z -= 5
        
        root.add(child: quadNode)
    }
    
    func setup4() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        let collection = try CubeCollection(
            link: link,
            size: SIMD3<Int>(20, 20, 20)
        )
        collection.position.z -= 50
        
        root.add(child: collection)
    }
    
    func setup3() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        let (min, max) = (-20, 20)
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
