//
//  MetalLinkGlyphNodeCache.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/13/22.
//

import Foundation
import Metal

class MetalLinkGlyphNodeCache {
    let link: MetalLink
    
    let meshCache: MetalLinkGlyphNodeMeshCache
    let textureCache: MetalLinkGlyphTextureCache
    
    init(link: MetalLink) {
        self.link = link
        self.meshCache = MetalLinkGlyphNodeMeshCache(link: link)
        self.textureCache = MetalLinkGlyphTextureCache(link: link)
    }
    
    func create(_ key: GlyphCacheKey) -> MetalLinkGlyphNode? {
        do {
            guard let glyphTexture = textureCache[key]
            else { throw MetalGlyphError.noTextures }
            
            let mesh = meshCache[key]
            let node = MetalLinkGlyphNode(
                link,
                key: key,
                texture: glyphTexture.texture,
                quad: mesh
            )
            node.constants.textureIndex = glyphTexture.textureIndex
            
            return node
        } catch {
            print(error)
            return nil
        }
    }
}
