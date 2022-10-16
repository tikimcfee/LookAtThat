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
    
    func semanticInfo(
        for node: Syntax,
        type: SyntaxEnum? = nil,
        fileName: String? = nil
    ) -> SemanticInfo {
        if let cached = localInfoCache[node] { return cached }
        
        let newInfo: SemanticInfo
        lazy var DANGEROUS_CAST = self[node] // Trying to read enum type during walk can be.. dangerous? it randomly crashes trying to read `raw`
        switch type ?? DANGEROUS_CAST {
        case .variableDecl(let varl):
            newInfo = makeVariableInfo(for: node, fileName: fileName, varl)
            
        case .extensionDecl(let extenl):
            newInfo = makeExtensionInfo(for: node, fileName: fileName, extenl)
            
        case .classDecl(let classl):
            newInfo = makeClassInfo(for: node, fileName: fileName, classl)
            
        case .structDecl(let structl):
            newInfo = makeStructInfo(for: node, fileName: fileName, structl)
            
        case .functionDecl(let funcl):
            newInfo = makeFunctionDeclInfo(for: node, fileName: fileName, funcl)
            
        case .token(let token):
            newInfo = makeTokenInfo(for: node, token)
            
        case .functionCallExpr(let fcall):
            newInfo = makeFunctionCallInfo(for: node, fileName: fileName, fcall)
            
        case .memberAccessExpr(let memal):
            newInfo = makeMemberAccessInfo(for: node, fileName: fileName, memal)
            
        case .protocolDecl(let protol):
            newInfo = makeProtocolInfo(for: node, fileName: fileName, protol)
            
        case .typealiasDecl(let typel):
            newInfo = makeTypeAliasInfo(for: node, fileName: fileName, typel)
            
        case .enumDecl(let enuml):
            newInfo = makeEnumDeclInfo(for: node, fileName: fileName, enuml)
            
        default:
            newInfo = makeDefaultInfo(for: node, fileName : fileName)
        }
        
        addToCallStackCache(newInfo)
        localInfoCache[node] = newInfo
        return newInfo
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
        get { localSemanticCache[node] }
        set { localSemanticCache[node] = newValue }
    }
}

extension SemanticInfoBuilder {
    func buildRecursiveParentName(_ info: Syntax) -> String {
        switch self[info] {
        case .classDecl(let classDecl):
            var finalId = "\(classDecl.identifier._syntaxNode.strippedText)"
            buildNameWalkingUp(
                from: classDecl,
                targetId: &finalId
            )
            return finalId
        case .structDecl(let structDecl):
            var finalId = "\(structDecl.identifier._syntaxNode.strippedText)"
            buildNameWalkingUp(
                from: structDecl,
                targetId: &finalId
            )
            return finalId
        case .functionDecl(let funcDecl):
            var finalId = "\(funcDecl.identifier._syntaxNode.strippedText)"
            buildNameWalkingUp(
                from: funcDecl,
                targetId: &finalId
            )
            return finalId
        case .enumDecl(let enumDecl):
            var finalId = "\(enumDecl.identifier._syntaxNode.strippedText)"
            buildNameWalkingUp(
                from: enumDecl,
                targetId: &finalId
            )
            return finalId
        case .extensionDecl(let extensionDecl):
            var finalId = "\(extensionDecl.extendedType._syntaxNode.strippedText)"
            buildNameWalkingUp(
                from: extensionDecl,
                targetId: &finalId
            )
            return finalId
        default:
            return ""
        }
    }
    
    func buildNameWalkingUp(
        from node: SyntaxProtocol,
        targetId: inout String
    ) {
        var current: Syntax? = node.parent
        while let next = current {
            switch self[next] {
            case .classDecl(let outerD):
                targetId = "\(outerD.identifier._syntaxNode.strippedText).\(targetId)"
                
            case .extensionDecl(let outerExt):
                targetId = "\(outerExt.extendedType._syntaxNode.strippedText).\(targetId)"
                
            case .functionDecl(let outerF):
                targetId = "\(outerF.identifier._syntaxNode.strippedText).\(targetId)"
                
            case .enumDecl(let outerEnum):
                targetId = "\(outerEnum.identifier._syntaxNode.strippedText).\(targetId)"
                
            case .structDecl(let outStruct):
                targetId = "\(outStruct.identifier._syntaxNode.strippedText).\(targetId)"
                
            default:
                break
            }
            current = current?.parent
        }
    }
}

