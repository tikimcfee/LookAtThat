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
        try? MetalLinkQuadMesh(link)
    }
}

class MetalLinkGlyphNodeBitmapCache: LockingCache<GlyphCacheKey, BitmapImages?> {
    let builder = GlyphBuilder()
    
    override func make(_ key: Key, _ store: inout [Key : Value]) -> Value {
        builder.makeBitmaps(key)
    }
}

class MetalLinkGlyphTextureCache: LockingCache<GlyphCacheKey, MetalLinkGlyphTextureCache.Bundle?> {
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
    
    let link: MetalLink
    let bitmapCache: MetalLinkGlyphNodeBitmapCache = MetalLinkGlyphNodeBitmapCache()
    
    init(link: MetalLink) {
        self.link = link
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

class MetalLinkGlyphNodeCache {
    let link: MetalLink
    
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
            guard let glyphTexture = textureCache[key]
                else { throw MetalGlyphError.noTextures }
            
            guard let mesh = meshCache[key]
                else { throw MetalGlyphError.noMesh }
            
            let node = try MetalLinkGlyphNode(
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
