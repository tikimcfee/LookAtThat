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
        return try? codeSheetVisitor.makeFileSheet(url).sheet
    }
    
    func parseDirectory(_ directory: Directory,
                        in scene: SceneState,
                        _ handler: @escaping (OrganizedSourceInfo) -> Void) {
        SCNNode.BoundsCaching.Clear()
        
        guard let results = codeSheetVisitor.renderDirectory(directory, in: scene).first
        else { return }
        handler(results.organizedSourceInfo)
    }
}

enum CodeSheetVisitorLoadError: Error {
    case failedToWalk
}

private class StateCapturingVisitor: SyntaxAnyVisitor {
    let onVisit: (Syntax) -> SyntaxVisitorContinueKind
    let onVisitAnyPost: (Syntax) -> Void
    
    init(onVisitAny: @escaping (Syntax) -> SyntaxVisitorContinueKind,
         onVisitAnyPost: @escaping (Syntax) -> Void) {
        self.onVisit = onVisitAny
        self.onVisitAnyPost = onVisitAnyPost
    }
    
    public override func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        onVisit(node)
    }
    
    public override func visitAnyPost(_ node: Syntax) {
        onVisitAnyPost(node)
    }
}

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
                .semantics(defaultSemanticInfo(for: node))
                .arrangeSemanticInfo(textNodeBuilder)
            
        case .sourceFile:
            let sourceSheet = collectChildrenPostVisit(of: node, into: state)
                .semantics(SemanticInfo(
                    syntaxId: node.id,
                    referenceName: state.sourceFile.lastPathComponent,
                    syntaxTypeName: String(describing: node.cachedType)
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
//            .semantics(defaultSemanticInfo(for: syntax))
//            .arrangeSemanticInfo(textNodeBuilder)
        
        state.organizedSourceInfo[syntax] = newSheet
    }
    
    private func defaultSemanticInfo(for node: SyntaxProtocol) -> SemanticInfo {
        return SemanticInfo(
            syntaxId: node.id,
            referenceName: String(describing: node.syntaxNodeType),
            syntaxTypeName: String(describing: node.syntaxNodeType)
        )
    }
}

extension CodeSheetVisitor {
    func renderDirectory(_ directory: Directory, in sceneState: SceneState) -> [ParsingState] {
        let results: [ParsingState] = directory.swiftUrls.compactMap { url in
            guard let state = try? makeFileSheet(url) else {
                print("Failed to load code file: \(url.lastPathComponent)")
                return nil
            }
            return state
        }
        
        let directorySheet = CodeSheet()
            .backgroundColor(NSUIColor.black)
        directorySheet.containerNode.position.z = -300
        
        var lastChild: SCNNode? { directorySheet.containerNode.childNodes.last }
        var lastChildLengthX: VectorFloat { lastChild?.lengthX ?? 0.0 }
        var lastChildLengthY: VectorFloat { lastChild?.lengthY ?? 0.0 }
        
        var x = VectorFloat(-16.0)
        var nextX: VectorFloat {
            x += lastChildLengthX + 16
            return x
        }
        
        var y = VectorFloat(0.0)
        var nextY: VectorFloat {
            y += 0
            return y
        }
        
        var z = VectorFloat(15.0)
        var nextZ: VectorFloat {
            z += 0
            return z
        }
        
        results.forEach { result in
            //            let lookAtCamera = SCNLookAtConstraint(target: sceneState.cameraNode)
            //            lookAtCamera.localFront = SCNVector3Zero.translated(dZ: 1.0)
            //            pair.1.containerNode.constraints = [lookAtCamera]
            result.sheet.containerNode.position =
                SCNVector3Zero.translated(
                    dX: nextX + result.sheet.halfLengthX,
                    //                    dY: -pair.1.halfLengthY - nextY,
                    dY: nextY - result.sheet.halfLengthY,
                    dZ: nextZ
                )
            directorySheet.containerNode.addChildNode(result.sheet.containerNode)
        }
        directorySheet.sizePageToContainerNode(pad: 20.0)
        
        sceneTransaction {
            sceneState.rootGeometryNode.addChildNode(directorySheet.containerNode)
        }
        
        return results
    }
}
