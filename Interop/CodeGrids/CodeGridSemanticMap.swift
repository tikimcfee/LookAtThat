//
//  GridInfo.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/26/21.
//

import Foundation
import SwiftSyntax
import SceneKit

typealias NodeID = String
typealias NodeSet = Set<SCNNode>
typealias SortedNodeSet = [SCNNode]
typealias AssociatedSyntaxSet = Set<SyntaxIdentifier>
typealias AssociatedSyntaxMap = [SyntaxIdentifier: [SyntaxIdentifier: Int]]

public struct CodeGridGlobalSemantics {
    let source: GridCache
    
    func forEachMap(
        _ receiver: (CodeGridSemanticMap) -> Void
    ) {
        source.cachedGrids.directWriteAccess { mutableGridStore in
            for (_, cacheValue) in mutableGridStore {
                receiver(cacheValue.source.codeGridSemanticInfo)
            }
        }
    }
    
    func forEachCategory(
        _ category: CodeGridSemanticMap.Category,
        _ receiver: (inout AssociatedSyntaxMap) -> Void)
    {
        source.cachedGrids.directWriteAccess { mutableGridStore in
            for (_, cacheValue) in mutableGridStore {
                cacheValue.source.codeGridSemanticInfo.category(category, receiver)
            }
        }
    }
}

public class CodeGridSemanticMap {
    
    // MARK: - Core association sets
    
    // TODO: *1 = these can be merged! SemanticInfo wraps Syntax
    var flattenedSyntax = [SyntaxIdentifier: Syntax]()  //TODO: *1
    var semanticsLookupBySyntaxId = [SyntaxIdentifier: SemanticInfo]()  //TODO: *1
    var syntaxIDLookupByNodeId = [NodeID: SyntaxIdentifier]()

    // MARK: - Categories
	var structs = AssociatedSyntaxMap()
	var classes = AssociatedSyntaxMap()
	var enumerations = AssociatedSyntaxMap()
	var functions = AssociatedSyntaxMap()
	var variables = AssociatedSyntaxMap()
	var typeAliases = AssociatedSyntaxMap()
	var protocols = AssociatedSyntaxMap()
	var initializers = AssociatedSyntaxMap()
	var deinitializers = AssociatedSyntaxMap()
	var extensions = AssociatedSyntaxMap()
    var switches = AssociatedSyntaxMap()
}

extension CodeGridSemanticMap {
    enum Category: String, CaseIterable {
        case structs
        case classes
        case enumerations
        case functions
        case variables
        case typeAliases
        case protocols
        case initializers
        case deinitializers
        case extensions
        case switches
    }
    
    func category(
        _ category: CodeGridSemanticMap.Category,
        _ receiver: (inout AssociatedSyntaxMap) -> Void
    ) {
        switch category {
        case .structs: receiver(&structs)
        case .classes: receiver(&classes)
        case .enumerations: receiver(&enumerations)
        case .functions: receiver(&functions)
        case .variables: receiver(&variables)
        case .typeAliases: receiver(&typeAliases)
        case .protocols: receiver(&protocols)
        case .initializers: receiver(&initializers)
        case .deinitializers: receiver(&deinitializers)
        case .extensions: receiver(&extensions)
        case .switches: receiver(&switches)
        }
    }
}

// MARK: - Simplified mapping

extension CodeGridSemanticMap {
    func addFlattened(_ syntax: Syntax) {
        flattenedSyntax[syntax.id] = syntax
    }
    
    func insertSemanticInfo(_ id: SyntaxIdentifier, _ info: SemanticInfo) {
        semanticsLookupBySyntaxId[id] = info
    }
    
    func insertNodeInfo(_ nodeId: NodeID, _ syntaxId: SyntaxIdentifier) {
        syntaxIDLookupByNodeId[nodeId] = syntaxId
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
            try walker(info, cache[tokenId.stringIdentifier + "-leadingTrivia"])
            try walker(info, cache[tokenId.stringIdentifier + "-trailingTriva"])
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
        
        StateCapturingVisitor(onVisitAnyPost: { [semanticsLookupBySyntaxId] syntax in
            let syntaxId = syntax.id
            guard let info = semanticsLookupBySyntaxId[syntaxId] else { return }
            
            try walker(info, cache[syntaxId.stringIdentifier])
            try walker(info, cache[syntaxId.stringIdentifier + "-leadingTrivia"])
            try walker(info, cache[syntaxId.stringIdentifier + "-trailingTriva"])
        }).walk(toWalk)
    }
}

extension CodeGridSemanticMap {
    var allSemanticInfo: [SemanticInfo] {
        return Array(semanticsLookupBySyntaxId.values)
    }
}

// MARK: Parent Hierarchy

extension CodeGridSemanticMap {
    func parentList(_ nodeId: NodeID, _ reversed: Bool = false) -> [SemanticInfo] {
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

// MARK: Node Sorting

extension CodeGridSemanticMap {
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
    
    private func sortTopLeft(_ left: SCNNode, _ right: SCNNode) -> Bool {
        return left.position.y > right.position.y
        && left.position.x < right.position.x
    }
    
    private func sortTuplesTopLeft(
        _ left: (SemanticInfo, SortedNodeSet),
        _ right: (SemanticInfo, SortedNodeSet)
    ) -> Bool {
        guard let left = left.1.first else { return false }
        guard let right = right.1.first else { return true }
        return sortTopLeft(left, right)
    }
    
}

// MARK: - Major Categories

extension CodeGridSemanticMap {
    func category(
        for syntax: DeclSyntaxProtocol,
        _ action: (inout AssociatedSyntaxMap) -> Void)
    {
        switch syntax.syntaxNodeType {
        case is ProtocolDeclSyntax.Type:
            action(&protocols)
        case is TypealiasDeclSyntax.Type:
            action(&typeAliases)
        case is VariableDeclSyntax.Type:
            action(&variables)
        case is ClassDeclSyntax.Type:
            action(&classes)
        case is EnumDeclSyntax.Type:
            action(&enumerations)
        case is ExtensionDeclSyntax.Type:
            action(&extensions)
        case is FunctionDeclSyntax.Type:
            action(&functions)
        case is StructDeclSyntax.Type:
            action(&structs)
        case is SwitchStmtSyntax.Type:
            action(&switches)
        default:
            break
        }
    }
    
    func category(
        for syntaxEnum: SyntaxEnum,
        _ action: (inout AssociatedSyntaxMap) -> Void)
    {
        switch syntaxEnum {
        case .protocolDecl:
            action(&protocols)
        case .typealiasDecl:
            action(&typeAliases)
        case .variableDecl:
            action(&variables)
        case .classDecl:
            action(&classes)
        case .enumDecl:
            action(&enumerations)
        case .extensionDecl:
            action(&extensions)
        case .functionDecl:
            action(&functions)
        case .structDecl:
            action(&structs)
        default:
            break
        }
    }
    
    var isEmpty: Bool {
        semanticsLookupBySyntaxId.isEmpty
        && syntaxIDLookupByNodeId.isEmpty
        && structs.isEmpty
        && classes.isEmpty
        && enumerations.isEmpty
        && functions.isEmpty
        && variables.isEmpty
        && typeAliases.isEmpty
        && protocols.isEmpty
        && initializers.isEmpty
        && deinitializers.isEmpty
        && extensions.isEmpty
    }
}

