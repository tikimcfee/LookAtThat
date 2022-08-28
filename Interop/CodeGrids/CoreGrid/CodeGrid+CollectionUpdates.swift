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
        // TODO: Oof multiple consumed files is torture
        guard let rootId = consumedRootSyntaxNodes.first?.id
        else {
            print("No root nodes to find nodes")
            return
        }
        codeGridSemanticInfo.doOnAssociatedNodes(rootId, tokenCache, operation)
    }
}

extension CodeGrid {
    typealias GlyphConstants = MetalLinkInstancedObject<MetalLinkGlyphNode>.InstancedConstants
    typealias Update = (inout GlyphConstants) -> GlyphConstants
    
    func updateAllNodeConstants(_ update: Update) {
        forAllNodesInCollection { _, nodeSet in
            for node in nodeSet {
                rootNode.updateConstants(for: node) { pointer in
                    return update(&pointer)
                }
            }
        }
    }
}
