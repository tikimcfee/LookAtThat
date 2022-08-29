//
//  CodeGrid+CollectionUpdates.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/27/22.
//

import Foundation

// MARK: - Collection Updates

extension CodeGrid {
    func forAllNodesInCollection(_ operation: ((SemanticInfo, CodeGridNodes)) -> Void) {
        // TODO: Oof multiple consumed files is torture, and wrong...
        for rootSyntaxNode in consumedRootSyntaxNodes {
            let rootSyntaxId = rootSyntaxNode.id
            semanticInfoMap.doOnAssociatedNodes(rootSyntaxId, tokenCache, operation)
        }
    }
}

extension CodeGrid {
    typealias GlyphConstants = MetalLinkInstancedObject<MetalLinkGlyphNode>.InstancedConstants
    typealias Update = (inout GlyphConstants) -> GlyphConstants
    
    func updateAllNodeConstants(_ update: Update) {
        guard !rootNode.willRebuildState else {
            print("Waiting for model build...")
            return
        }
        
        forAllNodesInCollection { _, nodeSet in
            for node in nodeSet {
                rootNode.updateConstants(for: node) { pointer in
                    return update(&pointer)
                }
            }
        }
    }
}
