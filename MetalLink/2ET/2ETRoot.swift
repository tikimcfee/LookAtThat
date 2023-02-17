//
//  2ETRoot.swift
//  MetalSimpleInstancing
//
//  Created by Ivan Lugo on 8/6/22.
//  Copyright © 2022 Metal by Example. All rights reserved.
//
//  - With thanks to Rick Twohy
//  https://discord.gg/hKPBTbC
//

import Combine
import MetalKit
import SwiftUI
import SwiftParser
import SwiftSyntax

class TwoETimeRoot: MetalLinkReader {
    let link: MetalLink
    
    var bag = Set<AnyCancellable>()
    
    lazy var root = RootNode(camera)
    
    lazy var builder = try! CodeGridGlyphCollectionBuilder(
        link: link,
        sharedSemanticMap: GlobalInstances.gridStore.globalSemanticMap,
        sharedTokenCache: GlobalInstances.gridStore.globalTokenCache,
        sharedGridCache: GlobalInstances.gridStore.gridCache
    )
    
    var camera: DebugCamera {
        GlobalInstances.debugCamera
    }
    
    var editor: WorldGridEditor {
        GlobalInstances.gridStore.editor
    }
    
    var focus: WorldGridFocusController {
        GlobalInstances.gridStore.worldFocusController
    }
    
    init(link: MetalLink) throws {
        self.link = link
        view.clearColor = MTLClearColorMake(0.03, 0.1, 0.2, 1.0)
        
        camera.interceptor.onNewFileOperation = handleDirectory
        camera.interceptor.onNewFocusChange = handleFocus
        
        GlobalInstances
            .gridStore
            .gridInteractionState
            .setupStreams()
        
//        try setupNodeChildTest()
//        try setupNodeBackgroundTest()
//        try setupBackgroundTest()
//        try setupSnapTestMulti()
//        try setupTriangleStripTest()
//        try setupWordWare()
//        try setupWordWareSentence()
//        try setupWordWarePLA()
        try setupDictionaryTest()
        
         // TODO: ManyGrid need more abstractions
//        try setupSnapTestMonoMuchDataManyGrid()
    }
    
    func delegatedEncode(in sdp: inout SafeDrawPass) {
        let dT =  1.0 / Float(link.view.preferredFramesPerSecond)
        
        // TODO: Create a proper container for all this glyph parent stuff.
        // Collection, builder, consumer, writer, grid... lol.
        // One more can't hurt.
        sdp.renderCommandEncoder.setVertexBuffer(
            builder.parentBuffer.buffer,
            offset: 0,
            index: 3
        )
        
        // TODO: Make update and render a single pass to avoid repeated child loops
        root.update(deltaTime: dT)
        root.render(in: &sdp)
    }
    
    func handleFocus(_ direction: SelfRelativeDirection) {
        let focused = editor.lastFocusedGrid
        guard let current = focused else { return }
        
        let grids = editor.snapping.gridsRelativeTo(current, direction)
        
        if let first = grids.first {
            focus.state = .set(first.targetGrid)
        } else {
            focus.state = .set(current)
        }
    }
    
    func handleDirectory(_ file: FileOperation) {
        switch file {
        case .openDirectory:
            openDirectory { file in
                guard let url = file.parent else { return }
                GlobalInstances.fileBrowser.setRootScope(url)
            }
        }
    }
}

// MARK: - Current Test
class WordNode: MetalLinkNode {
    let glyphs: CodeGridNodes
    let parentGrid: CodeGrid
    
    init(
        glyphs: CodeGridNodes,
        parentGrid: CodeGrid
    ) {
        self.glyphs = glyphs
        self.parentGrid = parentGrid
        super.init()
        
        let bounds = BoundsComputing()
        bounds.consumeNodeSet(Set(glyphs), convertingTo: nil)
        var xOffset: Float = -BoundsWidth(bounds.bounds) / 4.0
        
        for glyph in glyphs {
            glyph.parent = self
            glyph.position = LFloat3(x: xOffset, y: 0, z: 0)
            xOffset += glyph.boundsWidth
        }
        
        push()
    }
    
    func doOnAll(_ receiver: (CodeGridNodes) -> Void) {
        receiver(glyphs)
        parentGrid.pushNodes(glyphs)
    }
    
