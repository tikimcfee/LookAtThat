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
    typealias Update = (GlyphNode, inout GlyphConstants, inout Bool) -> GlyphConstants
    
    func updateAllNodeConstants(_ update: Update) {
        guard !rootNode.willRebuildState else {
            // To avoid initial update errors, call update() manually
            // if creating nodes, then using their instance positions
            // to do additional work.
            print("Waiting for model build...")
            return
        }
        
        var stopFlag = false
        forAllNodesInCollection { _, nodeSet in
            if stopFlag { return }
            for node in nodeSet {
                if stopFlag { return }
                rootNode.updateConstants(for: node) { pointer in
                    let newPointer = update(node, &pointer, &stopFlag)
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
