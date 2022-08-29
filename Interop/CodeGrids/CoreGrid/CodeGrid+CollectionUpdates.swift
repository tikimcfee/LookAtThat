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
            // TODO: This is bad news. It means we haven't updated the buffer indices yet.
            // There should be a thing that does this before the first render.
            // Ideally, get rid of the whole mapping thing and figure out direct calling.
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
