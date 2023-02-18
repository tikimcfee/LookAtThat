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
//        try setupDictionaryTest()
        
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
    let sourceWord: String
    let glyphs: CodeGridNodes
    let parentGrid: CodeGrid
    
    init(
        sourceWord: String,
        glyphs: CodeGridNodes,
        parentGrid: CodeGrid
    ) {
        self.sourceWord = sourceWord
        self.glyphs = glyphs
        self.parentGrid = parentGrid
        super.init()
        
        var xOffset: Float = 0
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
    
    func update(_ action: @escaping (WordNode) async -> Void) {
        Task {
            await action(self)
            push()
        }
    }
}

struct WordDictionary: Codable {
    var words: [String: [String]]
    
    init() {
        self.words = .init()
    }
    
    init(file: URL) {
        self.words = try! JSONDecoder().decode(
            [String: [String]].self,
            from: Data(contentsOf: file, options: .alwaysMapped)
        ).reduce(into: [String: [String]]()) { result, element in
            if let first = element.value.first {
                let cleanedWords = first.splitToWords.map { word in
                    word.trimmingCharacters(
                        in: .alphanumerics.inverted
                    ).lowercased()
                }
                result[element.key] = cleanedWords
            }
        }
    }
}

struct SortedDictionary {
    let sorted: [(String, [String])]
    
    init() {
        self.sorted = .init()
    }
    
    init(dictionary: WordDictionary) {
        self.sorted = dictionary.words.sorted(by: { left, right in
            left.key < right.key
        })
    }
}

class DictionaryController: ObservableObject {
    @Published var dictionary = WordDictionary()
    @Published var sortedDictionary = SortedDictionary()
    var nodeController = GlobalNodeController()
    
//    var nodeMap = [String: WordNode]()
    var nodeMap = ConcurrentDictionary<String, WordNode>()
    var lastLinkLine: MetalLinkLine?
    var lastRootNode: MetalLinkNode? {
        didSet { nodeMap = .init() }
    }
    
    lazy var scale: Float = 30.0
    lazy var scaleVector = LFloat3(scale, scale, scale)
    lazy var scaleVectorNested = LFloat3(scale / 2.0, scale / 2.0, scale / 2.0)
    
    lazy var inverseScale: Float = pow(scale, -1)
    lazy var inverseScaleVector = LFloat3(1, 1, 1)
    
    lazy var positionVector = LFloat3(0, 0, 16)
    lazy var inversePositionVector = LFloat3(0, 0, -16)
    
    lazy var colorVector = LFloat4(0.65, 0.30, 0.0, 0.0)
    lazy var colorVectorNested = LFloat4(-0.65, 0.55, 0.55, 0.0)
    
    var focusedWordNode: WordNode? {
        willSet {
            guard newValue != focusedWordNode else { return }
            
            if let focusedWordNode {
                defocusWord(focusedWordNode, defocusNested: true)
            }
            
            if let newValue {
                focusWord(newValue, focusNested: true)
            } else {
                if let rootNode = lastRootNode {
                    if let lastLinkLine {
                        rootNode.remove(child: lastLinkLine)
                    }
                }
            }
        }
    }
    
    func focusWord(
        _ wordNode: WordNode,
        focusNested: Bool = false,
        isNested: Bool = false
    ) {
        wordNode.update { toUpdate in
            toUpdate.position.translateBy(dZ: self.positionVector.z)
            toUpdate.scale = isNested
                ? self.scaleVectorNested
                : self.scaleVector
            
            for glyph in toUpdate.glyphs {
                UpdateNode(glyph, in: toUpdate.parentGrid) {
                    $0.addedColor += self.colorVector
                    if isNested {
                        $0.addedColor += self.colorVectorNested
                    }
                }
            }
        }
        
        if !isNested {
            if let rootNode = lastRootNode {
                if let lastLinkLine {
                    rootNode.remove(child: lastLinkLine)
                }
                
                let linkLine = MetalLinkLine(GlobalInstances.defaultLink)
                linkLine.setColor(LFloat4(1.0, 0.0, 0.0, 1.0))
                rootNode.add(child: linkLine)
                lastLinkLine = linkLine
            }
        }
        
        
        let definitionNodes = dictionary.words[wordNode.sourceWord]?.compactMap { nodeMap[$0] }
        if let definitionNodes, focusNested {
            lastLinkLine?.appendSegment(about: wordNode.position)
            
            if !isNested {
                for definitionWord in definitionNodes {
                    focusWord(definitionWord, focusNested: false, isNested: true)
                    lastLinkLine?.appendSegment(about: definitionWord.position)
                }
            }
        }
    }
    
