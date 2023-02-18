//
//  CodeGrid+Writing.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/12/21.
//

import Foundation
import SceneKit
import SwiftSyntax

class ColorGenerator{
    private let maxColorCount: Int
    
    private let startHexcolor: Int = 0xFF_FF_FF
    private let redMask: Int       = 0xFF
    private let greenMask: Int     = 0xFF
    private let blueMask: Int      = 0xFF
    
    private lazy var currentHexColor: Int = startHexcolor
    private lazy var hexDeltaStep: Int = 0xFF_FF_FF / maxColorCount
    
    init(maxColorCount: Int) {
        self.maxColorCount = max(1, maxColorCount)
    }
    
//    func fromInt(colorInt: Int) -> NSUIColor {
//        NSUIColor(
//            displayP3Red: (colorInt >> 16 & redMask).cg   / 255.0,
//            green:        (colorInt >>  8 & greenMask).cg / 255.0,
//            blue:         (colorInt >>  0 & blueMask).cg  / 255.0,
//            alpha:        1.0
//        )
//    }
    
    func fromInt(colorInt: Int) -> LFloat4 {
        LFloat4(
            (colorInt >> 16 & redMask).float   / 255.0,
            (colorInt >>  8 & greenMask).float / 255.0,
            (colorInt >>  0 & blueMask).float  / 255.0,
            1.0
        )
    }
    
    func nextHexColor() -> Int {
        let next = currentHexColor
        currentHexColor -= hexDeltaStep
//        print(currentHexColor)
        if currentHexColor <= 0 {
            currentHexColor = startHexcolor
//            print("-----reset!!")
        }
        return next
    }
    
//    func nextColor() -> NSUIColor {
//        let nextColor = nextHexColor()
//        let mappedColor = NSUIColor(
//            displayP3Red: (nextColor >> 24 & redMask).cg   / 255.0,
//            green:        (nextColor >> 16 & greenMask).cg / 255.0,
//            blue:         (nextColor >> 8  & blueMask).cg  / 255.0,
//            alpha:        1.0
//        )
//        return mappedColor
//    }
}

// MARK: -- Consume Text
extension CodeGrid {
    // If you call this, you basically draw text like a typewriter from wherevery you last were.
    // it adds caches layer glyphs motivated by display requirements inherited by those clients.
    @discardableResult
    func consume(
        text: String,
        color: NSUIColor = .white
    ) -> (CodeGrid, CodeGridNodes) {
        var nodes = CodeGridNodes()
        GlyphCollectionSyntaxConsumer(
            targetGrid: self
        ).write(
            text,
            "raw-text-\(UUID().uuidString)",
            color,
            &nodes
        )
        rootNode.setRootMesh()
        return (self, nodes)
    }
}

//MARK: -- Consume Syntax
extension CodeGrid {
    @discardableResult
    func consume(rootSyntaxNode: Syntax) -> CodeGrid {
        doSyntaxConsume(rootSyntaxNode: rootSyntaxNode)
        return self
    }
    
    @discardableResult
    private func doSyntaxConsume(rootSyntaxNode: Syntax) -> CodeGrid {
        let consumer = GlyphCollectionSyntaxConsumer(targetGrid: self)
        consumer.consume(rootSyntaxNode: rootSyntaxNode)
        consumedRootSyntaxNodes.append(rootSyntaxNode)
        return self
    }
}
