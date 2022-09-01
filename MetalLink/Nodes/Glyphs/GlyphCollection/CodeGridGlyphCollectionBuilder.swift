//
//  CodeGridGlyphCollectionBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/27/22.
//

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
        return grid
    }
    
    func createConsumerForNewGrid() -> GlyphCollectionSyntaxConsumer {
        GlyphCollectionSyntaxConsumer(targetGrid: createGrid())
    }
}
