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
    
    var mode: Mode = .monoCollection
    private lazy var monoCollection = GlyphCollection(link: link, linkAtlas: atlas)
    
    init(
        link: MetalLink,
        sharedSemanticMap semanticMap: SemanticInfoMap = .init(),
        sharedTokenCache tokenCache: CodeGridTokenCache = .init()
    ) {
        self.link = link
        self.atlas = GlobalInstances.defaultAtlas
        self.semanticMap = semanticMap
        self.tokenCache = tokenCache
    }
    
    func getCollection() -> GlyphCollection {
        switch mode {
        case .monoCollection:   return monoCollection
        case .multiCollection:  return GlyphCollection(link: link, linkAtlas: atlas)
        }
    }
    
    func createGrid() -> CodeGrid {
        CodeGrid(rootNode: getCollection(), tokenCache: tokenCache)
    }
    
    func createConsumerForNewGrid() -> GlyphCollectionSyntaxConsumer {
        GlyphCollectionSyntaxConsumer(targetGrid: createGrid())
    }
}
