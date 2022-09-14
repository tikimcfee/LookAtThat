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
    
    init(targetGrid: CodeGrid) {
        self.targetGrid = targetGrid
        self.targetCollection = targetGrid.rootNode
    }
    
    func consume(url: URL) {
        guard let fileSource = loadSourceUrl(url) else { return }
        consume(rootSyntaxNode: Syntax(fileSource))
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
        let parent = targetGrid.virtualParent
        for newCharacter in string {
            // NOTE: This is awkard, but we immediately update the node's ID
            // to the given name. This is unsafe, as the ID is set deep down
            // in the node itself automatically. Might want to create a new
            // pathway for this...
            let glyphKey = GlyphCacheKey(source: newCharacter, color)
            guard let glyph = targetCollection.addGlyph(glyphKey) else {
                print("Failed to render glyph for: \(newCharacter)")
                return
            }
            glyph.meta.syntaxID = nodeID
            writtenNodeSet.insert(glyph)
            
            if let parent = parent {
                // Parent is set by collection; reset before
                // adding to acknowledge multiparent warning
                glyph.parent = nil
                parent.add(child: glyph)
            }
        }
    }
}
