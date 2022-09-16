//
//  LinkGlyph.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/11/22.
//

import MetalKit

class MetalLinkGlyphNode: MetalLinkObject, QuadSizable {
    let key: GlyphCacheKey
    let texture: MTLTexture
    var meta: Meta
    
    var quad: MetalLinkQuadMesh
    var node: MetalLinkNode { self }
    
    override var hasIntrinsicSize: Bool { true }
    
    override var contentSize: LFloat3 {
        LFloat3(quad.width, quad.height, 1)
    }
    
    override var contentOffset: LFloat3 {
        LFloat3(-quad.width / 2.0, quad.height / 2.0, 0)
    }
    
    init(_ link: MetalLink,
         key: GlyphCacheKey,
         texture: MTLTexture,
         quad: MetalLinkQuadMesh) {
        self.key = key
        self.texture = texture
        self.quad = quad
        self.meta = Meta()
        super.init(link, mesh: quad)
        setQuadSize()
    }
    
    func setQuadSize() {
        BoundsCaching.ClearRoot(self)
        let size = UnitSize.from(texture.simdSize)
        (quad.width, quad.height) = (size.x, size.y)
    }
    
    override func applyTextures(_ sdp: inout SafeDrawPass) {
        sdp.renderCommandEncoder.setFragmentTexture(texture, index: 0)
    }
}

extension MetalLinkGlyphNode {
    // Optional meta on nodes; I think I'm shifting to using these as the
    // carrier of truth since I have more control of where they come from.
    // I think SCNNode made it trickier to know what was what. I'm decreasing
    // flexibility and adding cohesion (coupling?). This is basically what I
    // encoded into SCNNode.name. This is more explicit.
    struct Meta {
        var syntaxID: NodeSyntaxID?
        var instanceID: InstanceIDType?
        var instanceBufferIndex: Int?
    }
}

extension MetalLinkGlyphNode {
    enum GroupType {
        case glyphCollection(instanceID: InstanceIDType)
        case standardGroup
    }
}
