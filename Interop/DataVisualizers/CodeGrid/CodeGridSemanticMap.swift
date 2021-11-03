//
//  GridInfo.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/26/21.
//

import Foundation
import SwiftSyntax
import SceneKit

typealias SemanticsLookupType = SemanticInfo
typealias SemanticsLookupNodeKey = String
typealias SemanticsLookupSyntaxKey = SyntaxIdentifier

typealias GridAssociationType = Set<SCNNode>
typealias GridAssociationSyntaxToNodeType = [SyntaxIdentifier: GridAssociationType]

public class CodeGridSemanticMap {
	
	// TODO: Having separate caches is kinda lame
	// I'd like to find a way to use a shared key between node look and syntax lookup.
	// I may just need to go back and replace all the SyntaxIdentifier's with simple strings.
	var semanticsLookupBySyntaxId = [SemanticsLookupSyntaxKey: SemanticsLookupType]()
	var semanticsLookupByNodeId = [SemanticsLookupNodeKey: SemanticsLookupSyntaxKey]()
	
	var syntaxIdToTokenNodes = GridAssociationSyntaxToNodeType() // [SyntaxIdentifier: GridAssociationType]

	var structs = GridAssociationSyntaxToNodeType()
	var classes = GridAssociationSyntaxToNodeType()
	var enumerations = GridAssociationSyntaxToNodeType()
	var functions = GridAssociationSyntaxToNodeType()
	var variables = GridAssociationSyntaxToNodeType()
	var typeAliases = GridAssociationSyntaxToNodeType()
	var protocols = GridAssociationSyntaxToNodeType()
	var initializers = GridAssociationSyntaxToNodeType()
	var deinitializers = GridAssociationSyntaxToNodeType()
	var extensions = GridAssociationSyntaxToNodeType()
	
	static func + (left: CodeGridSemanticMap, right: CodeGridSemanticMap) -> CodeGridSemanticMap {
		
		left.syntaxIdToTokenNodes.merge(right.syntaxIdToTokenNodes, uniquingKeysWith: takeLeft)
		left.structs.merge(right.structs, uniquingKeysWith: takeLeft)
		left.classes.merge(right.classes, uniquingKeysWith: takeLeft)
		left.enumerations.merge(right.enumerations, uniquingKeysWith: takeLeft)
		left.functions.merge(right.functions, uniquingKeysWith: takeLeft)
		left.variables.merge(right.variables, uniquingKeysWith: takeLeft)
		left.typeAliases.merge(right.typeAliases, uniquingKeysWith: takeLeft)
		left.protocols.merge(right.protocols, uniquingKeysWith: takeLeft)
		left.initializers.merge(right.initializers, uniquingKeysWith: takeLeft)
		left.deinitializers.merge(right.deinitializers, uniquingKeysWith: takeLeft)
		left.extensions.merge(right.extensions, uniquingKeysWith: takeLeft)
		
		return left
	}
	
	private static func takeLeft(_ left: GridAssociationType,  _ right: GridAssociationType) -> GridAssociationType {
		print("<!> Duplicated gridAssociations key -> \(left.map { $0.name }), \(right.map { $0.name })")
		return left
	}
}

extension CodeGridSemanticMap {
    func tokenNodes(_ syntaxId: SyntaxIdentifier) -> GridAssociationType? {
		syntaxIdToTokenNodes[syntaxId]
	}
	
	func semanticsFromNodeId(_ nodeId: SemanticsLookupNodeKey?) -> SemanticInfo? {
		guard let nodeId = nodeId,
			  let syntaxId = semanticsLookupByNodeId[nodeId],
			  let syntaxSemantics = semanticsLookupBySyntaxId[syntaxId]
		else { return nil }
		return syntaxSemantics
	}
    
    func parentList(_ nodeId: SemanticsLookupNodeKey) -> [SemanticInfo] {
        var parentList = [SemanticInfo]()
        walkToRootFrom(nodeId) { info in
            parentList.append(info)
        }
        return parentList
    }
    
    func walkToRootFrom(_ nodeId: SemanticsLookupNodeKey?, _ walker: (SemanticInfo) -> Void) {
        guard let nodeId = nodeId,
              let syntaxId = semanticsLookupByNodeId[nodeId]else {
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
	
	func mergeSemanticInfo(_ syntaxId: SemanticsLookupSyntaxKey, 
						   _ nodeId: SemanticsLookupNodeKey,
						   _ semanticInfo: @autoclosure () -> SemanticInfo) {
		guard semanticsLookupBySyntaxId[syntaxId] == nil else { return }
		let newInfo = semanticInfo()
		
		semanticsLookupByNodeId[nodeId] = syntaxId
		semanticsLookupBySyntaxId[syntaxId] = newInfo
	}
	
	func mergeSyntaxAssociations(_ syntax: Syntax, _ newValue: GridAssociationType?) {
		let syntaxId = syntax.id
		let existingSyntaxAssociations = syntaxIdToTokenNodes[syntaxId] ?? []
		syntaxIdToTokenNodes[syntaxId] = existingSyntaxAssociations.union(newValue ?? [])
		
		if let decl = syntax.asProtocol(DeclSyntaxProtocol.self) {
			category(for: decl) { category in
				let existing = category[syntaxId] ?? [] 
				category[syntaxId] = existing.union(newValue ?? [])
			}
		}
	}
	
	func category(for syntax: DeclSyntaxProtocol,
					   _ action: (inout GridAssociationSyntaxToNodeType) -> Void) {
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
}

