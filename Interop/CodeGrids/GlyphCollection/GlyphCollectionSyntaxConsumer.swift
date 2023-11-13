//
//  GlyphCollection+Consume.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/21/22.
//

import Foundation
import SwiftSyntax
import MetalLink
import BitHandling

struct GlyphCollectionSyntaxConsumer: SwiftSyntaxFileLoadable {
    let targetGrid: CodeGrid
    let targetCollection: GlyphCollection
    var writer: GlyphCollectionWriter
    
    private static let __TEST_ASYNC__ = false
    
    init(targetGrid: CodeGrid) {
        self.targetGrid = targetGrid
        self.targetCollection = targetGrid.rootNode
        self.writer = GlyphCollectionWriter(target: targetCollection)
    }
  
    @discardableResult
    func consume(url: URL) -> CodeGrid {
        if Self.__TEST_ASYNC__ {
            return __asyncConsume(url: url)
        } else {
            guard let fileSource = loadSourceUrl(url) else {
                return consumeText(textPath: url)
            }
            
            let size = fileSource.root.allText.count + 512
            print("got \(size) textses")
            try? targetGrid
                .rootNode
                .instanceState
                .constants
                .expandBuffer(nextSize: size, force: true)
            
            print("starting consume: \(url.lastPathComponent)")
            consume(rootSyntaxNode: Syntax(fileSource))
            print("completed consume: \(url.lastPathComponent)")
            
            return targetGrid
        }
    }
    
    private func __asyncConsume(url: URL) -> CodeGrid {
        let sem = DispatchSemaphore(value: 0)
        Task(priority: .userInitiated) {
            await acceleratedConsume(url: url)
            sem.signal()
        }
        sem.wait()
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
    
    // --> cmd+f 'slow-stuff'
    func consume(rootSyntaxNode: Syntax) {
        FlatteningVisitor(
            target: targetGrid.semanticInfoMap,
            builder: targetGrid.semanticInfoBuilder
        ).walkRecursiveFromSyntax(rootSyntaxNode)
        
        for token in rootSyntaxNode.tokens(viewMode: .all) {
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
        for newCharacter in string {
            let glyphKey = GlyphCacheKey(source: newCharacter, color)
//            let glyphKey = GlyphCacheKey.fromCache(source: newCharacter, color)
            if let node = writer.writeGlyphToState(glyphKey) {
                node.meta.syntaxID = nodeID
                writtenNodeSet.append(node)
                targetCollection.renderer.insert(node)
            } else {
                print("nooooooooooooooooooooo!")
            }
        }
    }
    
    
    func acceleratedConsume(
        url: URL
    ) async {
        let reader = SplittingFileReader(targetURL: url)
        let stream = reader.indexingAsyncLineStream()
        
        let id = "raw-text-\(UUID().uuidString)"
        
        let glyphKey = GlyphCacheKey(source: "\n", .white)
        guard let lineBreakNode = writer.writeGlyphToState(glyphKey) else {
            return
        }
        let lineBreakSize = lineBreakNode.quadSize
        
        var made = [[GlyphNode]]()
        for await (line, lineOffset) in stream {
            let result = targetCollection.renderer.insertLineRaw(
                line: line,
                lineOffset: lineOffset,
                lineOffsetSize: lineBreakSize,
                writer: writer,
                rawId: id
            )
            made.append(result)
        }
//        targetGrid.tokenCache[id] = made.flatMap { $0 }
        targetGrid.updateBackground()
        targetCollection.setRootMesh()
    }
}

/* MARK: - slow-stuff
 Observation:
    - linearly advancing characters is slow to render
    - we rely on the order of nodes to render one by one
    - each token contains an absolute position and a length
    - it may be possible to render the text, then associate each utf index with the cached syntax
    -- so: split lines, for each character, get index (map it?)
    -- maybe the splitter needs to emit utf indices per line, and I map them
 ** token.position.utf8Offset
 
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
