//
//  DictionaryController.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 2/17/23.
//

import Foundation
import MetalLink
import BitHandling

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
    
    lazy var rootNodePositionTranslation = LFloat3(0, 0, 16)
    lazy var inversePositionVector = LFloat3(0, 0, -16)
    
    lazy var colorVector = LFloat4(0.65, 0.30, 0.0, 0.0)
    lazy var colorVectorNested = LFloat4(-0.65, 0.55, 0.55, 0.0)
    
    lazy var focusedColor =    LFloat4(1.0, 0.0, 0.0, 0.0)
    lazy var ancestorColor =   LFloat4(0.0, 1.0, 0.0, 0.0)
    lazy var descendantColor = LFloat4(0.0, 0.0, 1.0, 0.0)
    
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
    
    class Styler {
        enum Style {
            case rootWord
            case definitionDescendant(depth: Double)
        }
        
        lazy var rootNodeColor = LFloat4(1.0, 0.0, 0.0, 0.0)
        lazy var rootNodeScale = LFloat3(30.0, 30.0, 30.0)
        lazy var rootNodeTranslation = LFloat3(0, 0, 16)
        
        lazy var colors = ColorGenerator(maxColorCount: 500)
        lazy var depths: [WordNode: LFloat3] = [:]
        
        func focusWord(
            _ wordNode: WordNode,
            _ style: Style
        ) {
            switch style {
            case .rootWord:
                rootWord = wordNode
                
            case .definitionDescendant(let depth):
                break
            }
        }
        
        var rootWord: WordNode? {
            willSet {
                guard rootWord != newValue else { return }
                
                rootWord?.position -= rootNodeTranslation
                rootWord?.scale = .one
                newValue?.position += rootNodeTranslation
                newValue?.scale = .one
            }
        }
        
        func updateDepth(of word: WordNode, to depth: Float) {
            let lastUpdate = depths[word, default: .zero]
            guard lastUpdate.z != depth else { return }
            
            word.position -= lastUpdate
            word.position += LFloat3(0.0, 0.0, depth)
        }
    }
    
    func focusWord(
        _ wordNode: WordNode,
        focusNested: Bool = false,
        isNested: Bool = false
    ) {
        wordNode.update { toUpdate in
            toUpdate.position
                .translateBy(dZ: self.rootNodePositionTranslation.z)
            
            toUpdate.scale = isNested
                ? self.scaleVectorNested
                : self.scaleVector
            
            toUpdate.applyGlyphChanges { glyph, constants in
                constants.addedColor = self.focusedColor
            }
        }
        
        if let graphNode = dictionary.graph.node(with: wordNode.sourceWord) {
//            for ancestor in graphNode.ancestorIDs {
//                if let ancestorNode = nodeMap[ancestor] {
//                    ancestorNode.update {
//                        $0.scale = self.scaleVectorNested
//                        for glyph in ancestorNode.glyphs {
//                            UpdateNode(glyph, in: ancestorNode.parentGrid) {
//                                $0.addedColor = self.ancestorColor
//                            }
//                        }
//                    }
//                }
//            }
            
            for descendant in graphNode.descendantIDs {
                if descendant == wordNode.sourceWord { continue }
                
                if let descendantNode = nodeMap[descendant] {
                    descendantNode.update {
                        $0.scale = self.scaleVectorNested
                        for glyph in descendantNode.glyphs {
                            UpdateNode(glyph, in: descendantNode.parentGrid) {
                                $0.addedColor = self.descendantColor
                            }
                        }
                    }
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
                    $0.addedColor = .zero
                }
            }
        }
        
        if let graphNode = dictionary.graph.node(with: wordNode.sourceWord) {
//            for ancestor in graphNode.ancestorIDs {
//                if let ancestorNode = nodeMap[ancestor] {
//                    ancestorNode.update {
//                        $0.scale = .one
//                        for glyph in ancestorNode.glyphs {
//                            UpdateNode(glyph, in: ancestorNode.parentGrid) {
//                                $0.addedColor = .zero
//                            }
//                        }
//                    }
//                }
//            }
            
            for descendant in graphNode.descendantIDs {
                if descendant == wordNode.sourceWord { continue }
                
                if let descendantNode = nodeMap[descendant] {
                    descendantNode.update {
                        $0.scale = .one
                        for glyph in descendantNode.glyphs {
                            UpdateNode(glyph, in: descendantNode.parentGrid) {
                                $0.addedColor = .zero
                            }
                        }
                    }
                }
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
        if url.pathExtension == "wordnik" {
            let parsedDictionary = WordnikGameDictionary(from: url)
            let dictionary = WordDictionary(
                words: parsedDictionary.map
            )
            self.dictionary = dictionary
        } else {
            let dictionary = WordDictionary(file: url)
            self.dictionary = dictionary
        }
        self.sortedDictionary = SortedDictionary(dictionary: dictionary)
    }
}
