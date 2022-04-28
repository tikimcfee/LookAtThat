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
    private(set) var localCallStackCache = [String: Set<SemanticInfo>]()
    
    func semanticInfo(for node: Syntax, fileName: String? = nil) -> SemanticInfo {
		switch self[node] {
        case .variableDecl(let varl):
            var name: String
            var stackName: String?
            if let firstBinding = varl.bindings.first {
                let typeName = firstBinding.typeAnnotation?.description ?? ""
                let pattern = firstBinding.pattern.description
                stackName = pattern.trimmingCharacters(in: .whitespaces)
                name = "\(varl.letOrVarKeyword.text) \(pattern)\(typeName)"
            } else {
                name = "(unsupported syntax: \(varl.id)"
            }
            let newInfo = SemanticInfo(
                node: node,
                referenceName: name,
                color: CodeGridColors.variableDecl,
                fullTextSearchable: true,
                fileName: fileName,
                callStackName: stackName
            )
            addToCallStackCache(newInfo)
            return newInfo
            
        case .extensionDecl(let extenl):
            let extendedTypeName = extenl.extendedType._syntaxNode.strippedText
            let newInfo = SemanticInfo(
                node: node,
                referenceName: "extension \(extendedTypeName)",
                color: CodeGridColors.extensionDecl,
                fileName: fileName,
                callStackName: extendedTypeName.trimmingCharacters(in: .whitespaces)
            )
            addToCallStackCache(newInfo)
            return newInfo
            
        case .classDecl(let classl):
            let newInfo = SemanticInfo(
                node: node,
                referenceName: "\(classl.identifier)",
                color: CodeGridColors.classDecl,
                fileName: fileName,
                callStackName: "\(classl.identifier)".trimmingCharacters(in: .whitespaces)
            )
            addToCallStackCache(newInfo)
            return newInfo
            
        case .structDecl(let structl):
            let newInfo = SemanticInfo(
                node: node,
                referenceName: "\(structl.identifier)",
                color: CodeGridColors.structDecl,
                fileName: fileName,
                callStackName: "\(structl.identifier)".trimmingCharacters(in: .whitespaces)
            )
            addToCallStackCache(newInfo)
            return newInfo
            
        case .functionDecl(let funcl):
            let readableFunctionSignataure = "\(funcl.identifier)\(funcl.signature._syntaxNode.strippedText)"
            let newInfo = SemanticInfo(
                node: node,
                referenceName: readableFunctionSignataure,
                color: CodeGridColors.functionDecl,
                fileName: fileName,
                callStackName: "\(funcl.identifier)".trimmingCharacters(in: .whitespaces)
            )
            addToCallStackCache(newInfo)
            return newInfo
            
        case .protocolDecl(let protol):
            let newInfo = SemanticInfo(
                node: node,
                referenceName: "\(protol.identifier)",
                color: CodeGridColors.protocolDecl,
                fileName: fileName,
                callStackName: "\(protol.identifier)".trimmingCharacters(in: .whitespaces)
            )
            addToCallStackCache(newInfo)
            return newInfo
            
        default:
            return SemanticInfo(
                node: node,
                fileName: fileName
            )
		}
	}
    
    public func cachedCallStackInfo(_ callStackName: String) -> Set<SemanticInfo>? {
        localCallStackCache[callStackName]
    }
	
	subscript(_ node: Syntax) -> SyntaxEnum {
		get { localSemanticCache[node].nodeEnum }
	}
}

private extension SemanticInfoBuilder {
    func addToCallStackCache(_ info: SemanticInfo) {
        guard !info.callStackName.isEmpty else { return }
        localCallStackCache[info.callStackName, default: []].insert(info)
    }
}
