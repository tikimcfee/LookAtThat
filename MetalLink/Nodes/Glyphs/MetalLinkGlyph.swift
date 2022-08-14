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
         quad: MetalLinkQuadMesh) {
        self.key = key
        self.texture = texture
        self.quad = quad
        super.init(link, mesh: quad)
        setQuadSize()
    }
    
    func instanceableClone() -> MetalLinkGlyphNode {
        MetalLinkGlyphNode(link, key: key, texture: texture, quad: quad)
    }
    
    func setQuadSize() {
        let size = UnitSize.from(texture.simdSize)
        (quad.width, quad.height) = (size.x, size.y)
    }
    
    override func applyTextures(_ sdp: inout SafeDrawPass) {
        sdp.renderCommandEncoder.setFragmentTexture(texture, index: 0)
    }
}
