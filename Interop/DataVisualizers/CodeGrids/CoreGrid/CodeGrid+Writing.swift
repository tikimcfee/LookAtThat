//
//  CodeGrid+Writing.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/12/21.
//

import Foundation
import SceneKit
import SwiftSyntax

// MARK: -- Writer Vending
extension CodeGrid {
    var vendRawGlyphWriter: RawGlyphs {
        return RawGlyphs(self)
    }
    
    var vendAttributedGlyphsWriter: AttributedGlyphs {
        return AttributedGlyphs(self)
    }
    
    private func createNodeFor(
        _ syntaxTokenCharacter: Character,
        _ color: NSUIColor
    ) -> GlyphNode {
        laztrace(#fileID,#function,syntaxTokenCharacter,color)
        let key = GlyphCacheKey("\(syntaxTokenCharacter)", color)
        let (rootLayer, focusLayer, size) = glyphCache[key]
        let letterNode = GlyphNode.make(rootLayer, focusLayer, size)
        letterNode.categoryBitMask = HitTestType.codeGridToken.rawValue
        return letterNode
    }
}

//MARK: -- Writers
extension CodeGrid {
    class Writer {
        let grid: CodeGrid
        var rootNode: SCNNode { grid.rootNode }
        
        init(_ grid: CodeGrid) {
            self.grid = grid
        }
        
        func attributedString(_ string: String, _ color: NSUIColor) -> NSAttributedString {
            NSAttributedString(string: string, attributes: [
                .foregroundColor: color.cgColor,
                .font: FontRenderer.shared.font
            ])
        }
    }
    
    class RawGlyphs: Writer {
        func writeGlyphs(_ text: String) {
            writeString(text, text, .white)
        }
        
        private func writeString(_ string: String, _ name: String, _ color: NSUIColor) {
            for newCharacter in string {
                let glyphNode = grid.createNodeFor(newCharacter, color)
                glyphNode.name = name
                grid.renderer.insert(newCharacter, glyphNode, glyphNode.size)
            }
        }
    }
    
    class AttributedGlyphs: Writer {
        func writeString(
            _ string: String,
            _ name: String,
            _ color: NSUIColor,
            _ set: inout CodeGridNodes
        ) {
            for newCharacter in string {
                let glyphNode = grid.createNodeFor(newCharacter, color)
                glyphNode.name = name
                set.insert(glyphNode)
                grid.renderer.insert(newCharacter, glyphNode, glyphNode.size)
            }
        }
        
        func finalize() {
            grid.renderer.eraseWhitespace()
            grid.flattenRootGlyphNode()
        }
    }
}

// MARK: -- Consume Text
extension CodeGrid {
    // If you call this, you basically draw text like a typewriter from wherevery you last were.
    // it adds caches layer glyphs motivated by display requirements inherited by those clients.
    @discardableResult
    func consume(text: String) -> Self {
        laztrace(#fileID,#function,text)
        switch displayMode {
        case .glyphs:
            vendRawGlyphWriter.writeGlyphs(text)
        case .all:
            vendRawGlyphWriter.writeGlyphs(text)
        }
        recomputeDisplayMode()
        return self
    }
}

//MARK: -- Consume Syntax
extension CodeGrid {
    
    @discardableResult
    func consume(rootSyntaxNode: Syntax) -> CodeGrid {
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
        
        // Flushing implicit transaction immediately saves a few cycles
        // and removes need to 'wait' for elements to appear after finalization..
        flushSceneKitTransactions()
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
