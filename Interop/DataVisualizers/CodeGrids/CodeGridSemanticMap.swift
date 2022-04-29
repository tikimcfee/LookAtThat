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
typealias AssociatedSyntaxMap = [SyntaxIdentifier: [SyntaxIdentifier: Int]]

public class CodeGridSemanticMap {
	var semanticsLookupBySyntaxId = [SyntaxIdentifier: SemanticInfo]()
	var syntaxIDLookupByNodeId = [NodeID: SyntaxIdentifier]()
    
    var syntaxIdToAssociatedIds = AssociatedSyntaxMap()

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
}

extension CodeGridSemanticMap {
    var allSemanticInfo: [SemanticInfo] {
        return Array(semanticsLookupBySyntaxId.values)
    }
}

extension CodeGridSemanticMap {
    func semanticsFromNodeId(_ nodeId: NodeID?) -> SemanticInfo? {
        guard let nodeId = nodeId,
              let syntaxId = syntaxIDLookupByNodeId[nodeId],
              let syntaxSemantics = semanticsLookupBySyntaxId[syntaxId]
        else { return nil }
        return syntaxSemantics
    }
    
    func parentList(_ nodeId: NodeID) -> [SemanticInfo] {
        var parentList = [SemanticInfo]()
        walkToRootFrom(nodeId) { info in
            parentList.append(info)
        }
        return parentList.reversed()
    }

    func forAllNodesAssociatedWith(
        _ nodeId: SyntaxIdentifier,
        _ cache: CodeGridTokenCache,
        _ walker: (SemanticInfo, NodeSet) throws -> Void
    ) throws {
        // Specifically avoiding a map / map+reduce here to reduce copying
        for (associatedId, _) in syntaxIdToAssociatedIds[nodeId] ?? [:] {
            
            // todo: formalize this little hack around not having trivia have a separate node
            var associatedNodes = cache[associatedId.stringIdentifier]
            associatedNodes.formUnion(cache[associatedId.stringIdentifier + "-leadingTrivia"])
            associatedNodes.formUnion(cache[associatedId.stringIdentifier + "-trailingTrivia"])
            
            if let info = semanticsLookupBySyntaxId[associatedId] {
                do {
                    try walker(info, associatedNodes)
                } catch {
                    print("Semantic association lookup stopped: \(error)")
                    throw error
                }
            }
        }
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
    
    func collectAssociatedNodes(
        _ nodeId: SyntaxIdentifier,
        _ cache: CodeGridTokenCache,
        _ sort: Bool = false
    ) throws -> [(SemanticInfo, SortedNodeSet)] {
        var allFound = [(SemanticInfo, SortedNodeSet)]()
        try forAllNodesAssociatedWith(nodeId, cache, { infoForNodeSet, nodeSet in
            let sortedTopMost = sort ? nodeSet.sorted(by: sortTopLeft) : Array(nodeSet)
            allFound.append((infoForNodeSet, sortedTopMost))
        })
        
        return sort ? allFound.sorted(by: sortTuplesTopLeft) : allFound
    }
    
    func walkToRootFrom(
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
    
	func saveSemanticInfo(_ syntaxId: SyntaxIdentifier,
                          _ nodeId: NodeID,
                          _ makeSemanticInfo: @autoclosure () -> SemanticInfo) {
		guard semanticsLookupBySyntaxId[syntaxId] == nil else { return }
		
        let newInfo = makeSemanticInfo()
		syntaxIDLookupByNodeId[nodeId] = syntaxId
		semanticsLookupBySyntaxId[syntaxId] = newInfo
	}
    
    // Uses a nested dictionary to associate a node with an arbitrary set of
    // other nodes. The first key is lookup for associations. The second is
    // to quickly determine if a given node is associated with the former. 1
    // is a placeholder for hash lookup instead of Set.
    func associate(
        syntax: Syntax,
        withLookupId newValue: SyntaxIdentifier
    ) {
        let syntaxId = syntax.id
        if syntaxIdToAssociatedIds[syntaxId] == nil {
            syntaxIdToAssociatedIds[syntaxId] = [newValue: 1]
            return
        }
        syntaxIdToAssociatedIds[syntaxId]?[newValue] = 1
        
        if let decl = syntax.asProtocol(DeclSyntaxProtocol.self) {
            category(for: decl) { category in
                if category[syntaxId] == nil {
                    category[syntaxId] = [newValue: 1]
                    return
                }
                category[syntaxId]?[newValue] = 1
            }
        }
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
        default:
            break
        }
    }
    
    var isEmpty: Bool {
        semanticsLookupBySyntaxId.isEmpty
        && syntaxIDLookupByNodeId.isEmpty
        && syntaxIdToAssociatedIds.isEmpty
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

