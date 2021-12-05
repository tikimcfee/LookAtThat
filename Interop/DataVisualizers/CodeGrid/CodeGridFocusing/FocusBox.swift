//
//  FocusBox.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/5/21.
//

import Foundation
import SceneKit

let kFocusBoxContainerName = "kFocusBoxContainerName"

class FocusBox: Hashable, Identifiable {
    lazy var id = { "\(kFocusBoxContainerName)-\(UUID().uuidString)" }()
    lazy var rootNode: SCNNode = makeRootNode()
    lazy var gridNode: SCNNode = makeGridNode()
    lazy var geometryNode: SCNNode = makeGeometryNode()
    lazy var rootGeometry: SCNBox = makeGeometry()
    
    var focus: CodeGridFocusController
    
    init(_ focus: CodeGridFocusController) {
        self.focus = focus
        setup()
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (_ left: FocusBox, _ right: FocusBox) -> Bool {
        return left.id == right.id
            && left.rootNode.position == right.rootNode.position
            && left.rootNode.childNodes.count == right.rootNode.childNodes.count
    }
    
    var bounds: Bounds {
        get { rootGeometry.boundingBox }
        set {
            // Set the size of the box to match
            let pad = 16.0
            let halfPad = pad / 2.0
            rootGeometry.width = BoundsWidth(newValue) + pad
            rootGeometry.height = BoundsHeight(newValue) + pad
            rootGeometry.length = BoundsLength(newValue) + pad
            
            /// translate geometry:
            /// 1. so it's top-left-front is at (0, 0, 1/2 length)
            /// 2. so it's aligned with the bounds of the grids themselves.
            /// Note: this math assumes nothing has been moved from the origin
            geometryNode.pivot = SCNMatrix4MakeTranslation(
                -rootGeometry.width / 2.0 - newValue.min.x + halfPad,
                 rootGeometry.height / 2.0 - newValue.max.y - halfPad,
                 -newValue.min.z / 2.0
            )
        }
    }
    
    func detachGrid(_ grid: CodeGrid) {
        grid.rootNode.removeFromParentNode()
        layoutFocusedGrids()
        resetBounds()
    }
    
    func attachGrid(_ grid: CodeGrid) {
        gridNode.addChildNode(grid.rootNode)
        layoutFocusedGrids()
        resetBounds()
    }
    
    func resetBounds() {
        bounds = recomputeGridNodeBounds()
    }
    
    private func setup() {
        rootNode.name = id
        rootNode.addChildNode(geometryNode)
        rootNode.addChildNode(gridNode)
        rootNode.addWireframeBox()
        
        gridNode.name = id
        
        geometryNode.name = id
        geometryNode.categoryBitMask = HitTestType.codeGrid.rawValue
        geometryNode.geometry = rootGeometry
        
        // Adding nodes to root
        focus.controller.sceneState.rootGeometryNode.addChildNode(rootNode)
    }
    
    func layoutFocusedGrids() {
        sceneTransaction {
            focus.bimap.keysToValues.forEach { grid, depth in
                grid.position = SCNVector3Zero.translated(
                    //                    dX: -grid.centerX,
                    dZ: depth.cg * -25.0
                )
            }
        }
    }
    
    private func recomputeGridNodeBounds() -> Bounds {
        SCNNode.BoundsCaching.ClearRoot(gridNode)
        return gridNode.manualBoundingBox
    }
    
    private func makeRootNode() -> SCNNode {
        let root = SCNNode()
        root.renderingOrder = -1
        return root
    }
    
    private func makeGridNode() -> SCNNode {
        let root = SCNNode()
        root.renderingOrder = -1
        return root
    }
    
    private func makeGeometryNode() -> SCNNode {
        let root = SCNNode()
        root.renderingOrder = 1
        return root
    }
    
    private func makeGeometry() -> SCNBox {
        let box = SCNBox()
        box.chamferRadius = 4.0
        if let material = box.firstMaterial {
            material.transparency = 0.125
            material.transparencyMode = .dualLayer
            material.diffuse.contents = NSUIColor(displayP3Red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0)
        }
        return box
    }
}
