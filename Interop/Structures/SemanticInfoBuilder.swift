//
//  SemanticInfoBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/28/21.
//

import Foundation
import SwiftSyntax

class SemanticInfoBuilder {
	func semanticInfo(for node: Syntax) -> SemanticInfo {
		switch node.cachedType {
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
		return SemanticInfo(
			syntaxId: node.id,
			referenceName: String(describing: node.syntaxNodeType),
			syntaxTypeName: String(describing: node.syntaxNodeType)
		)
	}
}

