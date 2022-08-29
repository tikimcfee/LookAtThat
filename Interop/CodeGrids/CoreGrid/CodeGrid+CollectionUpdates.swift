//
//  CodeGrid+CollectionUpdates.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/27/22.
//

import Foundation

// MARK: - Collection Updates

extension CodeGrid {
    typealias GlyphConstants = MetalLinkInstancedObject<MetalLinkGlyphNode>.InstancedConstants
    typealias Update = (GlyphNode, inout GlyphConstants) -> GlyphConstants
    
    func updateAllNodeConstants(_ update: Update) {
        guard !rootNode.willRebuildState else {
            // To avoid initial update errors, call update() manually
            // if creating nodes, then using their instance positions
            // to do additional work.
            print("Waiting for model build...")
            return
        }
        
        forAllNodesInCollection { _, nodeSet in
            for node in nodeSet {
                rootNode.updateConstants(for: node) { pointer in
                    let newPointer = update(node, &pointer)
                    pointer.modelMatrix = node.modelMatrix
                    return newPointer
                }
            }
        }
    }
    
    private func forAllNodesInCollection(_ operation: ((SemanticInfo, CodeGridNodes)) -> Void) { 
        for rootSyntaxNode in consumedRootSyntaxNodes {
            let rootSyntaxId = rootSyntaxNode.id
            semanticInfoMap.doOnAssociatedNodes(rootSyntaxId, tokenCache, operation)
        }
    }
}
