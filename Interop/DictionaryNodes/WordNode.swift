//
//  WordNode.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 2/17/23.
//

import Foundation
import MetalLink
import MetalLinkHeaders
import SwiftNodes

class WordNode: MetalLinkNode {
    let sourceWord: String
    let glyphs: CodeGridNodes
    let parentGrid: CodeGrid
    
    public lazy var contentSizeCache = CachedValue(update: {
        let b = BoxComputing()
        b.consumeNodeSizes(self.glyphs)
        return BoundsSize(b.bounds) * self.scale
    })
    
    override var hasIntrinsicSize: Bool { true }
    override var contentSize: LFloat3 { contentSizeCache.get() }
    
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
            glyph.instanceConstants?.useParentMatrix = .zero
            glyph.parent = self
            glyph.position = LFloat3(x: xOffset, y: 0, z: 0)
            xOffset += glyph.boundsWidth
        }
    }
    
    override func rebuildTreeState() {
        rebuildNow()
    }
    
    override func rebuildNow() {
        contentSizeCache.updateNow()
        super.rebuildNow()
    }
    
    override func enumerateChildren(_ action: (MetalLinkNode) -> Void) {
        for glyph in glyphs {
            action(glyph)
        }
    }
}


extension WordNode {
    func hideNode() {
        
        
    }
    
    func showNode() {
        
    }
}
