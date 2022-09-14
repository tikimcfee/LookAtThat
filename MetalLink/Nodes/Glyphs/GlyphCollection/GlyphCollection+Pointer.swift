//
//  GlyphCollection+Pointer.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/21/22.
//

import Metal
import simd

extension GlyphCollection {
    class Pointer {
        var position: LFloat3 = .zero
        
        func right(_ dX: Float) { position.x += dX }
        func left(_ dX: Float) { position.x -= dX }
        func up(_ dY: Float) { position.y += dY }
        func down(_ dY: Float) { position.y -= dY }
        func away(_ dZ: Float) { position.z -= dZ }
        func toward(_ dZ: Float) { position.z += dZ }
        
        func reset() { position = .zero }
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
        
        func insert(
            _ letterNode: MetalLinkGlyphNode,
            _ constants: inout InstancedConstants
        ) {
            let checks = letterNode.key.source.checks
            let size = LFloat2(
                letterNode.quad.width,
                letterNode.quad.height
            )
            
            letterNode.position = currentPosition
            constants.modelMatrix = matrix_multiply(targetCollection.modelMatrix, letterNode.modelMatrix)
            pointer.right(size.x)
            
            if checks.isNewline {
                newLine(size)
            }
        }
        
        func newLine(_ size: LFloat2) {
//            pointer.down(size.y * Config.newLineSizeRatio)
            pointer.down(size.y)
            pointer.left(currentPosition.x)
            lineCount += 1
        }
    }
}
