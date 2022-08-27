//
//  GlyphCollection.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/11/22.
//

import MetalKit

class GlyphCollection: MetalLinkInstancedObject<MetalLinkGlyphNode> {
    var linkAtlas: MetalLinkAtlas
    lazy var renderer = Renderer(collection: self)
    
    init(link: MetalLink,
         linkAtlas: MetalLinkAtlas) {
        self.linkAtlas = linkAtlas
        super.init(link, mesh: link.meshLibrary[.Quad])
    }
        
    private var _time: Float = 0
    private func time(_ dT: Float) -> Float {
        _time += dT
        return _time
    }
    
    override func update(deltaTime dT: Float) {
        super.update(deltaTime: dT)
    }
    
    override func render(in sdp: inout SafeDrawPass) {
        sdp.renderCommandEncoder.setFragmentTexture(linkAtlas.currentAtlas, index: 5)
        super.render(in: &sdp)
    }
    
    override func enumerateChildren(_ action: (MetalLinkNode) -> Void) {
        enumerateInstanceChildren(action)
    }
    
    func enumerateInstanceChildren(_ action: (MetalLinkGlyphNode) -> Void) {
        for instance in instanceState.nodes {
            action(instance)
        }
    }
    
    override func performJITInstanceBufferUpdate(_ node: MetalLinkNode) {
//        node.rotation.x -= 0.0167 * 2
//        node.rotation.y -= 0.0167 * 2
//        node.position.z = cos(time(0.0167) / 500)
    }
}

extension GlyphCollection {
    // TODO: Add a 'render all of this' function to avoid
    // potentially recreating the buffer hundreds of times.
    // Buffer *should* only reset when the texture is called,
    // but that's a fragile guarantee.
    func addGlyph(_ key: GlyphCacheKey) -> GlyphNode? {
        guard let newGlyph = linkAtlas.newGlyph(key) else {
            print("No glyph for", key)
            return nil
        }
        
        var constants = instanceCache.createNew()
        if let cachedPair = linkAtlas.uvPairCache[key] {
            constants.textureDescriptorU = cachedPair.u
            constants.textureDescriptorV = cachedPair.v
        } else {
            print("--------------")
            print("MISSING UV PAIR")
            print("\(key.glyph)")
            print("--------------")
        }
        
        newGlyph.parent = self
        renderer.insert(newGlyph, constants)
        
        return newGlyph
    }
    
}

extension GlyphCollection {
    func setRootMesh() {
        // ***********************************************************************************
        // TODO:
        // THIS IS A DIRTY FILTHY HACK
        // The instance only works because the glyphs are all the same size - hooray monospace.
        // The moment there's something that's NOT, we'll get stretching / skewing / breaking.
        // Solving that.. is for next time.
        // Collections of collections per glyph size? Factored down (scaled) / rotated to deduplicate?
        // ***********************************************************************************
        guard !instanceState.nodes.isEmpty else { return }
        mesh = instanceState.nodes[0].mesh
    }
}
