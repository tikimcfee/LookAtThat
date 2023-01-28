//
//  GlyphCollection+Consume.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/21/22.
//

import Foundation
import SwiftSyntax

struct GlyphCollectionSyntaxConsumer: SwiftSyntaxFileLoadable {
    let targetGrid: CodeGrid
    let targetCollection: GlyphCollection
    var writer: GlyphCollectionWriter
    
    init(targetGrid: CodeGrid) {
        self.targetGrid = targetGrid
        self.targetCollection = targetGrid.rootNode
        self.writer = GlyphCollectionWriter(target: targetCollection)
    }
  
    @discardableResult
    func consume(url: URL) -> CodeGrid {
        guard let fileSource = loadSourceUrl(url) else {
            return consumeText(textPath: url)
        }
        consume(rootSyntaxNode: Syntax(fileSource))
        return targetGrid
    }
    
    func consumeText(textPath: URL) -> CodeGrid {
        guard let fullString = try? String(contentsOf: textPath) else {
            return targetGrid
        }
        var nodes = CodeGridNodes()
        let id = "raw-text-\(UUID().uuidString)"
        write(fullString, id, NSUIColor.white, &nodes)
        targetGrid.tokenCache[id] = nodes
        return targetGrid
    }
    
    func consume(rootSyntaxNode: Syntax) {
        FlatteningVisitor(
            target: targetGrid.semanticInfoMap,
            builder: targetGrid.semanticInfoBuilder
        ).walkRecursiveFromSyntax(rootSyntaxNode)
        
        for token in rootSyntaxNode.tokens {
            consumeSyntaxToken(token)
        }
        
        targetGrid.consumedRootSyntaxNodes.append(rootSyntaxNode)
        targetGrid.updateBackground()
        targetCollection.setRootMesh()
    }
    
    private func consumeSyntaxToken(_ token: TokenSyntax) {
        // Setup identifiers and build out token text
        let tokenId = token.id
        let tokenIdNodeName = tokenId.stringIdentifier
        let triviaColor = CodeGridColors.trivia
        let tokenColor = token.defaultColor
        
        // Combine all nodes into same set, colorize trivia differently
        var allCharacterNodes = CodeGridNodes()
        let leadingTrivia = token.leadingTrivia.stringified
        let tokenText = token.text
        let trailingTrivia = token.trailingTrivia.stringified
        
        write(leadingTrivia, tokenIdNodeName, triviaColor, &allCharacterNodes)
        write(tokenText, tokenIdNodeName, tokenColor, &allCharacterNodes)
        write(trailingTrivia, tokenIdNodeName, triviaColor, &allCharacterNodes)
        
        targetGrid.tokenCache[tokenIdNodeName] = allCharacterNodes
        targetGrid.semanticInfoMap.insertNodeInfo(tokenIdNodeName, tokenId)
    }
    
    func write(
        _ string: String,
        _ nodeID: NodeSyntaxID,
        _ color: NSUIColor,
        _ writtenNodeSet: inout CodeGridNodes
    ) {
        // Fetch parent buffer index to set for all new written nodes
        var parentBufferIndex: IndexedBufferType = .zero
        targetGrid.updateVirtualParentConstants? {
            parentBufferIndex = $0.bufferIndex
        }
        
        for newCharacter in string {
            let glyphKey = GlyphCacheKey(source: newCharacter, color)
            writer.addGlyph(glyphKey) { glyph, constants in
                glyph.meta.syntaxID = nodeID
                writtenNodeSet.insert(glyph)
                constants.parentIndex = parentBufferIndex
            }
        }
    }
    
//    func writeWord(
//        _ string: String,
//        _ wordID: NodeSyntaxID,
//        _ color: NSUIColor,
//        _ writtenNodeSet: inout CodeGridNodes
//    ) {
//        // Fetch parent buffer index to set for all new written nodes
//        var parentBufferIndex: IndexedBufferType = .zero
//        targetGrid.updateVirtualParentConstants? {
//            parentBufferIndex = $0.bufferIndex
//        }
//
//        let glyphKey = GlyphCacheKey(source: string, color)
//        writer.addGlyph(glyphKey) { glyph, constants in
//            glyph.meta.syntaxID = wordID
//            writtenNodeSet.insert(glyph)
//            constants.parentIndex = parentBufferIndex
//        }
//    }
}
