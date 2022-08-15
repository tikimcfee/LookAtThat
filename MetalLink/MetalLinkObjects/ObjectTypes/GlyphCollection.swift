//
//  GlyphCollection.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/11/22.
//

import MetalKit

// ----------------------------------

class GlyphCollection: MetalLinkInstancedObject<MetalLinkGlyphNode> {
    var textBody: String
    var linkAtlas: MetalLinkAtlas
    
    init(link: MetalLink, text: String) throws {
        let newLinkAtlas = MetalLinkAtlas(link)
        self.linkAtlas = newLinkAtlas
        self.textBody = text
        _ = newLinkAtlas.getSampleAtlas()
        
        
        try super.init(link, mesh: link.meshes[.Quad], instances: {
            [
                text.compactMap { character in
                    newLinkAtlas.newGlyph(GlyphCacheKey(String(character), .red))
                },
                text.compactMap { character in
                    newLinkAtlas.newGlyph(GlyphCacheKey(String(character), .green))
                },
                text.compactMap { character in
                    newLinkAtlas.newGlyph(GlyphCacheKey(String(character), .blue))
                }
            ].flatMap { $0 }
        })
        
        setupNodes()
    }
    
    func setupNodes() {
        print("Setting up collection nodes")
        
        let left = Float(0.0)
        let top = Float(0.0)
        let front = Float(-5.0)
        var xOffset = Float(left)
        var yOffset = Float(top)
        var zOffset = Float(front)
        
        var last: MetalLinkGlyphNode?
        instancedNodes.enumerated().forEach { index, node in
            xOffset += (last?.quad.width ?? 0) / 2.0 + node.quad.width / 2.0
            node.position.x = xOffset + 1
            node.position.y = yOffset
            node.position.z = zOffset
            
            if let cachedPair = linkAtlas.uvPairCache[node.key] {
                instancedConstants[index].textureDescriptorU = cachedPair.u
                instancedConstants[index].textureDescriptorV = cachedPair.v
            } else {
                print("--------------")
                print("MISSING UV PAIR")
                print("\(node.key.glyph)")
                print("--------------")
            }
            
            last = node
            
            guard index >= 1 else { return }
            if index % 100 == 0 {
                xOffset = left
                yOffset -= 1.1
            }
            
            if index % (100 * 100) == 0 {
                zOffset -= 10.0
                yOffset = top
            }
        }
        
        // ***********************************************************************************
        // TODO:
        // THIS IS A DIRTY FILTHY HACK
        // The instance only works because the glyphs are all the same size - hooray monospace.
        // The moment there's something that's NOT, we'll get stretching / skewing / breaking.
        // Solving that.. is for next time.
        // Collections of collections per glyph size? Factored down (scaled) / rotated to deduplicate?
        // ***********************************************************************************
        mesh = instancedNodes[0].mesh
    }
    
    private var _time: Float = 0
    private func time(_ dT: Float) -> Float { _time += dT; return _time }
    
    override func update(deltaTime dT: Float) {
//        pushModelConstants = true
        super.update(deltaTime: dT)
    }
    
    override func render(in sdp: inout SafeDrawPass) {
        if let atlas = linkAtlas.getSampleAtlas() {
            sdp.renderCommandEncoder.setFragmentTexture(atlas, index: 5)
        }
        super.render(in: &sdp)
    }
    
    override func performJITInstanceBufferUpdate(_ node: MetalLinkNode) {
//        node.rotation.x -= 0.0167 * 2
//        node.rotation.y -= 0.0167 * 2
//        node.position.z = cos(time(0.0167) / 500)
    }
}
