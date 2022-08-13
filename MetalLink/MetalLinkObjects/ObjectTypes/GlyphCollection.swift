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
    var linkNodeCache: MetalLinkGlyphNodeCache
    
    init(link: MetalLink, text: String) throws {
        self.textBody = text
        
        let cache = MetalLinkGlyphNodeCache(link: link)
        self.linkNodeCache = cache
        
        try super.init(link, mesh: link.meshes[.Quad], instances: {
            text.compactMap { char in
                cache.create(.init(String(char), .red))
            }
        })
        
        setupNodes()
    }
    
    func setupNodes() {
        let left = Float(0.0)
        let top = Float(0.0)
        let front = Float(-5.0)
        var xOffset = Float(left)
        var yOffset = Float(top)
        var zOffset = Float(front)
        
        var last: MetalLinkGlyphNode?
        instancedNodes.enumerated().forEach { index, node in
            xOffset += (last?.quad.width ?? 0) / 2.0 + node.quad.width / 2.0
            node.position.z = zOffset + 1
            node.position.x = xOffset + 1
            node.position.y = yOffset + 2
            
            instancedConstants[index].color = LFloat4.random_color()
            instancedConstants[index].textureIndex = node.constants.textureIndex
            
            last = node
            
            guard index >= 1 else { return }
            if index % 100 == 0 {
                xOffset = left
                yOffset -= 2.2
            }
            
            if index % (100 * 100) == 0 {
                zOffset -= 10.0
                yOffset = top
            }
        }
        
        mesh = last!.mesh
    }
    
    private var _time: Float = 0
    private func time(_ dT: Float) -> Float { _time += dT; return _time }
    
    override func update(deltaTime dT: Float) {
        //        rotation.x -= dT / 2
        //        rotation.y -= dT / 2
        
//        pushModelConstants = true
        super.update(deltaTime: dT)
    }
    
    override func performJITInstanceBufferUpdate(_ node: MetalLinkNode) {
        node.rotation.x -= 0.0167 * 2
        node.rotation.y -= 0.0167 * 2
    }
}
