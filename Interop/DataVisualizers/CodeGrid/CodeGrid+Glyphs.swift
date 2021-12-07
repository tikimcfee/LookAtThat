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
    struct GlyphPosition: Hashable, Equatable {
        let xColumn: VectorFloat
        let yRow: VectorFloat
        let zDepth: VectorFloat
        var vector: SCNVector3 { SCNVector3(xColumn, yRow, zDepth) }
        
        func transformed(dX: VectorFloat = 0,
                         dY: VectorFloat = 0,
                         dZ: VectorFloat = 0) -> GlyphPosition {
            GlyphPosition(xColumn: xColumn + dX, yRow: yRow + dY, zDepth: zDepth + dZ)
        }
    }
    
    class Pointer {
        var position: GlyphPosition = GlyphPosition(xColumn: 0, yRow: 0, zDepth: 0)
        
        func right(_ dX: VectorFloat) { position = position.transformed(dX: dX) }
        func left(_ dX: VectorFloat) { position = position.transformed(dX: -dX) }
        func up(_ dY: VectorFloat) { position = position.transformed(dY: dY) }
        func down(_ dY: VectorFloat) { position = position.transformed(dY: -dY) }
        func move(to newPosition: GlyphPosition) { position = newPosition }
    }
    
    class Renderer {
        struct Config {
            static let newLineSizeRatio: VectorFloat = 0.5
        }
        
        let targetGrid: CodeGrid
        var lineCount = 0
        private var currentPosition: GlyphPosition { targetGrid.pointer.position }
        
        init(targetGrid: CodeGrid) {
            self.targetGrid = targetGrid
        }
        
        func insert(
            _ syntaxTokenCharacter: Character,
            _ letterNode: SCNNode,
            _ size: CGSize
        ) {
            // add node directly to root container grid
            letterNode.position = currentPosition.vector
            letterNode.position = letterNode.position.translated(
                dX: letterNode.lengthX / 2.0,
                dY: -letterNode.lengthY / 2.0
            )
            targetGrid.rootGlyphsNode.addChildNode(letterNode)
            
            // we're writing left-to-right.
            // Letter spacing is implicit to layer size.
            targetGrid.pointer.right(size.width.vector)
            if syntaxTokenCharacter.isNewline {
                newLine(size)
            }
        }
        
        func newLine(_ size: CGSize) {
            targetGrid.pointer.down(size.height.vector * Config.newLineSizeRatio)
            targetGrid.pointer.left(currentPosition.xColumn)
            lineCount += 1
        }
    }
}
