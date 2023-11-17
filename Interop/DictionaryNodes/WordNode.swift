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
    var glyphs: CodeGridNodes
    let parentGrid: CodeGrid

    override var hasIntrinsicSize: Bool {
        true
    }
    
    override var contentBounds: Bounds {
        let b = BoxComputing()
        for node in glyphs {
            b.consumeBounds(
                node.sizeBounds
            )
        }
        return b.bounds * scale
    }
    
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
    
    override var children: [MetalLinkNode] {
        get { glyphs }
        set { glyphs = newValue as? [MetalLinkGlyphNode] ?? glyphs }
    }
    
    override func render(in sdp: inout SafeDrawPass) {
        // Don't render me
    }
}


extension WordNode {
    func hideNode() {
        
        
    }
    
    func showNode() {
        
    }
}
