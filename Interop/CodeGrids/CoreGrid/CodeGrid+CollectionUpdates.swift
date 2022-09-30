//
//  CodeGrid+CollectionUpdates.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/27/22.
//

import Foundation

// MARK: - Collection Updates

extension CodeGrid {
    @inline(__always)
    func updateAllNodeConstants(_ update: UpdateConstants) rethrows {
        var stopFlag = false
        try forAllNodesInCollection { _, nodeSet in
            if stopFlag { return }
            for node in nodeSet {
                if stopFlag { return }
                try rootNode.updateConstants(for: node) { pointer in
                    try update(node, &pointer, &stopFlag)
                }
            }
        }
    }
    
    @inline(__always)
    private func forAllNodesInCollection(_ operation: ((SemanticInfo, CodeGridNodes)) throws -> Void) rethrows {
        for rootSyntaxNode in consumedRootSyntaxNodes {
            let rootSyntaxId = rootSyntaxNode.id
            try semanticInfoMap.doOnAssociatedNodes(rootSyntaxId, tokenCache, operation)
        }
    }
}
