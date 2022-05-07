//
//  GlyphNode.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 5/5/22.
//

import Foundation
import SceneKit
import SwiftSyntax

class GlyphNode: SCNNode {
    var rootGeometry: SCNGeometry!
    var focusGeometry: SCNGeometry!
    var size: CGSize!
    var focusCount = 0
    
    static func make(
        _ root: SCNGeometry,
        _ focus: SCNGeometry,
        _ size: CGSize
    ) -> GlyphNode {
        let node = GlyphNode()
        node.rootGeometry = root
        node.focusGeometry = focus
        node.size = size
        node.geometry = root
        return node
    }
    
    func focus(level: Int) {
        position = position.translated(dZ: 8.0 * VectorVal((level - focusCount)))
        focusCount = level
        checkCount()
    }
    
    func focus() {
        position = position.translated(dZ: 8)
        focusCount += 1
        checkCount()
    }
    
    func unfocus() {
        position = position.translated(dZ: -8)
        focusCount = max(0, focusCount - 1)
        checkCount()
    }
    
    func checkCount() {
        if focusCount == 0 {
            geometry = rootGeometry
        } else {
            geometry = focusGeometry
        }
    }
}
