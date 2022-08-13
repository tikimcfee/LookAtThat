//
//  LinkGlyph.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/11/22.
//

import MetalKit

extension MTLTexture {
    var simdSize: LFloat2 {
        LFloat2(Float(width), Float(height))
    }
}

struct UnitSize {
    static func from(_ source: LFloat2) -> LFloat2 {
        let unitWidth = 1 / source.x
        let unitHeight = 1 / source.y
        return LFloat2(min(source.x * unitHeight, 1),
                       min(source.y * unitWidth, 1))
    }
}

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
        setQuadSize()
    }
    
    func setQuadSize() {
        let size = UnitSize.from(texture.simdSize)
        (quad.width, quad.height) = (size.x, size.y)
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
        super.init()
        self.buildAtlas()
    }
    
    private var _makeTextureIndex: TextureIndex = 0
    private func nextTextureIndex() -> TextureIndex {
        let index = _makeTextureIndex
        _makeTextureIndex += 1
        return index
    }
    
    static func makeAtlasCanvas(_ link: MetalLink) -> MTLTexture? {
        let glyphCount: Float = 128
        let glyphSizeEstimate = LFloat2(13.0, 23.0)
        let canvasSize = LInt2(glyphSizeEstimate * glyphCount)
        
        let glyphDescriptor = MTLTextureDescriptor()
        glyphDescriptor.textureType = .type2D
        glyphDescriptor.pixelFormat = .rgba8Unorm_srgb
        glyphDescriptor.width = canvasSize.x
        glyphDescriptor.height = canvasSize.y
        
        return link.device.makeTexture(descriptor: glyphDescriptor)
    }
    
    func buildAtlas() {
        guard let texture = Self.makeAtlasCanvas(link)
            else { return }
        print("Atlas ready: \(texture.width) x \(texture.height)")
        
        let block = """
        ABCDEFGHIJKLMNOPQRSTUVWXYZ
        abcdefghijklmnopqrstuvwxyz
        1234567890!@#$%^&*()
        []\\;',./{}|:"<>?
        """
        
        var stylusX: Float = 0
        var stylusY: Float = 0
        
        func addGlyph(_ key: GlyphCacheKey) {
            guard let textureBundle = self[key] else {
                print("Missing texture for \(key)")
                return
            }
            
            
        }
        
        block.map { GlyphCacheKey(String($0), .red) }
            .forEach { addGlyph($0) }
        
        
        print("Atlas Created")
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
