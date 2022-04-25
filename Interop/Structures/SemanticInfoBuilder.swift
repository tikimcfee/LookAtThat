//
//  SemanticInfoBuilder.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 10/28/21.
//

import Foundation
import SwiftSyntax

class SemanticInfoBuilder {
	private let localSemanticCache = SyntaxCache()
	
    func semanticInfo(for node: Syntax, fileName: String? = nil) -> SemanticInfo {
		switch self[node] {
			case .variableDecl(let varl):
                var name: String
                let stackName = varl.bindings.first?.pattern.description
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
                    fullTextSearchable: true,
                    fileName: fileName,
                    callStackName: stackName
                )
			case .extensionDecl(let extenl):
				return SemanticInfo(
					node: node, 
                    referenceName: "extension \(extenl.extendedType._syntaxNode.strippedText)",
                    color: CodeGridColors.extensionDecl,
                    fileName: fileName
				)
			case .classDecl(let classl):
				return SemanticInfo(
					node: node,
					referenceName: "\(classl.identifier)",
                    color: CodeGridColors.classDecl,
                    fileName: fileName,
                    callStackName: "\(classl.identifier)"
				)
			case .structDecl(let structl):
				return SemanticInfo(
					node: node,
					referenceName: "\(structl.identifier)",
                    color: CodeGridColors.structDecl,
                    fileName: fileName,
                    callStackName: "\(structl.identifier)"
				)
			case .functionDecl(let funcl):
                let readableFunctionSignataure = "\(funcl.identifier)\(funcl.signature._syntaxNode.strippedText)"
                return SemanticInfo(
					node: node,
                    referenceName: readableFunctionSignataure,
                    color: CodeGridColors.functionDecl,
                    fileName: fileName,
                    callStackName: "\(funcl.identifier)"
				)
			default:
				return SemanticInfo(
					node: node,
                    fileName: fileName
				)
		}
	}
	
	private subscript(_ node: Syntax) -> SyntaxEnum {
		get { localSemanticCache[node].nodeEnum }
	}
}