    func push(_ receiver: (WordNode) -> Void) {
        receiver(self)
        parentGrid.pushNodes(glyphs)
    }
    
    func push() {
        parentGrid.pushNodes(glyphs)
    }
    
    func update(_ action: @escaping (WordNode) -> Void) {
        Task {
            action(self)
            push()
        }
    }
}

struct WordDictionary: Codable {
    let words: [String: String]
    
    init(file: URL) {
        self.words = try! JSONDecoder().decode(
            [String: String].self,
            from: Data(contentsOf: file, options: .alwaysMapped)
        )
    }
}

actor WordPositioner {
    private var column: Int = -1
    private var row: Int = -1
    let length: Int
    
    init(length: Int) {
        self.length = length
    }
    
    func nextRow() -> Int {
        row += 1
        
        if row >= length {
            column += 8
            row = 0
        }
        
        return row
    }
    
    func nextColumn() -> Int {
        column += 1
        return column
    }
}

actor WordBuilder {
    let wordContainerGrid: CodeGrid
    let positioner: WordPositioner
    
    init(
        wordContainerGrid: CodeGrid,
        positioner: WordPositioner
    ) {
        self.wordContainerGrid = wordContainerGrid
        self.positioner = positioner
    }
    
    func make(word: String) async -> WordNode {
        let (_, sourceGlyphs) = wordContainerGrid.consume(text: word)
        let node = WordNode(glyphs: sourceGlyphs, parentGrid: wordContainerGrid)
        
        let column = await positioner.nextColumn().float
        let row = await positioner.nextRow().float * -1
        
        node.update {
            $0.position = LFloat3(
                x: column * 2.0,
                y: row * 2.0,
                z: 0
            )
        }
        
        return node
    }
}

extension TwoETimeRoot {
    func setupDictionaryTest() throws {
        openFile { file in
            switch file {
            case .success(let url):
                kickoffJsonLoad(url)
                
            default:
                break
            }
        }
        
//        /// JUST DON'T.
//        /// ASYNC / AWAIT. NOT EVEN ONCE.
//        func kickoffJsonLoadAsyncStyle(_ url: URL) {
//            let wordContainerGrid = builder.createGrid(
//                bufferSize: 15_500_000
//            )
//            wordContainerGrid.removeBackground()
//            wordContainerGrid.translated(dZ: -100.0)
//
//            let dictionary = WordDictionary(file: url)
//            print("Defined words: \(dictionary.words.count)")
//
//            let sideLength = Int(sqrt(dictionary.words.count.float)) * 2
//            let positioner = WordPositioner(length: sideLength)
//            let builder = WordBuilder(wordContainerGrid: wordContainerGrid, positioner: positioner)
//
//            Task { [builder] in
//                var group = DispatchGroup()
//                for (word, definition) in dictionary.words {
//                    group.enter()
//                    Task { [builder, group] in
//                        let wordNode = await builder.make(word: word)
//                        group.leave()
//                    }
//                }
//                group.wait()
//                root.add(child: wordContainerGrid.rootNode)
//            }
//
////            root.add(child: wordContainerGrid.rootNode)
//        }
        
        func kickoffJsonLoad(_ url: URL) {
            let wordContainerGrid = builder.createGrid(
                bufferSize: 15_500_000
            )
            wordContainerGrid.removeBackground()
            wordContainerGrid.translated(dZ: -100.0)
            
            let dictionary = WordDictionary(file: url)
            print("Defined words: \(dictionary.words.count)")
            
            let sideLength = Int(sqrt(dictionary.words.count.float)) * 2
            
            var rowCount = 0
            var colCount = 0
            
//            let layout = DepthLayout()
            
//            var stop = 1_000_000
            
            for (word, definition) in dictionary.words {
                let (_, sourceGlyphs) = wordContainerGrid.consume(text: word)
                let sourceNode = WordNode(glyphs: sourceGlyphs, parentGrid: wordContainerGrid)
                
                sourceNode.update {
                    $0.position = LFloat3(
                        x: colCount.float * 2.0,
                        y: -rowCount.float * 2.0,
                        z: 0
                    )
                }
                
//                var lastWord: WordNode = sourceNode
//                let definitionWords = definition.splitToWords
//                for definitionWord in definitionWords {
//                    let (_, sourceGlyphs) = wordContainerGrid.consume(text: definitionWord)
//                    let sourceNode = WordNode(glyphs: sourceGlyphs, parentGrid: wordContainerGrid)
//                    
//                    sourceNode.position = lastWord.position.translated(dZ: -8)
//                    sourceNode.push()
//                    
//                    lastWord = sourceNode
//                }
                
                rowCount += 1
                if rowCount == sideLength {
                    colCount += 8
                    rowCount = 0
                }
                
//                stop -= 1
//
//                if stop <= 0 {
//                    print("\n\n -- Stopped Early -- \n\n")
//                    break
//                }
            }
            
            root.add(child: wordContainerGrid.rootNode)
        }
    }
    
