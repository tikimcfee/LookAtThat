//
//  LinkGlyph.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/11/22.
//

import MetalKit

class MetalLinkGlyphNode: MetalLinkObject {
    let key: GlyphCacheKey
    let texture: MTLTexture
    var quad: MetalLinkQuadMesh
    
    init(_ link: MetalLink,
         key: GlyphCacheKey,
         texture: MTLTexture,
         quad: MetalLinkQuadMesh) throws {
        self.key = key
        self.texture = texture
        self.quad = quad
        try super.init(link, mesh: quad)
        sizeSelf()
    }
    
    func sizeSelf() {
        let (width, height) = (Float(texture.width), Float(texture.height))
        let unitHeight = 2.0 / height
        let unitWidth = 2.0 / width
        if unitHeight > unitWidth {
            quad.height = height * unitWidth
        } else {
            quad.width = width * unitHeight
        }
    }
    
    override func applyTextures(_ sdp: inout SafeDrawPass) {
        sdp.renderCommandEncoder.setFragmentTexture(texture, index: 0)
    }
}

class MetalLinkGlyphNodeMeshCache: LockingCache<GlyphCacheKey, MetalLinkQuadMesh?> {
    let link: MetalLink
    
    init(link: MetalLink) {
        self.link = link
    }
    
    override func make(_ key: Key, _ store: inout [Key : Value]) -> Value {
        do {
            return try MetalLinkQuadMesh(link)
        } catch {
            print(error)
            return nil
        }
    }
}

class MetalLinkGlyphNodeBitmapCache: LockingCache<GlyphCacheKey, BitmapImages?> {
    let builder = GlyphBuilder()
    
    override func make(_ key: Key, _ store: inout [Key : Value]) -> Value {
        builder.makeBitmaps(key)
    }
}


class MetalLinkGlyphTextureCache: LockingCache<MetalLinkGlyphTextureCache.TextureCacheKey, MTLTexture?> {
    struct TextureCacheKey: Hashable, Equatable {
        let glyph: GlyphCacheKey
        let bitmaps: BitmapImages
    }
    
    let link: MetalLink
    
    init(link: MetalLink) {
        self.link = link
    }
    
    override func make(_ key: Key, _ store: inout [Key: Value]) -> Value {
        let glyphTexture = try? link.textureLoader.newTexture(
            cgImage: key.bitmaps.requestedCG,
            options: [:]
        )
        return glyphTexture
    }
}

class MetalLinkGlyphNodeCache {
    let link: MetalLink
    
    let bitmapCache: MetalLinkGlyphNodeBitmapCache = MetalLinkGlyphNodeBitmapCache()
    let meshCache: MetalLinkGlyphNodeMeshCache
    let textureCache: MetalLinkGlyphTextureCache
    
    init(link: MetalLink) {
        self.link = link
        self.meshCache = MetalLinkGlyphNodeMeshCache(link: link)
        self.textureCache = MetalLinkGlyphTextureCache(link: link)
    }
    
    private typealias TextureKey = MetalLinkGlyphTextureCache.Key
    func create(_ key: GlyphCacheKey) -> MetalLinkGlyphNode? {
        do {
            guard let bitmaps = bitmapCache[key]
                else { throw MetalGlyphError.noBitmaps }
            
            let textureKey = TextureKey(glyph: key, bitmaps: bitmaps)
            guard let glyphTexture = textureCache[textureKey]
                else { throw MetalGlyphError.noTextures }
            
            guard let mesh = meshCache[key]
                else { throw MetalGlyphError.noMesh }
            
            return try MetalLinkGlyphNode(
                link,
                key: key,
                texture: glyphTexture,
                quad: mesh
            )
        } catch {
            print(error)
            return nil
        }
    }
}