private extension SemanticInfoBuilder {
    func makeTokenInfo(for node: Syntax, fileName: String? = nil, _ tokl: TokenSyntax) -> SemanticInfo {
        SemanticInfo(
            node: node,
            referenceName: tokl.text,
            fullTextSearchable: false,
            fileName: fileName
        )
    }
    
    func makeTypeAliasInfo(for node: Syntax, fileName: String? = nil, _ typel: TypealiasDeclSyntax) -> SemanticInfo {
        let aliasName = "\(typel.identifier) = \(typel.initializer.value.description)"
        return SemanticInfo(
            node: node,
            referenceName: aliasName,
            color: CodeGridColors.typealiasDecl,
            fileName: fileName
        )
    }
    
    func makeEnumDeclInfo(for node: Syntax, fileName: String? = nil, _ enuml: EnumDeclSyntax) -> SemanticInfo {
        let name = buildRecursiveParentName(node)
        return SemanticInfo(
            node: node,
            referenceName: name,
            color: CodeGridColors.enumDecl,
            fileName: fileName
        )
    }
    
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
        return newInfo
    }
    
    func makeClassInfo(for node: Syntax, fileName: String? = nil, _ classl: ClassDeclSyntax) -> SemanticInfo {
        let newInfo = SemanticInfo(
            node: node,
            referenceName: buildRecursiveParentName(node),
            color: CodeGridColors.classDecl,
            fileName: fileName,
            callStackName: "\(classl.identifier)".trimmingCharacters(in: .whitespaces)
        )
        return newInfo
    }
    
    func makeStructInfo(for node: Syntax, fileName: String? = nil, _ structl: StructDeclSyntax) -> SemanticInfo {
        let newInfo = SemanticInfo(
            node: node,
            referenceName: buildRecursiveParentName(node),
            color: CodeGridColors.structDecl,
            fileName: fileName,
            callStackName: "\(structl.identifier)".trimmingCharacters(in: .whitespaces)
        )
        return newInfo
    }
    
    func makeMemberAccessInfo(for node: Syntax, fileName: String? = nil, _ memal: MemberAccessExprSyntax) -> SemanticInfo {
        let readableFunctionSignataure = node.strippedText
        let newInfo = SemanticInfo(
            node: node,
            referenceName: readableFunctionSignataure,
            color: CodeGridColors.functionDecl,
            fileName: fileName
        )
        return newInfo
    }
    
    func makeFunctionDeclInfo(for node: Syntax, fileName: String? = nil, _ funcl: FunctionDeclSyntax) -> SemanticInfo {
        let readableFunctionSignataure = "\(funcl.identifier)\(funcl.signature._syntaxNode.strippedText)"
        let newInfo = SemanticInfo(
            node: node,
            referenceName: readableFunctionSignataure,
            color: CodeGridColors.functionDecl,
            fileName: fileName,
            callStackName: "\(funcl.identifier)".trimmingCharacters(in: .whitespaces)
        )
        return newInfo
    }
    
    func makeFunctionCallInfo(for node: Syntax, fileName: String? = nil, _ expressl: FunctionCallExprSyntax) -> SemanticInfo {
        let readableFunctionSignataure = node.strippedText
        let newInfo = SemanticInfo(
            node: node,
            referenceName: readableFunctionSignataure,
            color: CodeGridColors.functionDecl,
            fileName: fileName
        )
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
        return newInfo
    }
    
    func makeDefaultInfo(
        for node: Syntax,
        fileName: String? = nil
    ) -> SemanticInfo {
        return SemanticInfo(
            node: node,
            fileName: fileName
        )
    }
}
