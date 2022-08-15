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
        
        if bitmaps.requestedCG.width != 13 || bitmaps.requestedCG.height != 23 {
            print("-- Unhandled glyph: \(key.glyph)")
        }
        
        guard let glyphTexture = try? link.textureLoader.newTexture(
            cgImage: bitmaps.requestedCG,
            options: [.textureStorageMode: MTLStorageMode.private.rawValue]
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
