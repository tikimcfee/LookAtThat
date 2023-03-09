//
//  CodeGrid+Writing.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/12/21.
//

import Foundation
import SceneKit
import SwiftSyntax

class ColorGenerator {
    /// With eternal thanks as always to the language model entity that listened and assisted.
    struct ColorIterator_ai: Sequence, IteratorProtocol {
        let numColors: Int
        let saturation: Float
        let brightness: Float
        var currentIndex: Int = 0
        
        init(numColors: Int, saturation: Float = 1.0, brightness: Float = 0.9) {
            self.numColors = numColors
            self.saturation = saturation
            self.brightness = brightness
        }
        
        mutating func next() -> LFloat4? {
            guard currentIndex < numColors,
                  let colorVector = currentSystemColorVector
            else { return nil }
            currentIndex += 1
            return colorVector
        }
        
        private var currentSystemColorVector: LFloat4? {
            guard let systemColor = currentSystemColor,
                  let systemRGBA = systemColor.rgba
            else { return nil }
            return LFloat4(
                systemRGBA.red.float,
                systemRGBA.green.float,
                systemRGBA.blue.float,
                1.0
            )
        }
        
        private var currentSystemColor: NSUIColor? {
            let hue = currentIndex.cg / numColors.cg
//            let hue = CGFloat(currentIndex) / CGFloat(numColors)
//            let hueRange = hue < 1.0 ? 0.0..<1.0 : 0.0..<hue.truncatingRemainder(dividingBy: 1.0)
//            let hueValue = hueRange.lowerBound + (hueRange.upperBound - hueRange.lowerBound) * hue
            return NSUIColor(
                hue: hue,
                saturation: saturation.cg,
                brightness: brightness.cg,
                alpha: 1.0
            )
        }
    }
    
    private let maxColorCount: Int
    
    private lazy var colorIterator = ColorIterator_ai(numColors: maxColorCount)
    private lazy var sortedColors = Array(colorIterator)
    
    init(maxColorCount: Int) {
        self.maxColorCount = max(1, maxColorCount)
    }
    
    var nextColor: LFloat4 {
        sortedColors.popLast() ?? LFloat4(repeating: 1.0)
    }
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
