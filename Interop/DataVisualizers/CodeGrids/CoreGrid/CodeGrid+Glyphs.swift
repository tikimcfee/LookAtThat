//
//  CodeGrid+Glyphs.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/6/21.
//

import Foundation
import SceneKit

// MARK: -- Renderer and glyph position
extension CodeGrid {
    class Pointer {
        var position: SCNVector3 = SCNVector3()
        
        func right(_ dX: VectorFloat) { position.x += dX }
        func left(_ dX: VectorFloat) { position.x -= dX }
        func up(_ dY: VectorFloat) { position.y += dY }
        func down(_ dY: VectorFloat) { position.y -= dY }
    }
    
    class Renderer {
        struct Config {
            static let newLineSizeRatio: VectorFloat = 0.67
        }
        
        let targetGrid: CodeGrid
        var lineCount = 0
        private var currentPosition: SCNVector3 { targetGrid.pointer.position.translated() }
        
        init(targetGrid: CodeGrid) {
            self.targetGrid = targetGrid
        }
        
        func insert(
            _ syntaxTokenCharacter: Character,
            _ letterNode: SCNNode,
            _ size: CGSize
        ) {
            // add node directly to root container grid
            let nodeLengthX = size.width.vector
            let nodeLengthY = size.height.vector
            
            letterNode.position = currentPosition
            letterNode.position = letterNode.position.translated(
                dX: nodeLengthX / 2.0,
                dY: -nodeLengthY / 2.0
            )
            targetGrid.rawGlyphsNode.addChildNode(letterNode)
            
            // we're writing left-to-right.
            // Letter spacing is implicit to layer size.
            targetGrid.pointer.right(nodeLengthX)
            if syntaxTokenCharacter.isNewline {
                newLine(size)
            }
            
            if syntaxTokenCharacter.isWhitespace {
                letterNode.name?.append("-\(kWhitespaceNodeName)")
            }
        }
        
        func newLine(_ size: CGSize) {
            targetGrid.pointer.down(size.height.vector * Config.newLineSizeRatio)
            targetGrid.pointer.left(currentPosition.x)
            lineCount += 1
        }
        
        func eraseWhitespace() {
            targetGrid.rawGlyphsNode.enumerateHierarchy { node, _ in
                guard node.name?.hasSuffix(kWhitespaceNodeName) == true else { return }
                node.removeFromParentNode()
            }
        }
    }
}

extension Character {
    var isWhitespace: Bool {
        CharacterSet.whitespacesAndNewlines.containsUnicodeScalars(of: self)
    }
}

extension CharacterSet {
    func containsUnicodeScalars(of character: Character) -> Bool {
        return character.unicodeScalars.allSatisfy(contains(_:))
    }
}