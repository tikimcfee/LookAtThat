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
    enum LayoutMode {
        case horizontal
        case stacked
    }
    
    static func nextId() -> String { "\(kFocusBoxContainerName)-\(UUID().uuidString)" }
    
    lazy var bimap: BiMap<CodeGrid, Int> = BiMap()
    lazy var rootNode: SCNNode = makeRootNode()
    lazy var gridNode: SCNNode = makeGridNode()
    lazy var geometryNode: SCNNode = makeGeometryNode()
    lazy var rootGeometry: SCNBox = makeGeometry()
    
    var id: String
    var focus: CodeGridFocusController
    
    init(id: String,
         inFocus focus: CodeGridFocusController) {
        self.id = id
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
        grid.rootNode.position = SCNVector3Zero
        grid.rootNode.removeFromParentNode()
        bimap[grid] = nil
    }
    
    func attachGrid(_ grid: CodeGrid, _ depth: Int) {
        grid.rootNode.position = SCNVector3Zero
        gridNode.addChildNode(grid.rootNode)
        bimap[grid] = depth
    }
    
    func finishUpdates() {
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
        
        // TODO: Something other than the focus should add it to the scene
        // Adding nodes to root
        focus.controller.sceneState.rootGeometryNode.addChildNode(rootNode)
    }
    
    
    private let zDepthDistance = 75.0
    func layoutFocusedGrids() {
        sceneTransaction {
            iterateGrids { previousGrid, grid, depth in
                grid.rootNode.position = SCNVector3Zero.translated(
                    dZ: depth.cg * -zDepthDistance
                )
            }
        }
    }
    
    private func iterateGrids(_ receiver: (CodeGrid?, CodeGrid, Int) -> Void) {
        var previousGrid: CodeGrid?
        let sorted = bimap.keysToValues.sorted(by: { leftTuple, rightTuple in
            return leftTuple.key.measures.lengthY < rightTuple.key.measures.lengthY
        })
        sorted.enumerated().forEach { index, tuple in
            receiver(previousGrid, tuple.0, index)
            previousGrid = tuple.0
        }
    }
    
    private func recomputeGridNodeBounds() -> Bounds {
        // It's mostly safe to assume the child code grids
        // aren't changing bounds, so we just need to calculate
        // this grid itself. Not really useful to cache it either
        // since it's expected to update frequently.
        return gridNode.computeBoundingBox(false)
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
            material.diffuse.contents = NSUIColor(displayP3Red: 0.3, green: 0.3, blue: 0.4, alpha: 0.75)
        }
        return box
    }
}
