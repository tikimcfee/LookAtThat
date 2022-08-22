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
        
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        try setup11()
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
    func setup11() throws {
        let atlas = try MetalLinkAtlas(link)
        let collection = GlyphCollection(link: link, linkAtlas: atlas)
        collection.scale = LFloat3(0.5, 0.5, 0.5)
        collection.position.x = -25
        collection.position.y = 0
        collection.position.z = -30
        root.add(child: collection)
        
        let test = """
        Hello, Metal.
        This is some text.
        And you're rendering it just fine.
        """
        
        test.forEach { symbol in
            collection.addGlyph(GlyphCacheKey(source: symbol, .red))
        }
        collection.setRootMesh()
    }
}
