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
    static let codeSheetVisitor: TEST_CodeSheetVisitor = {
        TEST_CodeSheetVisitor()
    }()
    
    func parseFile(_ url: URL) -> CodeSheet? {
        SCNNode.BoundsCaching.Clear()
        return Self.codeSheetVisitor.makeFileSheet(url)
    }
}

enum TEST_CodeSheetVisitorLoadError: Error {
    case failedToWalk
}
public class TEST_CodeSheetVisitor:
    SyntaxAnyVisitor,
    SwiftSyntaxFileLoadable,
    SwiftSyntaxCodeSheetBuildable
{
    
    var organizedInfo: OrganizedSourceInfo = OrganizedSourceInfo()
    var textNodeBuilder: WordNodeBuilder = WordNodeBuilder()
    lazy var rootSheet = CodeSheet()
    
    func makeFileSheet(_ url: URL) -> CodeSheet? {
        do {
            guard let syntax = loadSourceUrl(url) else {
                throw TEST_CodeSheetVisitorLoadError.failedToWalk
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
    
    // TODO:
    // if there's already a sheet for me, I'm a parent.
    // problem is, I have syntax too. So what do I do
    // when I have visited all variables in a class,
    // and I am now at the class node which already has a sheet.
    // In fact, the child/parent thing is weird because every child
    // would have to append itself to its parent, or the parent
    // would have to find a way to iterate its children that were
    // already rendered, and those that weren't.
    // Sheet does not support moving stuff around, only appending.
    // Maybe we say:
    // If I have parent, append to it
    // If I don't write to a new sheet
    // If I *AM* a parent...
    //   - make a new sheet
    //   - for each child,
    //            if let parentOfNode = syntax.parent,
    //               let parentSheet = organizedInfo[parentOfNode] {
    //                // I have a parent with a sheet, so I'll append to it
    //                appendTarget = parentSheet
    //            } else {
    //                // I don't have a sheet, I have no parent sheet yet, so I'll
    //                // be the one to make that container sheet
    //                appendTarget = CodeSheet()
    //            }
    public override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        func appendNode(_ syntax: SyntaxProtocol) {
            var appendTarget: CodeSheet
            
            let newSheet = makeSheet(from: node)
                .semantics(defaultSemanticInfo(for: node))
                .arrangeSemanticInfo(textNodeBuilder)
            
            organizedInfo[node] = newSheet
        }
        
        // I want a node to be owned by its contextual parent.
        // look at a node
        //  if it has a parent, see if there's an existing sheet for it
        //  - if there isn't, make it, and then append yourself to it
        //  - if there is, just append yourself to it
        // if there is no parent, you are the root.
        
        switch node.as(SyntaxEnum.self) {
        //        case .codeBlockItem(let item):
        //            print("Code block:\n\(node.allText)")
        //            break
        //        case .codeBlock(let block):
        //            break
        //        case .codeBlockItemList(let list):
        //            break
        case let .variableDecl(decl):
            appendNode(decl)
        case let .extensionDecl(syntax):
            appendNode(syntax)
        case let .structDecl(syntax):
            appendNode(syntax)
        case let .enumDecl(syntax):
            appendNode(syntax)
        case let .protocolDecl(syntax):
            appendNode(syntax)
        case let .initializerDecl(syntax):
            appendNode(syntax)
        case let .classDecl(syntax):
            appendNode(syntax)
        case let .functionDecl(syntax):
            appendNode(syntax)
        default:
            break
        }
        
        return .visitChildren
    }
    
    public override func visitAnyPost(_ node: Syntax) {
        
    }
    
    public override func visit(_ node: TokenSyntax) -> SyntaxVisitorContinueKind {
        return .visitChildren
    }
    
}

extension CodeSheet {
    func consume(syntax: Syntax, nodeBuilder: WordNodeBuilder) {
        for token in syntax.tokens {
            add(token, nodeBuilder)
        }
    }
}
