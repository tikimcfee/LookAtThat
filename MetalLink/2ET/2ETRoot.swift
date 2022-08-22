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
        try setup10()
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
    func setup10() throws {
        let collection = GlyphCollection(link: link)
        collection.instanceState.refreshState(with: {
            (0..<1_00).flatMap { _ in
                MetalLinkAtlas.allSampleGlyphs.compactMap { key in
                    collection.linkAtlas.newGlyph(key)
                }
            }
        }())
        collection.setupNodes()
        
        collection.scale = LFloat3(0.5, 0.5, 0.5)
        collection.position.x = -25
        collection.position.y = 0
        collection.position.z = -30
        
        root.add(child: collection)
        
        func loop() {
            let color = [NSUIColor.gray, .green, .purple, .blue, .red].randomElement()!
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                collection.instanceState.refreshState(with: {
                    "Metal Magic".compactMap { letter in
                        collection.linkAtlas.newGlyph(GlyphCacheKey(String(letter), color))
                    }
                }())
                collection.setupNodes()
                loop()
            }
        }
        loop()
    }
    
    func setup9() throws {
        let collection = GlyphCollection(link: link)
        collection.instanceState.refreshState(with: {
            (0..<1_00).flatMap { _ in
                MetalLinkAtlas.allSampleGlyphs.compactMap { key in
                    collection.linkAtlas.newGlyph(key)
                }
            }
        }())
        collection.setupNodes()
        
        collection.scale = LFloat3(0.5, 0.5, 0.5)
        collection.position.x = -25
        collection.position.y = 0
        collection.position.z = -30
        
        root.add(child: collection)
    }
}
