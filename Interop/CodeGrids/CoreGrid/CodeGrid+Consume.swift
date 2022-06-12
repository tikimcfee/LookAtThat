//
//  CodeGrid+Writing.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/12/21.
//

import Foundation
import SceneKit
import SwiftSyntax

// MARK: -- Consume Text
extension CodeGrid {
    // If you call this, you basically draw text like a typewriter from wherevery you last were.
    // it adds caches layer glyphs motivated by display requirements inherited by those clients.
    @discardableResult
    func consume(text: String) -> CodeGrid {
        let gridResult = sceneTransactionSafe(0) {
            doTextConsume(text: text)
        }
        return gridResult
    }
    
    @discardableResult
    private func doTextConsume(text: String) -> CodeGrid {
        let writer: Writer
        switch displayMode {
        case .glyphs:
            let raw = vendRawGlyphWriter
            raw.writeGlyphs(text)
            writer = raw
        case .all:
            let raw = vendRawGlyphWriter
            raw.writeGlyphs(text)
            writer = raw
        }
        writer.finalize()
        recomputeDisplayMode()
        return self
    }
}

//MARK: -- Consume Syntax
extension CodeGrid {
    
    @discardableResult
    func consume(rootSyntaxNode: Syntax) -> CodeGrid {
        let gridResult = sceneTransactionSafe(0) {
            doSyntaxConsume(rootSyntaxNode: rootSyntaxNode)
        }
        
        let view = sceneTransactionSafe(0) { () -> SCNView in
            let width = gridResult.rootNode.boundsWidth
            let height = gridResult.rootNode.boundsHeight
            let testView = SCNView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            let scene = SCNScene()
            testView.scene = scene
            scene.rootNode.addChildNode(gridResult.rootNode)
            return testView
        }
//
        let image = view.snapshot()
        gridResult.rootNode.removeFromParentNode()
//        gridResult.rawGlyphsNode.isHidden = true
//        gridResult.flattenedGlyphsNode?.isHidden = true
        gridResult.backgroundGeometry.firstMaterial?.diffuse.contents = image
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            gridResult.rawGlyphsNode.isHidden = true
            gridResult.flattenedGlyphsNode?.isHidden = true
        }
        
        return gridResult
    }
    
    @discardableResult
    private func doSyntaxConsume(rootSyntaxNode: Syntax) -> CodeGrid {
        laztrace(#fileID,#function,rootSyntaxNode)
        
        let attributedGlyphsWriter = vendAttributedGlyphsWriter
        let writeGlyphs = [.all, .glyphs].contains(displayMode)
        
        // Precache all known syntax
        if walkSemantics {
            FlatteningVisitor(
                target: codeGridSemanticInfo,
                builder: semanticInfoBuilder
            ).walkRecursiveFromSyntax(rootSyntaxNode)
        }
        
        for token in rootSyntaxNode.tokens {
            // Setup identifiers and build out token text
            let tokenId = token.id
            let tokenIdNodeName = tokenId.stringIdentifier
            let leadingTriviaNodeName = "\(tokenIdNodeName)-leadingTrivia"
            let trailingTriviaNodeName = "\(tokenIdNodeName)-trailingTrivia"
            let triviaColor = CodeGridColors.trivia
            let tokenColor = token.defaultColor
            
            var leadingTriviaNodes = CodeGridNodes()
            let leadingTrivia = token.leadingTrivia.stringified
            
            var tokenTextNodes = CodeGridNodes()
            let tokenText = token.text
            
            var trailingTriviaNodes = CodeGridNodes()
            let trailingTrivia = token.trailingTrivia.stringified
            
            // Write glyphs
            if writeGlyphs {
                attributedGlyphsWriter.writeString(leadingTrivia, leadingTriviaNodeName, triviaColor, &leadingTriviaNodes)
                attributedGlyphsWriter.writeString(tokenText, tokenIdNodeName, tokenColor, &tokenTextNodes)
                attributedGlyphsWriter.writeString(trailingTrivia, trailingTriviaNodeName, triviaColor, &trailingTriviaNodes)
            }
            
            // Save nodes to tokenCache *after* glyphs area created and inserted
            tokenCache[leadingTriviaNodeName] = leadingTriviaNodes
            tokenCache[tokenIdNodeName] = tokenTextNodes
            tokenCache[trailingTriviaNodeName] = trailingTriviaNodes
            
            codeGridSemanticInfo.insertNodeInfo(leadingTriviaNodeName, tokenId)
            codeGridSemanticInfo.insertNodeInfo(tokenIdNodeName, tokenId)
            codeGridSemanticInfo.insertNodeInfo(trailingTriviaNodeName, tokenId)
        }
        
        consumedRootSyntaxNodes.append(rootSyntaxNode)
        
        if writeGlyphs {
            attributedGlyphsWriter.finalize()
        }
        
        recomputeDisplayMode()
        return self
    }
}

// MARK: -- Displays configuration
extension CodeGrid {
    enum DisplayMode {
        case glyphs
        case all
    }
    
    func didSetDisplayMode() {
        recomputeDisplayMode()
    }
    
    func recomputeDisplayMode() {
//        switch displayMode {
//        case .layers:
//            fullTextBlitter.rootNode.isHidden = false
//            fullTextBlitter.backgroundGeometryNode.isHidden = false
//            rawGlyphsNode.isHidden = true
//            backgroundGeometryNode.isHidden = true
//        case .glyphs:
//            fullTextBlitter.rootNode.isHidden = true
//            fullTextBlitter.backgroundGeometryNode.isHidden = true
//            rawGlyphsNode.isHidden = false
//            backgroundGeometryNode.isHidden = false
//        case .all:
//            fullTextBlitter.rootNode.isHidden = false
//            fullTextBlitter.backgroundGeometryNode.isHidden = false
//            rawGlyphsNode.isHidden = true
//            backgroundGeometryNode.isHidden = true
//        }
    }
}
