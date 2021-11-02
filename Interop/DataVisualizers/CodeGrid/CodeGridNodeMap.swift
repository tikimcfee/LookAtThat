//
//  GridInfo.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/26/21.
//

import Foundation
import SwiftSyntax
import SceneKit

typealias GridAssociationType = Set<SCNNode>
typealias GridAssociationSyntaxToNodeType = [SyntaxIdentifier: GridAssociationType]

struct RenderedCodeGrid {
	let sourceFile: URL
	let semanticInfo: SemanticInfo
	
	let associatedNodes: GridAssociationType
}

public class CodeGridNodeMap {
	
	class Cache {
		var syntexIdToSyntaxNodeSetMap: [SyntaxIdentifier: Set<SCNNode>] = [:]
		var syntexIdToSemanticInf: [SyntaxIdentifier: SemanticInfo] = [:]
	}
	
	var syntaxIdToSemanticInfo = [SyntaxIdentifier: SemanticInfo]()
	var syntaxToGridAssociation = GridAssociationSyntaxToNodeType()

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
	
	static func + (left: CodeGridNodeMap, right: CodeGridNodeMap) -> CodeGridNodeMap {
		
		func takeLeft(_ left: GridAssociationType, 
					  _ right: GridAssociationType) -> GridAssociationType {
			print("<!> Duplicated gridAssociations key -> \(left.map { $0.name }), \(right.map { $0.name })")
			return left
		}
		
		left.syntaxToGridAssociation.merge(right.syntaxToGridAssociation, uniquingKeysWith: takeLeft)
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
}

extension CodeGridNodeMap {
	subscript(_ syntaxId: SyntaxIdentifier) -> GridAssociationType? {
		get { syntaxToGridAssociation[syntaxId] }
	}
		
	subscript(_ syntax: Syntax) -> GridAssociationType? {
		get { syntaxToGridAssociation[syntax.id] }
		set { mergeSyntaxAssociations(syntax, newValue) }
	}
	
	private func mergeSyntaxAssociations(_ syntax: Syntax, _ newValue: GridAssociationType?) {
		let syntaxId = syntax.id
		let existingSyntaxAssociations = syntaxToGridAssociation[syntaxId] ?? []
		syntaxToGridAssociation[syntaxId] = existingSyntaxAssociations.union(newValue ?? [])
		
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

