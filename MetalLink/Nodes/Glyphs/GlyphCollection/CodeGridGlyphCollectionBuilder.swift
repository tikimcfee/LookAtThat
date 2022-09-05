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
        case monoCollection
        case multiCollection
    }
}

class CodeGridGlyphCollectionBuilder {
    let link: MetalLink
    let atlas: MetalLinkAtlas
    let semanticMap: SemanticInfoMap
    let tokenCache: CodeGridTokenCache
    let gridCache: GridCache
    
    var mode: Mode = .monoCollection
    private lazy var monoCollection = GlyphCollection(link: link, linkAtlas: atlas)
    
    init(
        link: MetalLink,
        sharedSemanticMap semanticMap: SemanticInfoMap,
        sharedTokenCache tokenCache: CodeGridTokenCache,
        sharedGridCache gridCache: GridCache
    ) {
        self.link = link
        self.atlas = GlobalInstances.defaultAtlas
        self.semanticMap = semanticMap
        self.tokenCache = tokenCache
        self.gridCache = gridCache
    }
    
    func getCollection() -> GlyphCollection {
        switch mode {
        case .monoCollection:   return monoCollection
        case .multiCollection:  return GlyphCollection(link: link, linkAtlas: atlas)
        }
    }
    
    func createGrid() -> CodeGrid {
        let grid = CodeGrid(rootNode: getCollection(), tokenCache: tokenCache)
        gridCache.cachedGrids[grid.id] = grid
        switch mode {
        case .monoCollection:
            let node = makeVirtualParent()
            grid.virtualParent = node
            break
        case .multiCollection:
            break
        }
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
        defer { super.update(deltaTime: deltaTime) }
        
        guard willUpdate else { return }
        updateRepresentedConstants()
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
