import Foundation
import SwiftUI
import SceneKit

let WORD_FONT_POINT_SIZE = CGFloat(3)
let WORD_CHARACTER_SPACING = CGFloat(0.0)
let WORD_EXTRUSION_SIZE = CGFloat(0.5)
let PAGE_EXTRUSION_DEPTH = CGFloat(0.75)
let POINTS_BETWEEN_WORDS = CGFloat(1)
let LINE_MARGIN_HEIGHT = CGFloat(1.5)

public typealias SizedText = (SCNGeometry, CGSize)

class WordNodeBuilder {
    let wordColorMap = WordColorCache()
    let wordGeometryCache = WordGeometryCache()

    func definitionNode(_ rootWordPosition: SCNVector3,
                        _ rootWord: String,
                        _ definitionText: String) -> SCNNode {
        let rootWordNode = node(for: rootWord)

        let rootContainerNode = SCNNode()
        rootContainerNode.position = rootWordPosition
        rootContainerNode.addChildNode(rootWordNode)

        var definitionWordPosition = SCNVector3(x: 0, y: -rootContainerNode.boundingBox.max.y, z: 0)
        var lastNode = rootWordNode

        definitionText
            .splitToWordsAndSpaces
            .map{ node(for: $0) }
            .forEach{ definitionWordNode in
                definitionWordNode.position = definitionWordPosition
                rootContainerNode.addChildNode(definitionWordNode)
                definitionWordNode.chainLinkTo(to: lastNode)
                lastNode = definitionWordNode
                definitionWordPosition.x += lastNode.boundingBox.max.x + POINTS_BETWEEN_WORDS
            }
        return rootContainerNode
    }

    func node(for word: String) -> SCNNode {
        let containerNode = makeTextNode(word)
        var lastPosition = SCNVector3(x: 0, y: 0, z: 0)
        var maxHeight = CGFloat(0)
        makeDecomposedGeometry(word).forEach{ sizedText in
            let letterNode = SCNNode()
            containerNode.addChildNode(letterNode)
            letterNode.position = lastPosition
            letterNode.geometry = sizedText.0
            lastPosition.x += sizedText.1.width + WORD_CHARACTER_SPACING
            maxHeight = max(sizedText.1.height, maxHeight)
        }
        containerNode.boundingBox = (
            SCNVector3(),
            SCNVector3(x: lastPosition.x, y: maxHeight, z: WORD_EXTRUSION_SIZE)
        )
        return containerNode
    }

    var TEXT_NODE_COUNT = 0
    private func makeTextNode(_ word: String) -> SCNNode {
        let wordNode = SCNNode()
        wordNode.name = word.appending("[>]\(TEXT_NODE_COUNT)")
        TEXT_NODE_COUNT += 1
        return wordNode
    }

    private func makeFullStringTextGeometry(_ word: String) -> SCNGeometry {
        let wordText = SCNText(string: word, extrusionDepth: WORD_EXTRUSION_SIZE)
        wordText.font = NSUIFont.systemFont(ofSize: WORD_FONT_POINT_SIZE)
        wordText.firstMaterial?.diffuse.contents = wordColorMap[word]
        return wordText
    }

    private func makeDecomposedGeometry(_ word: String) -> [SizedText] {
        let geometry = word.map{ wordGeometryCache[$0] }
        return geometry
    }
}

//let kDefaultSCNTextFont = NSUIFont.systemFont(ofSize: WORD_FONT_POINT_SIZE)
let kDefaultSCNTextFont = NSFont.monospacedSystemFont(ofSize: WORD_FONT_POINT_SIZE, weight: .regular)

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