    func setupWordWarePLA() throws {
        let wordContainerGrid = builder.createGrid()
        wordContainerGrid.removeBackground()
        wordContainerGrid.translated(dZ: -100.0)
        
        let testSentence = "Hello. My name is Ivan. My intent is understanding and peace. Hello. My name is Ivan. My intent is understanding and peace. Hello. My name is Ivan. My intent is understanding and peace."
        let sentences = Array(repeating: testSentence, count: 100)
        let layout = DepthLayout()
        
        var center = LFloat3.zero
        var allNodes = [WordNode]()
        for sentence in sentences {
            var wordNodes = [WordNode]()
            
            let sentenceWords = sentence.splitToWords
            for word in sentenceWords {
                let (_, wordGlyphs) = wordContainerGrid.consume(text: word)
                let wordNode = WordNode(glyphs: wordGlyphs, parentGrid: wordContainerGrid)
                wordNodes.append(wordNode)
                allNodes.append(wordNode)
            }
            
            layout.layoutGrids2(center.x, center.y, center.z, wordNodes, wordContainerGrid)
            center.translateBy(dX: 16.0)
        }
        
        root.add(child: wordContainerGrid.rootNode)
        
        var counter: Float = 0.0
        QuickLooper(
            interval: .milliseconds(16),
            loop: {
                for node in allNodes {
                    node.update {
                        $0.position.x += -cos(counter / 100)
                    }
                }
                counter += 1.0
            }
        ).runUntil { false }
    }
    
    
    func setupWordWareSentence() throws {
        let wordContainerGrid = builder.createGrid()
        wordContainerGrid.removeBackground()
        wordContainerGrid.translated(dZ: -50.0)
        
        let testSentence = "Hello. My name is Ivan. My intent is understanding and peace.\n"
        let sentences = Array(repeating: testSentence, count: 100)
        
        var wordNodes = [WordNode]()
        
        for sentence in sentences {
            let sentenceWords = sentence.splitToWordsAndSpaces
            for word in sentenceWords {
                let (_, wordGlyphs) = wordContainerGrid.consume(text: word)
                let wordNode = WordNode(glyphs: wordGlyphs, parentGrid: wordContainerGrid)
                wordNodes.append(wordNode)
            }
        }
        
        root.add(child: wordContainerGrid.rootNode)
        
        WorkerPool.shared.nextWorker().async {
            for wordNode in wordNodes {
                var counter = Double.random(in: (0.0...1.0))
                QuickLooper(
                    interval: .milliseconds(16),
                    loop: {
                        wordNode.push {
                            $0.translate(
                                dX: cos(counter.float / 5.0.float),
                                dY: sin(counter.float / 5.0.float)
                            )
                        }
                        counter += 1.0
                    }
                ).runUntil { false }
            }
        }
    }
    
    func setupWordWare() throws {
        let wordContainerGrid = builder.createGrid()
        wordContainerGrid.removeBackground()
        wordContainerGrid.translated(dZ: -50.0)
        
        var counter = 0.0
        let (_, nodes) = wordContainerGrid.consume(text: "Hello")
        
        // Word nodes are virtual parents right now - you don't add them to the root.
        let helloNode = WordNode(glyphs: nodes, parentGrid: wordContainerGrid)
        
        QuickLooper(interval: .milliseconds(16)) {
            helloNode.translate(dX: cos(counter.float / 5.0.float))
            counter += 1.0
        }.runUntil { false }
        
//        root.bindAsVirtualParentOf(grid.rootNode)
        root.add(child: wordContainerGrid.rootNode)
    }
}
