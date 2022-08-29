//
//  SemanticInfoMap+Iteration.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/28/22.
//

import Foundation
import SwiftSyntax

// MARK: - Associated Nodes for ID

extension SemanticInfoMap {
    func doOnAssociatedNodes(
        _ nodeId: SyntaxIdentifier,
        _ cache: CodeGridTokenCache,
        _ receiver: ((SemanticInfo, CodeGridNodes)) -> Void
    ) {
        walkFlattenedNonEscaping(from: nodeId, in: cache) { infoForNodeSet, nodeSet in
            receiver((infoForNodeSet, nodeSet))
        }
    }
    
    func collectAssociatedNodes(
        _ nodeId: SyntaxIdentifier,
        _ cache: CodeGridTokenCache,
        _ sort: Bool = false
    ) throws -> [(SemanticInfo, SortedNodeSet)] {
        var allFound = [(SemanticInfo, SortedNodeSet)]()
        
        walkFlattened(from: nodeId, in: cache) { infoForNodeSet, nodeSet in
            let sortedTopMost = sort ? nodeSet.sorted(by: self.sortTopLeft) : Array(nodeSet)
            allFound.append((infoForNodeSet, sortedTopMost))
        }
        
        return sort ? allFound.sorted(by: sortTuplesTopLeft) : allFound
    }
    
    func tokenNodes(
        from syntaxIdentifer: SyntaxIdentifier,
        in cache: CodeGridTokenCache,
        _ walker: @escaping (SemanticInfo, CodeGridNodes) throws -> Void
    ) rethrows {
        // Just get all nodes directly underneath this one
        guard let originalSynax = flattenedSyntax[syntaxIdentifer] else {
            print("Cache missing on id: \(syntaxIdentifer)")
            return
        }
        
        try originalSynax.tokens.forEach { token in
            let tokenId = token.id
            guard let info = semanticsLookupBySyntaxId[tokenId] else { return }
            
            try walker(info, cache[tokenId.stringIdentifier])
        }
    }
    
    func walkFlattened(
        from syntaxIdentifer: SyntaxIdentifier,
        in cache: CodeGridTokenCache,
        _ walker: @escaping (SemanticInfo, CodeGridNodes) throws -> Void
    ) rethrows {
        guard let toWalk = flattenedSyntax[syntaxIdentifer] else {
            print("Cache missing on id: \(syntaxIdentifer)")
            return
        }
        
        IterativeRecursiveVisitor.walkRecursiveFromSyntax(toWalk) { [semanticsLookupBySyntaxId] syntax in
            let syntaxId = syntax.id
            guard let info = semanticsLookupBySyntaxId[syntaxId] else { return }
            
            try walker(info, cache[syntaxId.stringIdentifier])
        }
    }
    
    func walkFlattenedNonEscaping(
        from syntaxIdentifer: SyntaxIdentifier,
        in cache: CodeGridTokenCache,
        _ walker: (SemanticInfo, CodeGridNodes) throws -> Void
    ) rethrows {
        guard let toWalk = flattenedSyntax[syntaxIdentifer] else {
            print("Cache missing on id: \(syntaxIdentifer)")
            return
        }
        
        IterativeRecursiveVisitor.walkRecursiveFromSyntax(toWalk) { [semanticsLookupBySyntaxId] syntax in
            let syntaxId = syntax.id
            guard let info = semanticsLookupBySyntaxId[syntaxId] else { return }
            
            try walker(info, cache[syntaxId.stringIdentifier])
        }
    }
}

// MARK: Parent Hierarchy from ID

extension SemanticInfoMap {
    func parentList(
        _ nodeId: NodeID,
        _ reversed: Bool = false
    ) -> [SemanticInfo] {
        var parentList = [SemanticInfo]()
        walkToRootFrom(nodeId) { info in
            parentList.append(info)
        }
        return reversed ? parentList.reversed() : parentList
    }
    
    private func walkToRootFrom(
        _ nodeId: NodeID?,
        _ walker: (SemanticInfo) -> Void
    ) {
        guard let nodeId = nodeId,
              let syntaxId = syntaxIDLookupByNodeId[nodeId] else {
            return
        }
        
        var maybeSemantics: SemanticInfo? = semanticsLookupBySyntaxId[syntaxId]
        while let semantics = maybeSemantics {
            walker(semantics)
            if let maybeParentId = semantics.node.parent?.id {
                maybeSemantics = semanticsLookupBySyntaxId[maybeParentId]
            } else {
                maybeSemantics = nil
            }
        }
    }
}
