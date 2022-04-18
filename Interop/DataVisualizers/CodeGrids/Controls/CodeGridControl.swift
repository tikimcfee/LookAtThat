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
    
    init(targetGrid: CodeGrid, parser: CodeGridParser) {
        self.targetGrid = targetGrid
        self.displayGrid = parser.createNewGrid()
    }
    
    func activate() {
        didActivate?(self)
    }
    
    @discardableResult
    func setup(_ settings: Settings) -> Self {
        displayGrid.applying {
            $0.displayMode = .glyphs
            $0.backgroundGeometryNode.categoryBitMask = HitTestType.codeGridControl.rawValue
        }
        
        displayGrid
            .consume(text: settings.name)
            .sizeGridToContainerNode(pad: 2.0)
            .backgroundColor(NSUIColor(displayP3Red: 0.2, green: 0.4, blue: 0.5, alpha: 0.8))

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
    
    func setPositionConstraint(
        target: SCNNode,
        positionOffset: SCNVector3
    ) {
//        let positionConstraint = SCNReplicatorConstraint(target: target)
//        positionConstraint.replicatesOrientation = true
//        positionConstraint.replicatesPosition = true
//        positionConstraint.replicatesScale = true
//        positionConstraint.positionOffset = positionOffset
//        displayGrid.rootNode.addConstraint(positionConstraint)
        
        let transformConstraint = SCNTransformConstraint(inWorldSpace: false) { node, _ in
            node.transform = target.transform
            node.translate(dX: positionOffset.x, dY: positionOffset.y, dZ: positionOffset.z)
            return node.transform
        }
        displayGrid.rootNode.addConstraint(transformConstraint)
        
    }
}
