//
//  LinkGlyph.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/11/22.
//

import MetalKit

class LinkNode: MetalLinkObject {
    let key: GlyphCacheKey
    let texture: MTLTexture
    let quad: MetalLinkQuadMesh
    
    init(_ link: MetalLink, key: GlyphCacheKey, texture: MTLTexture) throws {
        self.key = key
        self.texture = texture
        self.quad = link.meshes[.Quad] as! MetalLinkQuadMesh
        try super.init(link, mesh: quad)
        sizeSelf()
    }
    
    func sizeSelf() {
//        let (width, height) = (Float(texture.width), Float(texture.height))
//        let unitHeight = 1.0 / height
//        let unitWidth = 1.0 / height
//        let scaledUnitWidth = width * unitHeight
//        quad.width = scaledUnitWidth
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

class LinkNodeCache: LockingCache<GlyphCacheKey, LinkNode?> {
    let link: MetalLink
    let builder = GlyphBuilder()
    
    init(link: MetalLink) {
        self.link = link
    }
    
    func create(_ key: GlyphCacheKey) -> LinkNode? {
        do {
            guard let bitmaps = builder.makeBitmaps(key)
                else { throw MetalGlyphError.noBitmaps }
            
            let glyphTexture = try link.textureLoader.newTexture(
                cgImage: bitmaps.requestedCG,
                options: [:]
            )
            return try LinkNode(link, key: key, texture: glyphTexture)
        } catch {
            print(error)
            return nil
        }
    }
    
    override func make(_ key: GlyphCacheKey, _ store: inout [GlyphCacheKey : LinkNode?]) -> LinkNode? {
        create(key)
    }
}
