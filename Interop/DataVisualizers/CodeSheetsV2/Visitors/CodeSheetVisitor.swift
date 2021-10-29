//
//  CodeSheetVisitor.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/13/21.
//

import Foundation
import SceneKit
import SwiftSyntax

import SwiftTrace

public class CodeSheetVisitor: SwiftSyntaxFileLoadable {
    var allRootContainerNodes = [SCNNode: CodeSheet]()
    
    var textNodeBuilder: WordNodeBuilder
    let colorizer = CodeSheetColorizing()
    
    init(_ nodeBuilder: WordNodeBuilder) {
        self.textNodeBuilder = nodeBuilder
    }
    
    func makeFileSheet(_ url: URL) throws -> ParsingState {
        guard let syntax = loadSourceUrl(url) else {
            throw CodeSheetVisitorLoadError.failedToWalk
        }
        
        let parsingState = ParsingState(sourceFile: url, sourceFileSyntax: syntax)
        let newVisitor = StateCapturingVisitor(
            onVisitAny: { self.onVisitAny($0, state: parsingState) },
            onVisitAnyPost: { self.onVisitAnyPost($0, state: parsingState) }
        )
        newVisitor.walk(syntax)
        parsingState.sheet
            .categoryMask(.rootCodeSheet)
            .sizePageToContainerNode()
            .removingWhitespace()
        
        return parsingState
    }
    
    private func onVisitAny(_ node: Syntax, state: ParsingState) -> SyntaxVisitorContinueKind {
        cacheNewSheet(for: node, into: state)
        return .visitChildren
    }
    
    private func onVisitAnyPost(_ node: Syntax, state: ParsingState) {
        switch node.cachedType {
        case .structDecl, .enumDecl, .protocolDecl, .classDecl, .extensionDecl,
             .codeBlockItemList, .codeBlockItem, .codeBlock,
             .ifConfigClauseList, .ifConfigDecl, .ifConfigClause,
             .memberDeclBlock, .memberDeclList, .memberDeclListItem:
            collectChildrenPostVisit(of: node, into: state)
                .semantics(SemanticInfo(node: node))
                .arrangeSemanticInfo(textNodeBuilder)

        case .sourceFile:
            let sourceSheet = collectChildrenPostVisit(of: node, into: state)
                .semantics(SemanticInfo(
					node: node,
                    referenceName: state.sourceFile.lastPathComponent
                ))
                .arrangeSemanticInfo(textNodeBuilder, asTitle: true)
            state.setAsRoot(sourceSheet)
            
        default:
            break
        }
    }
    
    private func collectChildrenPostVisit(of node: Syntax, into state: ParsingState) -> CodeSheet {
        let newCollectedSheet = CodeSheet()
        
        node.children.forEach { childNode in
            if let child = state.organizedSourceInfo[childNode] {
                newCollectedSheet.appendChild(child)
            }
            else if let token = childNode.as(TokenSyntax.self) {
                newCollectedSheet.add(token, textNodeBuilder)
            }
            else {
                // We end up where when we've found a skipped token or child in a hierarchy that we didn't build for.
                //                print("Missing syntax child node, \(childNode.syntaxNodeType) in \(syntax.syntaxNodeType)")
            }
        }
        
        // Don't arrange semantic or add info by default.
        // Add and arrange in visitPost() to get the desired
        // custom positioning.
        state.organizedSourceInfo[node] = newCollectedSheet
            .sizePageToContainerNode()
            .backgroundColor(colorizer.backgroundColor(for: node))
        
        allRootContainerNodes[newCollectedSheet.containerNode] = newCollectedSheet
        
        return newCollectedSheet
    }
    
    private func cacheNewSheet(for syntax: Syntax, into state: ParsingState) {
        let newSheet = CodeSheet()
            .consume(syntax: syntax, textNodeBuilder)
            .sizePageToContainerNode()
            .backgroundColor(colorizer.backgroundColor(for: syntax))
        //            .arrangeSemanticInfo(textNodeBuilder)
        
        state.organizedSourceInfo[syntax] = newSheet
    }
}

enum CodeSheetVisitorLoadError: Error {
    case failedToWalk
}
