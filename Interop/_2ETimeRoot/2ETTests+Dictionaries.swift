//
//  2ETTests+Dictionaries.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/11/23.
//

import Combine
import MetalKit
import SwiftUI
import SwiftParser
import MetalLink
import BitHandling
import Algorithms

extension TwoETimeRoot {
    func setupDictionaryTest2(_ controller: DictionaryController) {
        if let node = controller.lastRootNode {
            root.remove(child: node)
        }
        
        let wordContainerGrid = builder.createGrid(
            bufferSize: 15_500_000
        )
        wordContainerGrid.removeBackground()
        wordContainerGrid.translated(dZ: -100.0)
        controller.lastRootNode = wordContainerGrid.rootNode
        
        let orderedWords = controller.dictionary.orderedWords
        print("Defined words: \(orderedWords.count)")
        
        let cachingGenerator = ColorGenerator(maxColorCount: orderedWords.count * 10)
        let colorFloats = ConcurrentDictionary<String, LFloat4>()
        let snap = WorldGridSnapping()
        
        for (sourceWord, definitionList) in orderedWords {
            let color = colorFloats[sourceWord] ?? cachingGenerator.nextColor
            colorFloats[sourceWord] = color
            
            let (_, sourceGlyphs) = wordContainerGrid.consume(text: sourceWord)
            let sourceNode = WordNode(
                sourceWord: sourceWord,
                glyphs: sourceGlyphs,
                parentGrid: wordContainerGrid
            )
            controller.nodeMap[sourceWord] = sourceNode
            
            for definition in definitionList {
                for definitionWord in definition {
                    let (_, definitionGlyphs) = wordContainerGrid.consume(text: definitionWord)
                    let definitionNode = WordNode(
                        sourceWord: definitionWord,
                        glyphs: definitionGlyphs,
                        parentGrid: wordContainerGrid
                    )
                    
                }
            }
            
            sourceNode.applyGlyphChanges { _, constants in
                constants.addedColor = color
            }
        }
    }
    
    func setupDictionaryTest(_ controller: DictionaryController) {
        if let node = controller.lastRootNode {
            root.remove(child: node)
        }
        
        let wordContainerGrid = builder.createGrid(
            bufferSize: 15_500_000
        )
        wordContainerGrid.removeBackground()
        wordContainerGrid.translated(dZ: -100.0)
        controller.lastRootNode = wordContainerGrid.rootNode
        
        let dictionary = controller.sortedDictionary
        print("Defined words: \(dictionary.sorted.count)")
        
//        let sideLength = Int(sqrt(dictionary.sorted.count.float))
        let sideLength = 400
        let chunkGroup = DispatchGroup()
//        let positions = Positioner(sideLength: sideLength)
        let positions = PositionerSync(sideLength: sideLength)
        let cachingGenerator = ColorGenerator(maxColorCount: dictionary.sorted.count)
        let colorFloats = ConcurrentDictionary<String, LFloat4>()
        
        func doWordColoring() {
            chunkGroup.enter()
            WorkerPool.shared.nextWorker().async {
                var generatedColors = [LFloat4: Int]()
                for (word, _) in dictionary.sorted {
                    let color = cachingGenerator.nextColor
                    generatedColors[color, default: 0] += 1
                    colorFloats[word] = color
                }
                chunkGroup.leave()
            }
            chunkGroup.wait()
        }
        
        func doWordChunking() {
            for chunk in dictionary.sorted.chunks(ofCount: 10_000) {
                chunkGroup.enter()
                WorkerPool.shared.nextWorker().async {
                    for (word, _) in chunk {
                        
                        let (_, sourceGlyphs) = wordContainerGrid.consume(text: word)
                        
                        let sourceNode = WordNode(
                            sourceWord: word,
                            glyphs: sourceGlyphs,
                            parentGrid: wordContainerGrid
                        )
                        controller.nodeMap[word] = sourceNode
                        
                        let color = colorFloats[word] ?? .zero
                        sourceNode.applyGlyphChanges { _, constants in
                            constants.addedColor = color
                        }
                    }
                    chunkGroup.leave()
                }
            }
            chunkGroup.wait()
        }
        
        func doWordPositioning() {
            chunkGroup.enter()
            WorkerPool.shared.nextWorker().async {
                for (word, _) in controller.sortedDictionary.sorted {
                    guard let node = controller.nodeMap[word] else {
                        continue
                    }
                    
                    node.updateSync {
                        let (row, column, depth) = positions.nextPos()
                        $0.position = LFloat3(
                            x: column.float * 24.0,
                            y: -row.float * 8.0,
                            z: -depth.float * 128.0
                        )
                    }
                }
                
                let graphLayout = WordGraphLayout()
                graphLayout.doIt(controller: controller)
                
                chunkGroup.leave()
            }
            chunkGroup.wait()
        }
        
        DispatchQueue.global().async {
            let watch = Stopwatch(running: true)
            
            doWordColoring()
            print("Coloring done in: \(watch.elapsedTimeString())")
            watch.restart()
            
            doWordChunking()
            print("Chunking done in: \(watch.elapsedTimeString())")
            watch.restart()
            
            doWordPositioning()
            print("Positioning done in: \(watch.elapsedTimeString())")
            watch.stop()
            
            self.root.add(child: wordContainerGrid.rootNode)
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
                let wordNode = WordNode(
                    sourceWord: word,
                    glyphs: wordGlyphs,
                    parentGrid: wordContainerGrid
                )
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
                let wordNode = WordNode(
                    sourceWord: word,
                    glyphs: wordGlyphs,
                    parentGrid: wordContainerGrid
                )
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
                        wordNode.update {
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
        let helloNode = WordNode(
            sourceWord: "Hello",
            glyphs: nodes,
            parentGrid: wordContainerGrid
        )
        
        QuickLooper(interval: .milliseconds(16)) {
            helloNode.translate(dX: cos(counter.float / 5.0.float))
            counter += 1.0
        }.runUntil { false }
        
        root.add(child: wordContainerGrid.rootNode)
    }
}
