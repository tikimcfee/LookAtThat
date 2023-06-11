//
//  GlyphCollection+Consume.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/21/22.
//

import Foundation
import SwiftSyntax
import MetalLink

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
        
        /*
         Observation:
            - linearly advancing characters is slow to render
            - we rely on the order of nodes to render one by one
            - each token contains an absolute position and a length
            - it may be possible to render the text, then associate each utf index with the cached syntax
            -- so: split lines, for each character, get index (map it?)
            -- maybe the splitter needs to emit utf indices per line, and I map them
         
         let lineReader = LineReader()
         for line in lineReader {
            renderLine() // <--- 'rendering' in this case is just building out the glyphs; capture glyphs?
                         // Each line could be a separately managed item... meh... JSON kills that.
                         // Indexing in seems correct, but I have to parse and to render at the same time.
                         // I want to do both at the same time for performance but...
                         // maybe I just don't right now, and just deal with rendering.
         }
         
         -- 'consumeSyntax'
         The trick here is that I'm directly mapping the syntax token to the result set of nodes.
         However, since I can get the UTF index out of the line reader (probably), I can map each index
         to the corresponding node instead:
            0: 'i' -> Token(import statement) -> Node(x)
            1: 'm' -> Token(import statement) -> Node(x+1)
            2: 'p' -> Token(import statement) -> Node(x+2)
            3: 'o' -> Token(import statement) -> Node(x+3)
            4: 'r' -> Token(import statement) -> Node(x+5)
            5: 't' -> Token(import statement) -> Node(x+6)
         
         So...
         In parallel:
            splitting reader -> split lines -> async kickoff per line
                -> generate [UTF8Index: GlyphNode] (another map, hooray, lol)
                -> RETURN the map, and then merge together at the end - avoid locking if possible
         
         In parallel(??):
            run syntax parser
                -> iterate over tokens (this gives us the correct syntanctic ordering; tree-sitter can sit here
                -> blit the token and the index into a map; the index is the start, soo..
         
         After both:
            combine result maps:
                -> splitting reader has all glyphs; syntax parser has all node position starts
                -> iterate over *syntax tokens* and collect *glyphs*
                    --> for each token, get the start index, and check the count
                    --> for each next token, look up the node and combine into the current set of nodes
                    --> stick the result into `tokenCache'
         */
        
        for token in rootSyntaxNode.tokens(viewMode: .all) {
            
//            token.position.utf8Offset
            
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
//                writtenNodeSet.insert(glyph)
                writtenNodeSet.append(glyph)
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
