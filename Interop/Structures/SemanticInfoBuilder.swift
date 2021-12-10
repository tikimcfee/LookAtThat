//
//  SemanticInfoBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/28/21.
//

import Foundation
import SwiftSyntax

struct SemanticInfo: Hashable, CustomStringConvertible {
	let node: Syntax
	let syntaxId: SyntaxIdentifier
	
	// Refer to this semantic info by this name; it's displayable
    var fullTextSearch: String = ""
	let referenceName: String
	let syntaxTypeName: String
	let color: NSUIColor
	
	var description: String {
		"\(syntaxTypeName)~>[\(referenceName)]"
	}
    
    var isFullTextSearchable: Bool = false
	
	init(node: Syntax,
		 referenceName: String? = nil,
		 typeName: String? = nil,
		 color: NSUIColor? = nil,
         fullTextSearchable: Bool = false
	) {
		self.node = node
		self.syntaxId = node.id
		self.referenceName = referenceName ?? "\(node.cornerText(5))"
		self.syntaxTypeName = typeName ?? String(describing: node.syntaxNodeType)
		self.color = color ?? CodeGridColors.defaultText
        self.isFullTextSearchable = fullTextSearchable
        if isFullTextSearchable {
            self.fullTextSearch = node.strippedText
        }
	}
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(syntaxId.hashValue)
        hasher.combine(referenceName.hashValue)
    }
}

extension SemanticInfo {
    func iterateReferenceKeys(_ receiver: (String) -> Void) {
        receiver(referenceName)
        receiver(referenceName.lowercased())
        receiver(referenceName.uppercased())
        
        referenceName.iterateTrieKeys(receiver: receiver)
    }
}

class SemanticInfoBuilder {
	private let localSemanticCache = SyntaxCache()
	
	func semanticInfo(for node: Syntax) -> SemanticInfo {
		switch self[node] {
			case .variableDecl(let varl):
                var name: String
				if let firstBinding = varl.bindings.first {
					let typeName = firstBinding.typeAnnotation?.description ?? ""
					let pattern = firstBinding.pattern.description
                    name = "\(varl.letOrVarKeyword.text) \(pattern)\(typeName)"
                } else {
                    name = "(unsupported syntax: \(varl.id)"
                }
				return SemanticInfo(
					node: node,
					referenceName: name, 
					color: CodeGridColors.variableDecl,
                    fullTextSearchable: true
                )
			case .extensionDecl(let extenl):
				return SemanticInfo(
					node: node, 
                    referenceName: "\(extenl.extendedType._syntaxNode.strippedText)::\(extenl.extendedType._syntaxNode.strippedText)",
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
                let readableFunctionSignataure = "\(funcl.identifier)\(funcl.signature._syntaxNode.strippedText)"
                return SemanticInfo(
					node: node,
                    referenceName: readableFunctionSignataure,
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
	
	static let trivia = color(0.8, 0.8, 0.8, 0.5)
	
	static func color(_ red: VectorFloat,
                      _ green: VectorFloat,
                      _ blue: VectorFloat,
                      _ alpha: VectorFloat)  -> NSUIColor {
        NSUIColor(displayP3Red: red.cg, green: green.cg, blue: blue.cg, alpha: alpha.cg)
	}
}
