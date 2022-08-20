//
//  CodeGrid+Writers.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 6/11/22.
//

import Foundation
import SceneKit
import SwiftSyntax

//MARK: -- Writers
extension CodeGrid {
    class Writer {
        let grid: CodeGrid
        var rootNode: SCNNode { grid.rootNode }
        
        init(_ grid: CodeGrid) {
            self.grid = grid
        }
        
        func attributedString(_ string: String, _ color: NSUIColor) -> NSAttributedString {
            NSAttributedString(string: string, attributes: [
                .foregroundColor: color.cgColor,
                .font: FontRenderer.shared.font
            ])
        }
        
        func finalize() {
//            // Only erase if you've added; it's a full and expensive node walk
//            grid.renderer.eraseWhitespace()
            grid.flattenRootGlyphNode()
        }
    }
    
    class RawGlyphs: Writer {
        func writeGlyphs(_ text: String) {
            writeString(text, .white)
        }
        
        private func writeString(_ string: String, _ color: NSUIColor) {
            for newCharacter in string {
                let glyphNode = grid.createNodeFor(newCharacter, color)
                glyphNode.name = String(newCharacter)
                grid.renderer.insert(newCharacter, glyphNode, glyphNode.size)
            }
        }
    }
    
    class AttributedGlyphs: Writer {
        func writeString(
            _ string: String,
            _ name: String,
            _ color: NSUIColor,
            _ set: inout CodeGridNodes
        ) {
            for newCharacter in string {
                let glyphNode = grid.createNodeFor(newCharacter, color)
                glyphNode.name = name
                if !newCharacter.isWhitespace {
                    set.insert(glyphNode)
                }
                grid.renderer.insert(newCharacter, glyphNode, glyphNode.size)
            }
        }
    }
}

// MARK: -- Node creation

extension CodeGrid {
    private func createNodeFor(
        _ syntaxTokenCharacter: Character,
        _ color: NSUIColor
    ) -> GlyphNode {
        laztrace(#fileID,#function,syntaxTokenCharacter,color)
        let key = GlyphCacheKey("\(syntaxTokenCharacter)", color)
        let (rootLayer, focusLayer, size) = glyphCache[key]
        let letterNode = GlyphNode.make(rootLayer, focusLayer, size)
        letterNode.categoryBitMask = HitTestType.codeGridToken.rawValue
        return letterNode
    }
}
