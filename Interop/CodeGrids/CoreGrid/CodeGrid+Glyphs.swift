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
        
        init(targetGrid: CodeGrid) {
            self.targetGrid = targetGrid
        }
        
        private var currentPosition: SCNVector3 {
            targetGrid.pointer.position.translated()
        }
        
        func insert(
            _ syntaxTokenCharacter: Character,
            _ letterNode: SCNNode,
            _ size: CGSize
        ) {
            let checks = syntaxTokenCharacter.checks
            
            // add node directly to root container grid
            let nodeLengthX = size.width.vector
            let nodeLengthY = size.height.vector
            
            letterNode.position = currentPosition.translated(
                dX: nodeLengthX / 2.0,
                dY: -nodeLengthY / 2.0
            )

            if !checks.isWhitespace {
                targetGrid.rawGlyphsNode.addChildNode(letterNode)
            }
            
            // we're writing left-to-right.
            // Letter spacing is implicit to layer size.
            targetGrid.pointer.right(nodeLengthX)
            if checks.isNewline {
                newLine(size)
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

private extension Character {
    struct Check {
        let isWhitespace: Bool
        let isNewline: Bool
    }
    
    private class CheckCaches: LockingCache<Character, Check> {
        static let shared: CheckCaches = CheckCaches()
        override func make(_ key: Key, _ store: inout [Key : Value]) -> Character.Check {
            Check(
                isWhitespace: CharacterSet.whitespacesAndNewlines.containsUnicodeScalars(of: key),
                isNewline: key.isNewline
            )
        }
    }
    
    var checks: Check {
        CheckCaches.shared[self]
    }
    
    var isWhitespaceCharacter: Bool {
        CheckCaches.shared[self].isWhitespace
    }
    
    var isNewlineCharacter: Bool {
        CheckCaches.shared[self].isNewline
    }
}

extension CharacterSet {
    func containsUnicodeScalars(of character: Character) -> Bool {
        return character.unicodeScalars.allSatisfy(contains(_:))
    }
}
