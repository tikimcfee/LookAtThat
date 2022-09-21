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
    
    override var contentSize: LFloat3 {
        return BoundsSize(rectPos)
    }
    
    init(
        link: MetalLink,
        linkAtlas: MetalLinkAtlas
    ) throws {
        self.linkAtlas = linkAtlas
        try super.init(link, mesh: link.meshLibrary[.Quad])
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
    subscript(glyphID: InstanceIDType) -> MetalLinkGlyphNode? {
        instanceState.instanceIdNodeLookup[glyphID]
    }
}

extension MetalLinkInstancedObject
where InstancedNodeType == MetalLinkGlyphNode {
    func updatePointer(
        _ operation: (inout UnsafeMutablePointer<InstancedConstants>) throws -> Void
    ) {
        do {
            try operation(&instanceState.rawPointer)
        } catch {
            print("pointer operation update failed")
            print(error)
        }
    }
    
    func updateConstants(
        for node: InstancedNodeType,
        _ operation: (inout InstancedConstants) throws -> InstancedConstants
    ) rethrows {
        guard let bufferIndex = node.meta.instanceBufferIndex
        else {
            print("Missing buffer index for [\(node.key.source)]: \(node.nodeId)")
            return
        }
        
        guard instanceState.indexValid(bufferIndex)
        else {
            print("Invalid buffer index for \(node.nodeId)")
            return
        }
        
        // This may be unsafe... not sure what happens here with multithreading.
        // Probably very bad things. If there's a crash here, just create a copy
        // and don't be too fancy.
        let pointer = instanceState.rawPointer
        pointer[bufferIndex] = try operation(&pointer[bufferIndex])
    }
}

extension GlyphCollection {
    func setRootMesh() {
        // ***********************************************************************************
        // TODO: mesh instance hack
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
