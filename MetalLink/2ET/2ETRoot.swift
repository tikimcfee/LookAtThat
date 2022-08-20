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
    
    lazy var camera = DebugCamera(link: link)
    lazy var root = RootNode(camera)
    
    init(link: MetalLink) throws {
        self.link = link
        try setup9()
    }
    
    func delegatedEncode(in sdp: inout SafeDrawPass) {
        let dT =  1.0 / Float(link.view.preferredFramesPerSecond)
        
        // TODO: Make update and render a single pass to avoid repeated child loops
        root.update(deltaTime: dT)
        root.render(in: &sdp)
    }
}

enum MetalGlyphError: String, Error {
    case noBitmaps
    case noTextures
    case noMesh
    case noAtlasTexture
}

extension TwoETimeRoot {
    func setup9() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        let collection = try GlyphCollection(
            link: link
        ) { atlas in
            (0..<1_00).flatMap { _ in
                MetalLinkAtlas.allSampleGlyphs.compactMap { key in
                    atlas.newGlyph(key)
                }
            }
        }
        
        collection.scale = LFloat3(0.5, 0.5, 0.5)
        collection.position.x = -25
        collection.position.y = 0
        collection.position.z = -30
        
        root.add(child: collection)
    }
    
    func setup8() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        let test = "METAL"
        
        let collection = try GlyphCollection(
            link: link
        ) { atlas in
            test.compactMap { atlas.newGlyph(GlyphCacheKey(String($0), .red)) }
        }
        
        collection.position.x = -5
        collection.position.y = -5
        collection.position.z = -10
        
        root.add(child: collection)
    }
    
    func setup7() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        let linkNodeCache = MetalLinkGlyphNodeCache(link: link)
        
        let cacheKeys = ">🥸 Hello there, Metal."
            .map { GlyphCacheKey("\($0)", .red) }
        
        func doHello(at yStart: Float = 0.0) {
            func updateNode(_ node: MetalLinkGlyphNode) {
//                print("g:[\(node.key.glyph)]")
                xOffset += (last?.quad.width ?? 0) / 2.0 + node.quad.width / 2.0
                node.position.z -= 5
                node.position.x += xOffset
                node.position.y = yStart
            }
            
            var xOffset = Float(0.0)
            var last: MetalLinkGlyphNode?
            cacheKeys
                .lazy
                .compactMap { linkNodeCache.create($0) }
                .forEach { node in
                    updateNode(node)
                    last = node
                    root.add(child: node)
                }
        }
        
        stride(from: 0.0, to: 1000, by: 1).forEach {
            doHello(at: -1.1 * $0)
        }
    }
    
    func setup6() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        let linkNodeCache = MetalLinkGlyphNodeCache(link: link)
        
//        let block = "🥸"
        let block = ">🥸 Hello there, Metal."
        let testKey = GlyphCacheKey(block, .red)
        
        guard let node = linkNodeCache.create(testKey)
        else { return }
        
        // Map [(0, 0), (x, y)] to [(0, 0), (1, 1)]
        node.position.z = -10
        root.add(child: node)
    }
    
    
    func setup5() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        let quadNode = MetalLinkObject(link, mesh: link.meshes[.Quad])
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
                    let cube = CubeNode(link: link)
                    cube.position = LFloat3(xPos / halfCount, yPos / halfCount, zPos / halfCount)
                    cube.scale = LFloat3(repeating: 1 / (count + 10))
                    root.add(child: cube)
                }
            }
        }
    }
    
    func setup2() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        let node = CubeNode(link: link)
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
                
                let node = ArrowNode(link)
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
