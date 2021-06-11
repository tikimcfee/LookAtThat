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
        
        print("Finding children of: \(syntax.syntaxNodeType)")
        
        syntax.children.forEach { childNode in
            let text = childNode.children.isEmpty ? childNode.strippedText : ""
            
            print("\t\(childNode.syntaxNodeType) | \(childNode.children.count) children > \(text)")
            
            if let child = organizedInfo[childNode] {
                newCollectedSheet.appendChild(child)
                
                // Make all children are interactable by stuffing it into the index
//                allRootContainerNodes[child.containerNode] = child
            }
            else if childNode.isToken, let token = childNode.as(TokenSyntax.self) {
                newCollectedSheet.add(token, textNodeBuilder)
            }
            else {
                print("\t<!> \(childNode.syntaxNodeType) missing")
            }
        }
        
        organizedInfo[syntax] = newCollectedSheet
            .sizePageToContainerNode()
            .semantics(defaultSemanticInfo(for: syntax))
            .arrangeSemanticInfo(textNodeBuilder)
        
        allRootContainerNodes[newCollectedSheet.containerNode] = newCollectedSheet
    }
    
    private func cacheNewSheet(for syntax: Syntax) {
        let newSheet = CodeSheet()
            .consume(syntax: syntax, nodeBuilder: textNodeBuilder)
            .sizePageToContainerNode()
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
