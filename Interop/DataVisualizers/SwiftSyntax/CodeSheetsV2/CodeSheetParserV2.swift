//
//  CodeSheetParserV2.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/10/21.
//

import Foundation
import SwiftSyntax
import SceneKit

public class CodeSheetParserV2 {
    var textNodeBuilder: WordNodeBuilder
    let codeSheetVisitor: CodeSheetVisitor
    
    init(_ nodeBuilder: WordNodeBuilder) {
        self.textNodeBuilder = nodeBuilder
        self.codeSheetVisitor = CodeSheetVisitor(nodeBuilder)
    }
    
    func parseFile(_ url: URL) -> CodeSheet? {
        SCNNode.BoundsCaching.Clear()
        return codeSheetVisitor.makeFileSheet(url)
    }
}

enum CodeSheetVisitorLoadError: Error {
    case failedToWalk
}

public class CodeSheetVisitor:
    SyntaxAnyVisitor,
    SwiftSyntaxFileLoadable,
    SwiftSyntaxCodeSheetBuildable
{
    
    lazy var organizedInfo = OrganizedSourceInfo()
    var allRootContainerNodes = [SCNNode: CodeSheet]()
    lazy var rootSheet = CodeSheet()
    
    var textNodeBuilder: WordNodeBuilder
    let colorizer = CodeSheetColorizing()
    
    init(_ nodeBuilder: WordNodeBuilder) {
        self.textNodeBuilder = nodeBuilder
    }
    
    func makeFileSheet(_ url: URL) -> CodeSheet? {
        do {
            guard let syntax = loadSourceUrl(url) else {
                throw CodeSheetVisitorLoadError.failedToWalk
            }
            rootSheet = CodeSheet()
            walk(syntax)
            return rootSheet
                .categoryMask(.rootCodeSheet)
                .sizePageToContainerNode()
                .removingWhitespace()
        } catch {
            print(error)
            return nil
        }
    }
    
    func defaultSemanticInfo(for node: SyntaxProtocol) -> SemanticInfo {
        return SemanticInfo(
            syntaxId: node.id,
            referenceName: String(describing: node.syntaxNodeType),
            syntaxTypeName: String(describing: node.syntaxNodeType)
        )
    }
    
    public override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        cacheNewSheet(for: node)
        return .visitChildren
    }
    
    public override func visitAnyPost(_ node: Syntax) {
        switch node.as(SyntaxEnum.self) {
        case .structDecl, .enumDecl, .protocolDecl, .classDecl, .extensionDecl,
             .codeBlockItemList, .codeBlockItem, .codeBlock,
             .ifConfigClauseList, .ifConfigDecl, .ifConfigClause,
             .memberDeclBlock, .memberDeclList, .memberDeclListItem:
            collectChildrenPostVisit(of: node)
        case .sourceFile:
            collectChildrenPostVisit(of: node)
            if let sourceSheet = organizedInfo[node] {
                rootSheet.appendChild(sourceSheet)
            } else {
                print("<!> At source node, but root sheet not found ")
            }
        default:
            break
        }
    }
    
    public override func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }
    
    private func collectChildrenPostVisit(of syntax: Syntax) {
        let newCollectedSheet = CodeSheet()
        
        syntax.children.forEach { childNode in
            if let child = organizedInfo[childNode] {
                newCollectedSheet.appendChild(child)
            }
            else if let token = childNode.as(TokenSyntax.self) {
                newCollectedSheet.add(token, textNodeBuilder)
            }
            else {
                print("Missing syntax child node, \(childNode.syntaxNodeType) in \(syntax.syntaxNodeType)")
            }
        }
        
        organizedInfo[syntax] = newCollectedSheet
            .sizePageToContainerNode()
            .semantics(defaultSemanticInfo(for: syntax))
            .arrangeSemanticInfo(textNodeBuilder)
            .backgroundColor(colorizer.backgroundColor(for: syntax))
        
        allRootContainerNodes[newCollectedSheet.containerNode] = newCollectedSheet
    }
    
    private func cacheNewSheet(for syntax: Syntax) {
        let newSheet = CodeSheet()
            .consume(syntax: syntax, nodeBuilder: textNodeBuilder)
            .sizePageToContainerNode()
            .backgroundColor(colorizer.backgroundColor(for: syntax))
//            .semantics(defaultSemanticInfo(for: syntax))
//            .arrangeSemanticInfo(textNodeBuilder)
        
        organizedInfo[syntax] = newSheet
    }
    
}

extension CodeSheet {
    func consume(syntax: Syntax, nodeBuilder: WordNodeBuilder) -> Self {
        for token in syntax.tokens {
            add(token, nodeBuilder)
        }
        return self
    }
}

class CodeSheetColorizing {
    func backgroundColor(for syntax: Syntax) -> NSUIColor {
        return typeColor(for: syntax.syntaxNodeType)
    }
    
    func typeColor(for type: SyntaxProtocol.Type) -> NSUIColor {
        if type == StructDeclSyntax.self {
            return color(0.3, 0.2, 0.3, 1.0)
        }
        if type == ClassDeclSyntax.self {
            return color(0.2, 0.2, 0.4, 1.0)
        }
        if type == FunctionDeclSyntax.self {
            return color(0.15, 0.15, 0.3, 1.0)
        }
        if type == EnumDeclSyntax.self {
            return color(0.1, 0.3, 0.4, 1.0)
        }
        if type == ExtensionDeclSyntax.self {
            return color(0.2, 0.4, 0.4, 1.0)
        }
        if type == VariableDeclSyntax.self {
            return color(0.3, 0.3, 0.3, 1.0)
        }
        if type == TypealiasDeclSyntax.self {
            return color(0.5, 0.3, 0.5, 1.0)
        }
        else {
            return color(0.2, 0.2, 0.2, 1.0)
        }
    }
    
    private func color(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat)  -> NSUIColor {
        return NSUIColor(displayP3Red: red, green: green, blue: blue, alpha: alpha)
    }
}