    func defocusWord(
        _ wordNode: WordNode,
        defocusNested: Bool = false,
        isNested: Bool = false
    ) {
        wordNode.update { toUpdate in
            toUpdate.position.translateBy(dZ: self.inversePositionVector.z)
            toUpdate.scale = self.inverseScaleVector
            for glyph in toUpdate.glyphs {
                UpdateNode(glyph, in: toUpdate.parentGrid) {
                    $0.addedColor -= self.colorVector
                    if isNested {
                        $0.addedColor -= self.colorVectorNested
                    }
                }
            }
        }
        
        let definitionNodes = dictionary.words[wordNode.sourceWord]?.compactMap { nodeMap[$0] }
        if let definitionNodes, defocusNested {
            for definitionWord in definitionNodes {
                defocusWord(definitionWord, defocusNested: false, isNested: true)
            }
        }
    }
    
    func start() {
        openFile { file in
            switch file {
            case .success(let url):
                self.kickoffJsonLoad(url)
                
            default:
                break
            }
        }
    }
    
    func kickoffJsonLoad(_ url: URL) {
        let dictionary = WordDictionary(file: url)
        self.dictionary = dictionary
        self.sortedDictionary = SortedDictionary(dictionary: dictionary)
    }
}

actor Positioner {
    var column: Int = 0
    var row: Int = 0
    var depth: Int = 0
    
    var sideLength: Int
    
    init(sideLength: Int) {
        self.sideLength = sideLength
    }
    
    private func nextDepth() -> Int {
        let val = depth
        return val
    }
    
    private func nextColumn() -> Int {
        let val = column
        if val >= sideLength / 4 {
            column = 0
            depth += 1
        }
        return val
    }
    
    private func nextRow() -> Int {
        let val = row
        if val >= sideLength {
            row = 0
            column += 1
        }
        row += 1
        return val
    }
    
    func nextPos() -> (Int, Int, Int) {
        (nextRow(), nextColumn(), nextDepth())
    }
}

extension TwoETimeRoot {
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
        
        let sideLength = Int(sqrt(dictionary.sorted.count.float))
        let chunkGroup = DispatchGroup()
        let positions = Positioner(sideLength: sideLength)
        
        DispatchQueue.global().async {
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
                        
                        sourceNode.update {
                            let (row, column, depth) = await positions.nextPos()
                            print(row, column, depth)
                            $0.position = LFloat3(
                                x: column.float * 24.0,
                                y: -row.float * 4.0,
                                z: -depth.float * 128.0
                            )
                        }
                    }
                    chunkGroup.leave()
                }
            }
            
//            for (word, _) in dictionary.sorted {
//                group.enter()
//
//                WorkerPool.shared.nextWorker().async {
//                    let (_, sourceGlyphs) = wordContainerGrid.consume(text: word)
//                    let sourceNode = WordNode(glyphs: sourceGlyphs, parentGrid: wordContainerGrid)
//                    controller.nodeMap[word] = sourceNode
//
//                    sourceNode.update {
//                        let (row, column) = await positions.nextPos()
//                        $0.position = LFloat3(
//                            x: column.float * 2.0,
//                            y: -row.float * 2.0,
//                            z: 0
//                        )
//                        group.leave()
//                    }
//                }
//            }
        }
        
        DispatchQueue.global().async {
            chunkGroup.wait()
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
        let helloNode = WordNode(
            sourceWord: "Hello",
            glyphs: nodes,
            parentGrid: wordContainerGrid
        )
        
        QuickLooper(interval: .milliseconds(16)) {
            helloNode.translate(dX: cos(counter.float / 5.0.float))
            counter += 1.0
        }.runUntil { false }
        
//        root.bindAsVirtualParentOf(grid.rootNode)
        root.add(child: wordContainerGrid.rootNode)
    }
}
