//
//  SemanticInfoBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/28/21.
//

import Foundation
import SwiftSyntax

struct SemanticInfo: Hashable, CustomStringConvertible {
	let syntaxId: SyntaxIdentifier
	
	// Refer to this semantic info by this name; it's displayable
	let referenceName: String
	let syntaxTypeName: String
	let color: NSUIColor
	
	var description: String {
		"\(syntaxTypeName)~>[\(referenceName)]"
	}
	
	init(node: Syntax,
		 referenceName: String? = nil,
		 typeName: String? = nil,
		 color: NSUIColor? = nil
	) {
		self.syntaxId = node.id
		self.referenceName = referenceName ?? "\(node.hashValue)"
		self.syntaxTypeName = typeName ?? String(describing: node.syntaxNodeType)
		self.color = color ?? CodeGridColors.defaultText
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
					node: node,
					referenceName: name, 
					color: CodeGridColors.variableDecl
				)
			case .extensionDecl(let extenl):
				return SemanticInfo(
					node: node, 
					referenceName: "\(extenl.extendedType.description)+\(node.id.hashValue)", 
					color: CodeGridColors.extensionDecl
				)
			case .classDecl(let classl):
				return SemanticInfo(
					node: node,
					referenceName: "\(classl.identifier)",
					color: CodeGridColors.classDecl
				)
			case .structDecl(let structl):
				return SemanticInfo(
					node: node,
					referenceName: "\(structl.identifier)",
					color: CodeGridColors.structDecl 
				)
			case .functionDecl(let funcl):
				return SemanticInfo(
					node: node,
					referenceName: "\(funcl.identifier)\(funcl.signature)", 
					color: CodeGridColors.functionDecl
				)
			default:
				return SemanticInfo(
					node: node
				)
		}
	}
	
	private subscript(_ node: Syntax) -> SyntaxEnum {
		get { localSemanticCache[node].nodeEnum }
	}
}


class CodeGridColors {
	static let structDecl = color(0.3, 0.2, 0.3, 1.0)
	static let classDecl = color(0.2, 0.2, 0.4, 1.0)
	static let functionDecl = color(0.15, 0.15, 0.3, 1.0)
	static let enumDecl = color(0.1, 0.3, 0.4, 1.0)
	static let extensionDecl = color(0.2, 0.4, 0.4, 1.0)
	static let variableDecl = color(0.3, 0.3, 0.3, 1.0)
	static let typealiasDecl = color(0.5, 0.3, 0.5, 1.0)
	static let defaultText = color(0.2, 0.2, 0.2, 1.0)
	
	static func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat)  -> NSUIColor {
		NSUIColor(displayP3Red: red, green: green, blue: blue, alpha: alpha)
	}
}
