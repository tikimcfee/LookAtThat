//
//  WordNode.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 2/17/23.
//

import Foundation

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
    
    func update(_ action: @escaping (WordNode) async -> Void) {
        Task {
            await action(self)
            push()
        }
    }
    
    func updateSync(_ action: (WordNode) -> Void) {
        action(self)
        push()
    }
    
    func  applyGlyphChanges(
        _ receiver: @escaping (GlyphNode, inout GlyphConstants) -> Void
    ) {
        for glyph in glyphs {
            UpdateNode(glyph, in: parentGrid) { constants in
                receiver(glyph, &constants)
            }
        }
    }
    
    private var asyncApplyTask: Task<(), Never>?
    
    func  applyGlyphChangesAsync(
        _ receiver: @escaping (GlyphNode, inout GlyphConstants) -> Void
    ) {
        asyncApplyTask?.cancel()
        asyncApplyTask = Task {
            for glyph in glyphs where !Task.isCancelled {
                UpdateNode(glyph, in: parentGrid) { constants in
                    receiver(glyph, &constants)
                }
            }
        }
        
    }
    
    private func push() {
        parentGrid.pushNodes(glyphs)
    }
}
