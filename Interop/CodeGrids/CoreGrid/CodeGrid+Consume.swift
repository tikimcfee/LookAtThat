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
        doTextConsume(text: text)
        return self
    }
    
    @discardableResult
    private func doTextConsume(text: String) -> CodeGrid {
        print("TODO: Add text consume!")
        return self
    }
}

//MARK: -- Consume Syntax
extension CodeGrid {
    private var writeGlyphs: Bool {
//        [.all, .glyphs].contains(displayMode)
        return true
    }
    
    @discardableResult
    func consume(rootSyntaxNode: Syntax) -> CodeGrid {
        doSyntaxConsume(rootSyntaxNode: rootSyntaxNode)
        return self
        
//        doSyntaxConsume(rootSyntaxNode: rootSyntaxNode)
    }
    
    @discardableResult
    private func doSyntaxConsume(rootSyntaxNode: Syntax) -> CodeGrid {
        laztrace(#fileID,#function,rootSyntaxNode)
        
        // Precache all known syntax
        if walkSemantics {
            FlatteningVisitor(
                target: codeGridSemanticInfo,
                builder: semanticInfoBuilder
            ).walkRecursiveFromSyntax(rootSyntaxNode)
        }
        
        for token in rootSyntaxNode.tokens {
            consumeSyntaxToken(token)
        }
        
        consumedRootSyntaxNodes.append(rootSyntaxNode)
    
        return self
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
        
//        // Write glyphs
//        attributedGlyphsWriter.writeString(leadingTrivia, leadingTriviaNodeName, triviaColor, &leadingTriviaNodes)
//        attributedGlyphsWriter.writeString(tokenText, tokenIdNodeName, tokenColor, &tokenTextNodes)
//        attributedGlyphsWriter.writeString(trailingTrivia, trailingTriviaNodeName, triviaColor, &trailingTriviaNodes)
        
        // Save nodes to tokenCache *after* glyphs area created and inserted
        // Skippable to shave off time for large root directories
        tokenCache[leadingTriviaNodeName] = leadingTriviaNodes
        tokenCache[tokenIdNodeName] = tokenTextNodes
        tokenCache[trailingTriviaNodeName] = trailingTriviaNodes
        
        codeGridSemanticInfo.insertNodeInfo(leadingTriviaNodeName, tokenId)
        codeGridSemanticInfo.insertNodeInfo(tokenIdNodeName, tokenId)
        codeGridSemanticInfo.insertNodeInfo(trailingTriviaNodeName, tokenId)
    }
}
