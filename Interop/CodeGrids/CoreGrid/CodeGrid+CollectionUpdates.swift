//
//  CodeGrid+CollectionUpdates.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/27/22.
//

import Foundation
import SwiftSyntax

// MARK: - Collection Updates

extension CodeGrid {
    @inline(__always)
    func updateAllNodeConstants(_ update: UpdateConstants) rethrows {
        var stopFlag = false
        try forAllNodesInCollection { _, nodeSet in
            if stopFlag { return }
            for node in nodeSet {
                if stopFlag { return }
                try update(node, &stopFlag)
            }
        }
    }
    
    @inline(__always)
    func updateAssociatedNodes(
        _ targetSyntaxID: SyntaxIdentifier,
        _ update: UpdateConstants
    ) rethrows {
        var stopFlag = false
        try semanticInfoMap.doOnAssociatedNodes(targetSyntaxID, tokenCache) { info, nodeSet in
            if stopFlag { return }
            for node in nodeSet {
                if stopFlag { return }
                try update(node, &stopFlag)
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
