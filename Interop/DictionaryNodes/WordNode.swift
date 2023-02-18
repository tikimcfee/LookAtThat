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
