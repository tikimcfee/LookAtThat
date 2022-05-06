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
    private(set) var localInfoCache = [Syntax: SemanticInfo]()
    
    func semanticInfo(for node: Syntax, fileName: String? = nil) -> SemanticInfo {
        if let cached = localInfoCache[node] { return cached }
        
        let info: SemanticInfo
        switch self[node] {
        case .variableDecl(let varl):
            info = makeVariableInfo(for: node, fileName: fileName, varl)
            
        case .extensionDecl(let extenl):
            info = makeExtensionInfo(for: node, fileName: fileName, extenl)
            
        case .classDecl(let classl):
            info = makeClassInfo(for: node, fileName: fileName, classl)
            
        case .structDecl(let structl):
            info = makeStructInfo(for: node, fileName: fileName, structl)
            
        case .functionDecl(let funcl):
            info = makeFunctionInfo(for: node, fileName: fileName, funcl)
            
        case .protocolDecl(let protol):
            info = makeProtocolInfo(for: node, fileName: fileName, protol)
            
        default:
            info = makeDefaultInfo(for: node, fileName : fileName)
        }
        
        localInfoCache[node] = info
        return info
    }
}

extension SemanticInfoBuilder {
    private func addToCallStackCache(_ info: SemanticInfo) {
        guard !info.callStackName.isEmpty else { return }
        localCallStackCache[info.callStackName, default: []].insert(info)
    }
    
    public func cachedCallStackInfo(_ callStackName: String) -> Set<SemanticInfo>? {
        localCallStackCache[callStackName]
    }
    
    subscript(_ node: Syntax) -> SyntaxEnum {
        get { localSemanticCache[node].nodeEnum }
    }
}

private extension SemanticInfoBuilder {
    func makeVariableInfo(for node: Syntax, fileName: String? = nil, _ varl: VariableDeclSyntax) -> SemanticInfo {
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
    }
    
    func makeExtensionInfo(for node: Syntax, fileName: String? = nil, _ extenl: ExtensionDeclSyntax) -> SemanticInfo {
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
    }
    
    func makeClassInfo(for node: Syntax, fileName: String? = nil, _ classl: ClassDeclSyntax) -> SemanticInfo {
        let newInfo = SemanticInfo(
            node: node,
            referenceName: "\(classl.identifier)",
            color: CodeGridColors.classDecl,
            fileName: fileName,
            callStackName: "\(classl.identifier)".trimmingCharacters(in: .whitespaces)
        )
        addToCallStackCache(newInfo)
        return newInfo
    }
    
    func makeStructInfo(for node: Syntax, fileName: String? = nil, _ structl: StructDeclSyntax) -> SemanticInfo {
        let newInfo = SemanticInfo(
            node: node,
            referenceName: "\(structl.identifier)",
            color: CodeGridColors.structDecl,
            fileName: fileName,
            callStackName: "\(structl.identifier)".trimmingCharacters(in: .whitespaces)
        )
        addToCallStackCache(newInfo)
        return newInfo
    }
    
    func makeFunctionInfo(for node: Syntax, fileName: String? = nil, _ funcl: FunctionDeclSyntax) -> SemanticInfo {
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
    }
    
    func makeProtocolInfo(for node: Syntax, fileName: String? = nil, _ protol: ProtocolDeclSyntax) -> SemanticInfo {
        let newInfo = SemanticInfo(
            node: node,
            referenceName: "\(protol.identifier)",
            color: CodeGridColors.protocolDecl,
            fileName: fileName,
            callStackName: "\(protol.identifier)".trimmingCharacters(in: .whitespaces)
        )
        addToCallStackCache(newInfo)
        return newInfo
    }
    
    func makeDefaultInfo(for node: Syntax, fileName: String? = nil) -> SemanticInfo {
        return SemanticInfo(
            node: node,
            fileName: fileName
        )
    }
}
