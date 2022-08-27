//
//  GlyphCollection+Consume.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/21/22.
//

import Foundation
import SwiftSyntax

struct GlyphCollectionSyntaxConsumer: SwiftSyntaxFileLoadable {
    let targetCollection: GlyphCollection
    let targetGrid: CodeGrid
    
    func consume(
        url: URL
    ) {
        guard let source = loadSourceUrl(url) else { return }
        consume(
            rootSyntaxNode: Syntax(source)
        )
    }
    
    func consume(
        rootSyntaxNode: Syntax
    ) {
        FlatteningVisitor(
            target: targetGrid.codeGridSemanticInfo,
            builder: targetGrid.semanticInfoBuilder
        ).walkRecursiveFromSyntax(rootSyntaxNode)
        
        for token in rootSyntaxNode.tokens {
            consumeSyntaxToken(token)
        }
    }
    
    private func consumeSyntaxToken(_ token: TokenSyntax) {
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
        
        writeString(leadingTrivia, leadingTriviaNodeName, triviaColor, &leadingTriviaNodes)
        writeString(tokenText, tokenIdNodeName, tokenColor, &tokenTextNodes)
        writeString(trailingTrivia, trailingTriviaNodeName, triviaColor, &trailingTriviaNodes)
        
        targetGrid.tokenCache[leadingTriviaNodeName] = leadingTriviaNodes
        targetGrid.tokenCache[tokenIdNodeName] = tokenTextNodes
        targetGrid.tokenCache[trailingTriviaNodeName] = trailingTriviaNodes
        
        targetGrid.codeGridSemanticInfo.insertNodeInfo(leadingTriviaNodeName, tokenId)
        targetGrid.codeGridSemanticInfo.insertNodeInfo(tokenIdNodeName, tokenId)
        targetGrid.codeGridSemanticInfo.insertNodeInfo(trailingTriviaNodeName, tokenId)
    }
    
    func writeString(
        _ string: String,
        _ name: String,
        _ color: NSUIColor,
        _ set: inout CodeGridNodes
    ) {
        for newCharacter in string {
            let glyph = targetCollection.addGlyph(GlyphCacheKey(source: newCharacter, color))
            guard let glyph = glyph else {
                print("Failed to render glyph for: \(newCharacter)")
                return
            }
            set.insert(glyph)
        }
    }
}
