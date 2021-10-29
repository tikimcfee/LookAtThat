//
//  SemanticInfoBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/28/21.
//

import Foundation
import SwiftSyntax

// I want to find all the functions
// I want to find all the functions that take strings
// I want to find all the functions that take strings and return strings

struct SemanticInfo: Hashable, CustomStringConvertible {
	let syntaxId: SyntaxIdentifier
	
	// Refer to this semantic info by this name; it's displayable
	let referenceName: String
	let syntaxTypeName: String
	
	var description: String {
		"\(syntaxTypeName)~>[\(referenceName)]"
	}
}

class SemanticInfoBuilder {
	private let localSemanticCache = SyntaxCache()
	
	func semanticInfo(for node: Syntax) -> SemanticInfo {
		switch self[node] {
			case .variableDecl(let varl):
				var name = "(unsupported syntax: \(varl.id)"
				if let firstBinding = varl.bindings.first {
					let typeName = firstBinding.typeAnnotation?.description ?? ""
					let pattern = firstBinding.pattern.description
					name = "\(varl.letOrVarKeyword.text) \(pattern)\(typeName)"
				}
				return SemanticInfo(
					syntaxId: node.id,
					referenceName: name, 
					syntaxTypeName: String(describing: varl.syntaxNodeType)
				)
			case .extensionDecl(let extenl):
				return SemanticInfo(
					syntaxId: node.id, 
					referenceName: "\(extenl.extendedType.description)+\(node.id.hashValue)", 
					syntaxTypeName: String(describing: extenl.syntaxNodeType)
				)
			case .classDecl(let classl):
				return SemanticInfo(
					syntaxId: node.id, 
					referenceName: "\(classl.identifier)", 
					syntaxTypeName: String(describing: classl.syntaxNodeType)
				)
			case .structDecl(let structl):
				return SemanticInfo(
					syntaxId: node.id, 
					referenceName: "\(structl.identifier)", 
					syntaxTypeName: String(describing: structl.syntaxNodeType)
				)
			case .functionDecl(let funcl):
				return SemanticInfo(
					syntaxId: node.id, 
					referenceName: "\(funcl.identifier)\(funcl.signature)", 
					syntaxTypeName: String(describing: funcl.syntaxNodeType)
				)
			default:
				return defaultSemanticInfo(for: node)
		}
	}
	
	private func defaultSemanticInfo(for node: SyntaxProtocol) -> SemanticInfo {
		let nodeTypeName = String(describing: node.syntaxNodeType)
		return SemanticInfo(
			syntaxId: node.id,
			referenceName: nodeTypeName,
			syntaxTypeName: nodeTypeName
		)
	}
	
	private subscript(_ node: Syntax) -> SyntaxEnum {
		get { localSemanticCache[node].nodeEnum }
	}
}

