//
//  MetalLinkGlyphNodeTextureCache.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/13/22.
//

import MetalKit

class MetalLinkGlyphTextureCache: LockingCache<GlyphCacheKey, MetalLinkGlyphTextureCache.Bundle?> {
    let link: MetalLink
    let bitmapCache: MetalLinkGlyphNodeBitmapCache
    
    // TODO: This is dangerous!
    // TODO: The atlas writes UVs directly in to the mesh cache.
    // It's lazy, so it happens on first call    
    private lazy var linkAtlas = try? MetalLinkAtlas(link)
    var atlas: MTLTexture? { linkAtlas?.texture }
    
    init(link: MetalLink) {
        self.link = link
        self.bitmapCache = MetalLinkGlyphNodeBitmapCache()
        super.init()
    }
    
    private var _makeTextureIndex: TextureIndex = 0
    private func nextTextureIndex() -> TextureIndex {
        let index = _makeTextureIndex
        _makeTextureIndex += 1
        return index
    }
    
    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        guard let bitmaps = bitmapCache[key]
        else { return nil }
        
        guard let glyphTexture = try? link.textureLoader.newTexture(
            cgImage: bitmaps.requestedCG,
            options: [:]
        ) else { return nil}
        
        return Bundle(texture: glyphTexture, textureIndex: nextTextureIndex())
    }
}

extension MetalLinkGlyphTextureCache {
    struct Bundle: Equatable {
        let texture: MTLTexture
        let textureIndex: TextureIndex
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(textureIndex)
        }
        
        static func == (_ l: Bundle, _ r: Bundle) -> Bool {
            l.textureIndex == r.textureIndex
        }
    }
}
