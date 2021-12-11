import Foundation
import SwiftUI
import SceneKit

let WORD_FONT_POINT_SIZE = CGFloat(1)
let WORD_CHARACTER_SPACING = CGFloat(0.0)
let WORD_EXTRUSION_SIZE = CGFloat(0.5)
let PAGE_EXTRUSION_DEPTH = CGFloat(0.75)
let POINTS_BETWEEN_WORDS = CGFloat(1)
let LINE_MARGIN_HEIGHT = CGFloat(1.5)

public typealias SizedText = (SCNGeometry, CGSize)

enum BuildMode {
    case words
    case characters
    case layers
}

class WordNodeBuilder {
    private var TEXT_NODE_COUNT = 0
    
    let wordColorMap = WordColorCache()

    let wordCharacterCache = WordGeometryCache()
    let wordStringCache = WordStringCache()
    let wordLayerCache = WordLayerCache()
    let glyphLayerCache = GlyphLayerCache()

    let buildMode = BuildMode.layers

    func definitionNode(_ rootWordPosition: SCNVector3,
                        _ rootWord: String,
                        _ definitionText: String) -> SCNNode {
        let rootWordNode = node(for: rootWord)

        let rootContainerNode = SCNNode()
        rootContainerNode.position = rootWordPosition
        rootContainerNode.addChildNode(rootWordNode)

        var definitionWordPosition = SCNVector3(x: 0, y: -rootWordNode.boundingBox.max.y, z: 0)
        var lastNode = rootWordNode

        definitionText
            .splitToWordsAndSpaces
            .map{ node(for: $0) }
            .forEach{ definitionWordNode in
                definitionWordNode.position = definitionWordPosition
                rootContainerNode.addChildNode(definitionWordNode)
                
                let dX = lastNode.lengthX / 2 + definitionWordNode.lengthX / 2
                definitionWordNode.position = lastNode.position.translated(dX: dX, dY: 0, dZ: 0)
//                definitionWordNode.chainLinkTo(to: lastNode)
                
                lastNode = definitionWordNode
                definitionWordPosition.x += lastNode.boundingBox.max.x + POINTS_BETWEEN_WORDS.vector
            }
        return rootContainerNode
    }

    func node(for word: String) -> SCNNode {
        let containerNode = makeTextNode(word)
        let allText: [SizedText]
        switch buildMode {
        case .characters:
            allText = makeDecomposedGeometry(word)
        case .words:
            allText = makeFullStringTextGeometry(word)
        case .layers:
            allText = makeLayerTextGeometry(.init(word: word, foreground: .white))
        }
        map(text: allText, onto: containerNode)
        return containerNode
    }
    
    func colorizedNode(with key: LayerCacheKey) -> SCNNode {
        let containerNode = makeTextNode(key.word)
        let allText = makeLayerTextGeometry(key)
        map(text: allText, onto: containerNode)
        return containerNode
    }
    
    private func map(text sizedText: [SizedText], onto containerNode: SCNNode) {
        var lastPosition = SCNVector3Zero
        var maxHeight = CGFloat(0)
        
        sizedText.forEach { sizedText in
            let letterNode = SCNNode()
            containerNode.addChildNode(letterNode)
            letterNode.position = lastPosition
            letterNode.geometry = sizedText.0
            lastPosition.x += sizedText.1.width.vector + WORD_CHARACTER_SPACING.vector
            maxHeight = max(sizedText.1.height, maxHeight)
        }
        
        containerNode.boundingBox = (
            SCNVector3Zero,
            SCNVector3(x: lastPosition.x.vector,
                       y: maxHeight.vector,
                       z: WORD_EXTRUSION_SIZE.vector)
        )
    }

    private func makeTextNode(_ word: String) -> SCNNode {
        let wordNode = SCNNode()
        wordNode.name = UUID().uuidString
        TEXT_NODE_COUNT += 1
        return wordNode
    }

    private func makeLayerTextGeometry(_ key: LayerCacheKey) -> [SizedText] {
        let wordText = wordLayerCache[key]
        return [wordText]
    }

    private func makeFullStringTextGeometry(_ word: String) -> [SizedText] {
        let wordText = wordStringCache[word]
        return [wordText]
    }

    private func makeDecomposedGeometry(_ word: String) -> [SizedText] {
        let geometry = word.map{ wordCharacterCache[$0] }
        return geometry
    }
}

extension WordNodeBuilder {
    func arrange(_ nodes: [SCNNode], on node: SCNNode) {
        var lastNode: SCNNode? = node.childNodes.last

        switch buildMode {
        case .characters, .words:
            nodes.forEach { wordNode in
                let lastWordPosition: SCNVector3
                if let lastNode = lastNode {
                    let dX = lastNode.lengthX
                    lastWordPosition = lastNode.position.translated(dX: dX)
                } else {
                    let dY = -wordNode.lengthY
                    lastWordPosition = SCNVector3Zero.translated(dY: dY)
                }
                wordNode.position = lastWordPosition
                node.addChildNode(wordNode)
                lastNode = wordNode
            }
        case .layers:
            nodes.forEach { wordNode in
                let lastWordPosition: SCNVector3
                if let lastNode = lastNode {
                    let dX = lastNode.lengthX / 2.0 + wordNode.lengthX / 2.0
                    lastWordPosition = lastNode.position.translated(dX: dX)
                } else {
                    let dX = wordNode.lengthX / 2.0
                    let dY = -wordNode.lengthY / 2.0
                    lastWordPosition = SCNVector3Zero.translated(dX: dX, dY: dY)
                }
                wordNode.position = lastWordPosition
                node.addChildNode(wordNode)
                lastNode = wordNode
            }
        }
    }
}

let kDefaultSCNTextFont = NSUIFont.monospacedSystemFont(ofSize: WORD_FONT_POINT_SIZE, weight: .regular)

extension String {
    var fontedSize: CGSize {
        return self.size(withAttributes: [.font: kDefaultSCNTextFont])
    }
}


// Maybe use something like the below to precache character nodes
//extension CharacterSet {
//    func characters() -> [Character] {
//        // A Unicode scalar is any Unicode code point in the range
//        // U+0000 to U+D7FF inclusive or
//        // U+E000 to U+10FFFF inclusive.
//        return codePoints()
//            .compactMap { UnicodeScalar($0) }
//            .map { Character($0) }
//    }
//
//    // following documentation at https://developer.apple.com/documentation/foundation/nscharacterset/1417719-bitmaprepresentation
//    func codePoints() -> [Int] {
//        var result: [Int] = []
//        var plane = 0
//        for (i, w) in bitmapRepresentation.enumerated() {
//            let k = i % 0x2001
//            if k == 0x2000 {
//                // plane index byte
//                plane = Int(w) << 13
//                continue
//            }
//            let base = (plane + k) << 3
//            for j in 0 ..< 8 where w & 1 << j != 0 {
//                result.append(base + j)
//            }
//        }
//        return result
//    }
//}
