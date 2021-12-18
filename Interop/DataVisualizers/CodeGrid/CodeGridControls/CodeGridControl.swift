//
//  CodeGridControl.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/16/21.
//

import Foundation
import SceneKit
import SwiftUI

class CodeGridControl {
    typealias AlignReceiver = (CodeGridControl) -> SCNMatrix4
    var onAlign: AlignReceiver?
    
    typealias ControlReceiver = (CodeGridControl) -> Void
    var didActivate: ControlReceiver?
    
    struct Settings {
        let name: String
        let action: ControlReceiver
    }
    
    let targetGrid: CodeGrid
    let displayGrid: CodeGrid
    
    init(targetGrid: CodeGrid) {
        self.targetGrid = targetGrid
        self.displayGrid = targetGrid.newGridUsingCaches()
    }
    
    @discardableResult
    func setup(_ settings: CodeGridControl.Settings) -> Self {
        displayGrid.applying {
            $0.displayMode = .glyphs
            $0.fullTextBlitter.rootNode.removeFromParentNode()
            $0.fullTextBlitter.backgroundGeometryNode.removeFromParentNode()
            $0.backgroundGeometryNode.categoryBitMask = HitTestType.codeGridControl.rawValue
        }
        
        displayGrid
            .consume(text: settings.name)
            .sizeGridToContainerNode(pad: 4.0)
            .backgroundColor(NSUIColor(displayP3Red: 0.2, green: 0.4, blue: 0.5, alpha: 0.8))
            .applying { _ = SCNNode.BoundsCaching.Update($0.rootNode, false) }
        
//        displayGrid.rootNode.addConstraint(
//            SCNTransformConstraint(inWorldSpace: false, with: onConstraintLayout)
//        )

        didActivate = settings.action
        
        return self
    }
    
    @discardableResult
    func applying(_ settings: ControlReceiver) -> Self {
        settings(self)
        return self
    }
    
    func onConstraintLayout(_ node: SCNNode, _ transform: SCNMatrix4) -> SCNMatrix4 {
        guard let onAlign = onAlign else {
            return transform
        }
        
        let final = onAlign(self)
        
        return final
    }
}
