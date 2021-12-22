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
    var vendRawFullTextWriter: RawFullText {
        return RawFullText(self)
    }
    
    var vendRawGlyphWriter: RawGlyphs {
        return RawGlyphs(self)
    }
    
    var vendAttributedFullTextWriter: AttributedFullText {
        return AttributedFullText(self)
    }
    
    var vendAttributedGlyphsWriter: AttributedGlyphs {
        return AttributedGlyphs(self)
    }
    
    private func createNodeFor(
        _ syntaxTokenCharacter: Character,
        _ color: NSUIColor
    ) -> (SCNNode, CGSize) {
        laztrace(#fileID,#function,syntaxTokenCharacter,color)
        let key = GlyphCacheKey("\(syntaxTokenCharacter)", color)
        let (geometry, size) = glyphCache[key]
        
        let letterNode = SCNNode()
        letterNode.geometry = geometry
        letterNode.categoryBitMask = HitTestType.codeGridToken.rawValue
        
        return (letterNode, size)
    }
}

//MARK: -- Writers
extension CodeGrid {
    class Writer {
        let grid: CodeGrid
        var fullTextBlitter: CodeGridBlitter { grid.fullTextBlitter }
        var fullTextLayerBuilder: FullTextLayerBuilder { grid.fullTextLayerBuilder }
        var rootNode: SCNNode { grid.rootNode }
        
        init(_ grid: CodeGrid) {
            self.grid = grid
        }
        
        func attributedString(_ string: String, _ color: NSUIColor) -> NSAttributedString {
            NSAttributedString(string: string, attributes: [.foregroundColor: color.cgColor])
        }
    }
    
    class RawFullText: Writer {
        let zOffset = VectorFloat(2.0)
        
        func writeAttributedText(_ text: String) {
            let sourceAttributedString = NSMutableAttributedString()
            sourceAttributedString.append(attributedString(text, .white))
            
            fullTextBlitter.createBackingFlatLayer(fullTextLayerBuilder, sourceAttributedString)
            fullTextBlitter.rootNode.position.z += zOffset
            
            rootNode.addChildNode(fullTextBlitter.rootNode)
        }
    }
    
    class RawGlyphs: Writer {
        func writeGlyphs(_ text: String) {
            writeString(text, text, .white)
        }
        
        private func writeString(_ string: String, _ name: String, _ color: NSUIColor) {
            for newCharacter in string {
                let (letterNode, size) = grid.createNodeFor(newCharacter, color)
                
                let limit = name.index(name.startIndex, offsetBy: 32, limitedBy: name.endIndex)
                let name = String(name.prefix(upTo: limit ?? name.startIndex))
                
                letterNode.name = name
                grid.renderer.insert(newCharacter, letterNode, size)
            }
        }
    }
    
    class AttributedFullText: Writer {
        private let zOffset = VectorFloat(2.0)
        
        var sourceAttributedString = NSMutableAttributedString()
        
        func writeAttributedText(_ text: String, color: NSUIColor) {
            sourceAttributedString.append(attributedString(text, color))
        }
        
        func finalize() {
            fullTextBlitter.createBackingFlatLayer(
                fullTextLayerBuilder,
                sourceAttributedString
            )
            fullTextBlitter.rootNode.position.z += zOffset
            grid.rootNode.addChildNode(fullTextBlitter.rootNode)
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
                let (letterNode, size) = grid.createNodeFor(newCharacter, color)
                letterNode.name = name
                set.insert(letterNode)
                grid.renderer.insert(newCharacter, letterNode, size)
            }
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
        case .layers:
            vendRawFullTextWriter.writeAttributedText(text)
        case .glyphs:
            vendRawGlyphWriter.writeGlyphs(text)
        case .all:
            vendRawFullTextWriter.writeAttributedText(text)
            vendRawGlyphWriter.writeGlyphs(text)
        }
        recomputeDisplayMode()
        
//        renderer.eraseWhitespace()
        return self
    }
}

//MARK: -- Consume Syntax
extension CodeGrid {
    
    @discardableResult
    func consume(syntax: Syntax) -> Self {
        laztrace(#fileID,#function,syntax)
        
        lazy var attributedTextWriter = vendAttributedFullTextWriter
        lazy var attributedGlyphsWriter = vendAttributedGlyphsWriter
        
        let writeText = [.all, .layers].contains(displayMode)
        let writeGlyphs = [.all, .glyphs].contains(displayMode)
        
        for token in syntax.tokens {
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
            
            // Write attributed text
            if writeText {
                attributedTextWriter.writeAttributedText(leadingTrivia, color: triviaColor)
                attributedTextWriter.writeAttributedText(tokenText, color: tokenColor)
                attributedTextWriter.writeAttributedText(trailingTrivia, color: triviaColor)
            }
            
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
            
            if walkSemantics {
                walkHierarchyForSemantics(
                    rootSyntax: syntax,
                    token, tokenId, tokenIdNodeName,
                    fileName
                )
            }
        }
        
        if writeText {
            attributedTextWriter.finalize()
        }

//        renderer.eraseWhitespace()
        recomputeDisplayMode()
        return self
    }
    
    func walkHierarchyForSemantics(
        rootSyntax: Syntax,
        _ token: TokenSyntax,
        _ tokenId: SyntaxIdentifier,
        _ tokenIdNodeName: String,
        _ sourceFileName: String
    ) {
        // Walk the parenty hierarchy and associate these nodes with that parent.
        // Add semantic info to lookup for each parent node found.
        var tokenParent: Syntax? = Syntax(token)
        while tokenParent != nil && tokenParent?.id != rootSyntax.id {
            guard let parent = tokenParent else { continue }
            let parentId = parent.id
            codeGridSemanticInfo.saveSemanticInfo(
                parentId,
                tokenIdNodeName,
                semanticInfoBuilder.semanticInfo(
                    for: parent,
                    fileName: sourceFileName
                )
            )
            codeGridSemanticInfo.associate(
                syntax: parent,
                withLookupId: tokenId
            )
            tokenParent = parent.parent
        }
    }
}

// MARK: -- Displays configuration
extension CodeGrid {
    enum DisplayMode {
        case glyphs
        case layers
        case all
    }
    
    func didSetDisplayMode() {
        recomputeDisplayMode()
    }
    
    func recomputeDisplayMode() {
        switch displayMode {
        case .layers:
            fullTextBlitter.rootNode.isHidden = false
            fullTextBlitter.backgroundGeometryNode.isHidden = false
            rootGlyphsNode.isHidden = true
            backgroundGeometryNode.isHidden = true
        case .glyphs:
            fullTextBlitter.rootNode.isHidden = true
            fullTextBlitter.backgroundGeometryNode.isHidden = true
            rootGlyphsNode.isHidden = false
            backgroundGeometryNode.isHidden = false
        case .all:
            fullTextBlitter.rootNode.isHidden = false
            fullTextBlitter.backgroundGeometryNode.isHidden = false
            rootGlyphsNode.isHidden = true
            backgroundGeometryNode.isHidden = true
        }
    }
}
