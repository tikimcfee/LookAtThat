//
//  GlyphCollection+Pointer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/21/22.
//

import Foundation
import Metal

extension GlyphCollection {
    class Pointer {
        var position: LFloat3 = .zero
        
        func right(_ dX: Float) { position.x += dX }
        func left(_ dX: Float) { position.x -= dX }
        func up(_ dY: Float) { position.y += dY }
        func down(_ dY: Float) { position.y -= dY }
    }
    
    class Renderer {
        struct Config {
            static let newLineSizeRatio: Float = 1.10
        }
        
        let pointer = Pointer()
        let targetCollection: GlyphCollection
        var lineCount = 0
        private var currentPosition: LFloat3 { LFloat3(pointer.position) }
        
        init(collection: GlyphCollection) {
            self.targetCollection = collection
        }
        
        func insert(_ letterNode: MetalLinkGlyphNode) {
            let checks = letterNode.key.source.checks
            let size = LFloat2(letterNode.quad.width, letterNode.quad.height)
            
            letterNode.position = currentPosition.translated(dX: size.x)
            
            if !checks.isWhitespace {
                targetCollection.add(child: letterNode)
            }
            
            pointer.right(size.x)
            
            if checks.isNewline {
                newLine(size)
            }
        }
        
        func newLine(_ size: LFloat2) {
            pointer.down(size.y * Config.newLineSizeRatio)
            pointer.left(currentPosition.x)
            lineCount += 1
        }
    }
}
