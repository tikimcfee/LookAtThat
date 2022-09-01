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
    typealias Update = (GlyphNode, inout GlyphConstants, inout Bool) throws -> GlyphConstants
    
    func updateAllNodeConstants(_ update: Update) rethrows {
        guard !rootNode.willRebuildState else {
            // To avoid initial update errors, call update() manually
            // if creating nodes, then using their instance positions
            // to do additional work.
            print("Waiting for model build...")
            return
        }
        
        var stopFlag = false
        try forAllNodesInCollection { _, nodeSet in
            if stopFlag { return }
            for node in nodeSet {
                if stopFlag { return }
                try rootNode.updateConstants(for: node) { pointer in
                    let newPointer = try update(node, &pointer, &stopFlag)
                    pointer.modelMatrix = node.modelMatrix
                    return newPointer
                }
            }
        }
    }
    
    private func forAllNodesInCollection(_ operation: ((SemanticInfo, CodeGridNodes)) throws -> Void) rethrows {
        for rootSyntaxNode in consumedRootSyntaxNodes {
            let rootSyntaxId = rootSyntaxNode.id
            try semanticInfoMap.doOnAssociatedNodes(rootSyntaxId, tokenCache, operation)
        }
    }
}
