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
    let builder = GlyphBuilder()
    
    lazy var root = RootNode(
        DebugCamera(link: link)
    )
    
    init(link: MetalLink) throws {
        self.link = link
        try setup6()
    }
    
    func delegatedEncode(in sdp: inout SafeDrawPass) {
        root.update(deltaTime: 1.0 / Float(link.view.preferredFramesPerSecond))
        root.render(in: &sdp)
    }
}

enum MetalGlyphError: String, Error {
    case noBitmaps
}

extension TwoETimeRoot {
    func setup6() throws {
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        guard let bitmaps = builder.makeBitmaps(GlyphCacheKey(
            "Hello, Metal.",
            .red
        )) else {
            throw MetalGlyphError.noBitmaps
        }
        
        let glyphTexture = try link.textureLoader.newTexture(
            cgImage: bitmaps.requestedCG,
            options: [:]
        )
        
        class GlyphNode: MetalLinkObject {
            let texture: MTLTexture
            
            init(_ link: MetalLink, texture: MTLTexture) throws {
                self.texture = texture
                try super.init(link, mesh: link.meshes[.Quad])
            }
            
            override func applyTextures(_ sdp: inout SafeDrawPass) {
                sdp.renderCommandEncoder.setFragmentTexture(texture, index: 0)
            }
        }
        
//        let textureDescriptor = MTLTextureDescriptor()
//        textureDescriptor.width = glyphTexture.width
//        textureDescriptor.height = glyphTexture.height
//        textureDescriptor.pixelFormat = glyphTexture.pixelFormat
//        textureDescriptor.allowGPUOptimizedContents = true
        
        let node = try GlyphNode(link, texture: glyphTexture)
        let ratio = Float(bitmaps.requestedCG.width) / Float(bitmaps.requestedCG.height)
//        node.scale.y = ratio / Float(bitmaps.requestedCG.width)
        
        root.add(child: node)
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
