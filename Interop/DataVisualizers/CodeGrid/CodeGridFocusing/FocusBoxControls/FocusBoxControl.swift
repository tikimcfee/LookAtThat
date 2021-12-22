//
//  FocusBoxControl.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/20/21.
//

import Foundation
import SceneKit

class FocusBoxControl {
    typealias AlignReceiver = (FocusBoxControl) -> SCNMatrix4
    var onAlign: AlignReceiver?

    typealias ControlReceiver = (FocusBoxControl) -> Void
    var didActivate: ControlReceiver?

    struct Settings {
        let name: String
        let action: ControlReceiver
    }

    let targetBox: FocusBox
    let displayGrid: CodeGrid

    init(targetBox: FocusBox, parser: CodeGridParser) {
        self.targetBox = targetBox
        self.displayGrid = parser.createNewGrid()
    }

    func activate() {
        didActivate?(self)
    }

    @discardableResult
    func setup(_ settings: Settings) -> Self {
        displayGrid.applying {
            $0.displayMode = .glyphs
            $0.fullTextBlitter.rootNode.removeFromParentNode()
            $0.fullTextBlitter.backgroundGeometryNode.removeFromParentNode()
            $0.backgroundGeometryNode.categoryBitMask = HitTestType.codeGridFocusControl.rawValue
        }

        displayGrid
            .consume(text: settings.name)
            .sizeGridToContainerNode(pad: 4.0)
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
        let positionConstraint = SCNReplicatorConstraint(target: target)
        positionConstraint.replicatesOrientation = true
        positionConstraint.replicatesPosition = true
        positionConstraint.replicatesScale = true
        positionConstraint.positionOffset = positionOffset

        displayGrid.rootNode.addConstraint(positionConstraint)
    }
}

