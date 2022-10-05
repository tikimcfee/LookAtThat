//
//  CodeGridGlyphCollectionBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/27/22.
//

import simd
import Foundation

extension CodeGridGlyphCollectionBuilder {
    enum Mode {
//        case monoCollection
        case multiCollection
    }
}

typealias ParentSource = (inout VirtualParentConstants) -> Void
typealias ParentUpdater = (ParentSource) -> Void

class CodeGridGlyphCollectionBuilder {
    let link: MetalLink
    let atlas: MetalLinkAtlas
    let semanticMap: SemanticInfoMap
    let tokenCache: CodeGridTokenCache
    let gridCache: GridCache
    let parentBuffer: BackingBuffer<VirtualParentConstants>
    
    var mode: Mode = .multiCollection
    private lazy var monoCollection = makeMonoCollection()
    
    init(
        link: MetalLink,
        sharedSemanticMap semanticMap: SemanticInfoMap,
        sharedTokenCache tokenCache: CodeGridTokenCache,
        sharedGridCache gridCache: GridCache
    ) throws {
        self.link = link
        self.atlas = GlobalInstances.defaultAtlas
        self.semanticMap = semanticMap
        self.tokenCache = tokenCache
        self.gridCache = gridCache
        self.parentBuffer = try BackingBuffer<VirtualParentConstants>(link: link, initialSize: 256)
        
        // create the first buffer item and set it as identity.
        // this might let 0-parents have an identity to multiply.
        // Not tested, just a hypothesis
        _ = try parentBuffer.createNext {
            $0.modelMatrix = matrix_identity_float4x4
        }
    }
    
    private func makeMonoCollection() -> GlyphCollection {
        try! GlyphCollection(link: link, linkAtlas: atlas)
    }
    
    func getCollection() -> GlyphCollection {
        switch mode {
        case .multiCollection:
            return try! GlyphCollection(link: link, linkAtlas: atlas)
        }
    }
    
    func createGrid() -> CodeGrid {
        let grid = CodeGrid(rootNode: getCollection(), tokenCache: tokenCache)
        gridCache.cachedGrids[grid.id] = grid

//        switch mode {
//        case .multiCollection:
//            break
//        }
        
        // TODO: This is whacky and gross. I love it and hate it. Make parent buffers better.
        let parent = try! parentBuffer.createNext()
        func updateParent(_ operation: (inout VirtualParentConstants) -> Void) {
            operation(&parentBuffer.pointer[parent.arrayIndex])
        }
        grid.updateVirtualParentConstants = updateParent(_:)
        
        return grid
    }
    
    func createConsumerForNewGrid() -> GlyphCollectionSyntaxConsumer {
        GlyphCollectionSyntaxConsumer(targetGrid: createGrid())
    }
    
    func makeVirtualParent() -> VirtualGlyphParent {
        let node = VirtualGlyphParent(
            parentGlyphCollection: monoCollection
        )
        monoCollection.add(child: node)
        return node
    }
}


class VirtualGlyphParent: MetalLinkNode {
    let parentGlyphCollection: GlyphCollection
    
    private var instances: [MetalLinkGlyphNode] {
        children as! [MetalLinkGlyphNode]
    }
    
    init(parentGlyphCollection: GlyphCollection) {
        self.parentGlyphCollection = parentGlyphCollection
    }
    
    override func render(in sdp: inout SafeDrawPass) {
        // super.render(in: &sdp)
        // virtual nodes don't render
    }
   
    override func update(deltaTime: Float) {
//        defer { super.update(deltaTime: deltaTime) }
//
//        guard willUpdate else { return }
//        updateRepresentedConstants()
    }
    
    func updateRepresentedConstants() {
        // TODO: this can likely be threaded easily, or pooled up
        parentGlyphCollection.updatePointer { pointer in
            for instance in instances {
                guard let index = instance.meta.instanceBufferIndex else { continue }
                pointer[index].modelMatrix = matrix_multiply(self.modelMatrix, instance.modelMatrix)
            }
        }
    }
}
