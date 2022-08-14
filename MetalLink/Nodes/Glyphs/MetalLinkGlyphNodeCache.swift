//
//  MetalLinkGlyphNodeCache.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/13/22.
//

import Foundation

//TODO: Think if there's a way to do something with saved nodes for *instancing*.
// Still need 1 instance per glyph, but the mapping of key -> texture + uvs might be reusable?
// I have no freaking idea and I'm tired again.
class MetalLinkGlyphNodeCache {
    let link: MetalLink
    
    let meshCache: MetalLinkGlyphNodeMeshCache
    let textureCache: MetalLinkGlyphTextureCache
    var glyphAtlas: MetalLinkAtlas? { textureCache.linkAtlas }
    
    init(link: MetalLink) {
        self.link = link
        self.meshCache = MetalLinkGlyphNodeMeshCache(link: link)
        self.textureCache = MetalLinkGlyphTextureCache(link: link)
    }
    
    private typealias TextureKey = MetalLinkGlyphTextureCache.Key
    func create(_ key: GlyphCacheKey) -> MetalLinkGlyphNode? {
        do {
            guard let glyphTexture = textureCache[key]
            else { throw MetalGlyphError.noTextures }
            
            guard let mesh = meshCache[key]
            else { throw MetalGlyphError.noMesh }
            
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
