//
//  DictionaryController.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 2/17/23.
//

import Foundation

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
        
//        if !isNested {
//            if let rootNode = lastRootNode {
//                if let lastLinkLine {
//                    rootNode.remove(child: lastLinkLine)
//                }
//                
//                let linkLine = MetalLinkLine(GlobalInstances.defaultLink)
//                linkLine.setColor(LFloat4(1.0, 0.0, 0.0, 1.0))
//                rootNode.add(child: linkLine)
//                lastLinkLine = linkLine
//            }
//        }
        
        
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
