//
//  CodeGridFocus.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/1/21.
//

import Foundation
import SceneKit

class FocusBox {
    lazy var rootNode: SCNNode = makeRootNode()
    
    lazy var gridNode: SCNNode = makeGridNode()
    lazy var geometryNode: SCNNode = makeGeometryNode()
    lazy var rootGeometry: SCNBox = makeGeometry()
    lazy var sizeConstraint: SCNConstraint = makeGeometryConstraint()
    
    lazy var id = { "\(kContainerName)-\(UUID().uuidString)" }()
    
    var focus: CodeGridFocus
    
    init(_ focus: CodeGridFocus) {
        self.focus = focus
        setup()
    }
    
    var bounds: Bounds {
        get { rootGeometry.boundingBox }
        set {
            // Set the size of the box to match
            let pad = 8.0
            let halfPad = pad / 2.0
            rootGeometry.width = BoundsWidth(newValue) + pad
            rootGeometry.height = BoundsHeight(newValue) + pad
            rootGeometry.length = BoundsLength(newValue) + pad
            
            /// translate geometry:
            /// 1. so it's top-left-front is at (0, 0, 1/2 length)
            /// 2. so it's aligned with the bounds of the grids themselves.
            geometryNode.pivot = SCNMatrix4MakeTranslation(
//                -rootGeometry.width / 2.0 + (halfPad),
                0,
                 rootGeometry.height / 2.0 - (newValue.max.y) - (halfPad),
                -rootGeometry.length / 2.0 - (newValue.min.z) + (halfPad)
            )
        }
    }
    
    func detachGrid(_ grid: CodeGrid) {
        grid.rootNode.removeFromParentNode()
        bounds = recomputeGridNodeBounds()
    }
    
    func attachGrid(_ grid: CodeGrid) {
        gridNode.addChildNode(grid.rootNode)
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
        geometryNode.addConstraint(makeGeometryConstraint())
        geometryNode.geometry = rootGeometry

        // Adding nodes to root
        focus.controller.sceneState.rootGeometryNode.addChildNode(rootNode)
    }
    
    private func recomputeGridNodeBounds() -> Bounds {
        SCNNode.BoundsCaching.ClearRoot(gridNode)
        return gridNode.manualBoundingBox
    }
    
    private func makeRootNode() -> SCNNode {
        let root = SCNNode()
        return root
    }
    
    private func makeGridNode() -> SCNNode {
        let root = SCNNode()
        return root
    }
    
    private func makeGeometryNode() -> SCNNode {
        let root = SCNNode()
        return root
    }
    
    private func makeGeometry() -> SCNBox {
        let box = SCNBox()
        box.chamferRadius = 4.0
        box.firstMaterial?.diffuse.contents = NSUIColor(displayP3Red: 0.3, green: 0.3, blue: 0.4, alpha: 0.2)
        box.length = PAGE_EXTRUSION_DEPTH
        return box
    }
    
    func makeGeometryConstraint() -> SCNTransformConstraint{
        func onConstraint(_ node: SCNNode, _ transform: SCNMatrix4) -> SCNMatrix4 {
            return transform
            
            guard let geometry = node.geometry as? SCNBox, geometry === rootGeometry else {
                print("Missing geometry")
                return node.transform
            }

            // final_x = current_x * scale_x
                // scale_x = final_x / current_x
            // final_y = current_y * scale_y
                // scale_y = final_y / current_y
            // final_y = current_y * scale_y
                // scale_z = final_z / current_z
            let newBounds = recomputeGridNodeBounds()
            let currentBounds = geometry.boundingBox
            
            let scaleX = BoundsWidth(newBounds) / BoundsWidth(currentBounds)
            let scaleY = BoundsHeight(newBounds) / BoundsHeight(currentBounds)
            let scaleZ = BoundsLength(newBounds) / BoundsLength(currentBounds)
            let finalScale = SCNMatrix4Scale(transform, scaleX, scaleY, scaleZ)
//            let finalTranslate = SCNMatrix4Translate(finalScale, 100, 0, 0)
            print(finalScale)
            return finalScale
        }
        
        return SCNTransformConstraint(
            inWorldSpace: false,
            with: onConstraint
        )
    }
}

class CodeGridFocus {
    
    var bimap: BiMap<SCNNode, Int> = BiMap()
    lazy var constraint = makeConstraint()
    lazy var focusBox = FocusBox(self)
    let controller: CodePagesController
    
    init(controller: CodePagesController) {
        self.controller = controller
    }
    
    func depth(_ node: SCNNode) -> CGFloat {
        CGFloat(bimap[node] ?? 0)
    }
    
    func removeGridFromFocus(_ grid: CodeGrid) {
        bimap[grid.rootNode] = nil
        focusBox.detachGrid(grid)
        
        layoutFocusedGrids()
//        grid.rootNode.removeConstraint(constraint)
    }

    func addGridToFocus(_ grid: CodeGrid, _ depth: Int) {
        bimap[grid.rootNode] = depth
        focusBox.attachGrid(grid)
        
        layoutFocusedGrids()
//        grid.rootNode.addConstraint(constraint)
    }
    
    func layoutFocusedGrids() {
        sceneTransaction {
            bimap.keysToValues.forEach { grid, depth in
                grid.position = SCNVector3Zero.translated(
                    dX: -grid.centerX,
                    dZ: depth.cg * -25.0
                )
            }
        }
    }
    
    func makeConstraint() -> SCNTransformConstraint{
        func onConstraint(_ node: SCNNode, _ position: SCNVector3) -> SCNVector3 {
//            return position
            return SCNVector3Zero.translated(
                dX: -node.centerX,
                dZ: self.depth(node) * -25.0
            )
        }
        
        return SCNTransformConstraint.positionConstraint(
            inWorldSpace: false,
            with: onConstraint
        )
    }
}
