//
//  GlyphCollection.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/11/22.
//

import MetalKit

// ----------------------------------

class GlyphCollection: MetalLinkInstancedObject<LinkNode> {
    var textBody: String
    var linkNodeCache: LinkNodeCache
    
    init(link: MetalLink, text: String) throws {
        self.textBody = text
        
        let cache = LinkNodeCache(link: link)
        self.linkNodeCache = cache
        
        try super.init(link, mesh: link.meshes[.Quad], instances: {
            text.compactMap { char in
                cache.create(.init(String(char), .red))
            }
        })
        
        setupNodes()
    }
    
    func setupNodes() {
        var xOffset = Float(0.0)
        
        var last: LinkNode?
        instancedNodes.enumerated().forEach { index, node in
            xOffset += (last?.quad.width ?? 0) / 2.0 + node.quad.width / 2.0
            node.position.z -= 5
            node.position.x += xOffset + 0.2
            
            instancedConstants[index].color = LFloat4.random_color()
            
            last = node
        }
    }
    
    private var _time: Float = 0
    private func time(_ dT: Float) -> Float { _time += dT; return _time }
    
    override func update(deltaTime dT: Float) {
        //        rotation.x -= dT / 2
        //        rotation.y -= dT / 2
        
        pushModelConstants = true
        super.update(deltaTime: dT)
    }
    
    override func performJITInstanceBufferUpdate(_ node: MetalLinkNode) {
        node.rotation.x -= 0.0167 * 2
        node.rotation.y -= 0.0167 * 2
    }
}
