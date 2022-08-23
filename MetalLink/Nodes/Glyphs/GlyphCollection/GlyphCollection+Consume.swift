//
//  GlyphCollection+Consume.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/21/22.
//

import Foundation
import SwiftSyntax

struct SyntaxGlyphTransformer: SwiftSyntaxFileLoadable {
    let target: GlyphCollection
    
    func consume(url: URL) {
        guard let source = loadSourceUrl(url) else { return }
        doSyntaxConsume(rootSyntaxNode: Syntax(source))
    }
    
    private func doSyntaxConsume(rootSyntaxNode: Syntax) {
        //        FlatteningVisitor(
        //            target: codeGridSemanticInfo,
        //            builder: semanticInfoBuilder
        //        ).walkRecursiveFromSyntax(rootSyntaxNode)
        
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
    }
    
    func writeString(
        _ string: String,
        _ name: String,
        _ color: NSUIColor,
        _ set: inout CodeGridNodes
    ) {
        for newCharacter in string {
            target.addGlyph(GlyphCacheKey(source: newCharacter, color))
        }
    }
}
