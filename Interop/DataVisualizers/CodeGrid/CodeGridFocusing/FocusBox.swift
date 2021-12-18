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
    
    var focusedGrid: CodeGrid?
    var layoutMode: LayoutMode = .stacked
    lazy var bimap: BiMap<CodeGrid, Int> = BiMap()
    lazy var rootNode: SCNNode = makeRootNode()
    lazy var gridNode: SCNNode = makeGridNode()
    private lazy var geometryNode: SCNNode = makeGeometryNode()
    private lazy var rootGeometry: SCNBox = makeGeometry()
    lazy var snapping: WorldGridSnapping = WorldGridSnapping()
    var engine: FocusBoxLayoutEngine { focus.controller.compat.engine }
    
    var id: String
    var focus: CodeGridFocusController
    
    var deepestDepth: Int {
        bimap.valuesToKeys.keys.max() ?? -1
    }
    
    init(id: String, inFocus focus: CodeGridFocusController) {
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
            let pad: VectorFloat = 32.0
            let halfPad: VectorFloat = pad / 2.0
            
            rootGeometry.width = (BoundsWidth(newValue) + pad).cg
            rootGeometry.height = (BoundsHeight(newValue) + pad).cg
            rootGeometry.length = (BoundsLength(newValue) + pad).cg
            
            let rootWidth = rootGeometry.width.vector
            let rootHeight = rootGeometry.height.vector
            
            /// translate geometry:
            /// 1. so it's top-left-front is at (0, 0, 1/2 length)
            /// 2. so it's aligned with the bounds of the grids themselves.
            /// Note: this math assumes nothing has been moved from the origin
            
            let translateX = -1.0 * rootWidth / 2.0 - newValue.min.x + halfPad
            let translateY = rootHeight / 2.0 - newValue.max.y - halfPad
            let translateZ = -newValue.min.z / 2.0
            
            geometryNode.pivot = SCNMatrix4MakeTranslation(
                translateX, translateY, translateZ
            )
        }
    }
    
    func detachGrid(_ grid: CodeGrid) {
        grid.rootNode.position = SCNVector3Zero
        grid.rootNode.removeFromParentNode()
        snapping.detachRetaining(grid)
        
        guard let depth = bimap[grid] else { return }
        bimap[grid] = nil
        let sortedKeys = Array(bimap.valuesToKeys.keys.sorted(by: { $0 < $1 } ))
        sortedKeys.forEach { key in
            if key <= depth { return }
            let newKey = key - 1
            let swap = bimap[key]
            bimap[key] = nil
            bimap[newKey] = swap
        }
    }
    
    func attachGrid(_ grid: CodeGrid, _ depth: Int) {
        grid.rootNode.position = SCNVector3Zero
        gridNode.addChildNode(grid.rootNode)
        bimap[grid] = depth
        
        var nextDirection: WorldGridSnapping.RelativeGridMapping {
            switch layoutMode {
            case .stacked: return .forward(grid)
            case .horizontal: return .right(grid)
            }
        }
        
        var previousDirection: WorldGridSnapping.RelativeGridMapping {
            switch layoutMode {
            case .stacked: return .backward(grid)
            case .horizontal: return .left(grid)
            }
        }
        
        if let previous = bimap[depth - 1] {
            snapping.connectWithInverses(sourceGrid: previous, to: nextDirection)
        }
        
        if let next = bimap[depth + 1] {
            snapping.connectWithInverses(sourceGrid: next, to: previousDirection)
        }
    }
    
    func setFocusedGrid(_ depth: Int) {
        focusedGrid = bimap[depth]
    }
    
    func finishUpdates() {
        layoutFocusedGrids()
        resetBounds()
    }
    
    func resetBounds() {
        bounds = recomputeGridNodeBounds()
    }
    
    private func setup() {
        rootNode.addChildNode(geometryNode)
        rootNode.addChildNode(gridNode)
        rootNode.addWireframeBox()
        
        geometryNode.geometry = rootGeometry
    }
    
    func layoutFocusedGrids(_ alignTrailing: Bool = false) {
        engine.layout(self)
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
        root.name = id
        root.renderingOrder = -1
        return root
    }
    
    private func makeGridNode() -> SCNNode {
        let root = SCNNode()
        root.name = id
        root.renderingOrder = -1
        return root
    }
    
    private func makeGeometryNode() -> SCNNode {
        let root = SCNNode()
        root.name = id
        root.categoryBitMask = HitTestType.codeGridFocusBox.rawValue
        root.renderingOrder = 1
        return root
    }
    
    private func makeGeometry() -> SCNBox {
        let box = SCNBox()
        box.chamferRadius = 4.0
        if let material = box.firstMaterial {
            #if os(macOS)
            material.transparency = 0.125
            #endif
            material.transparencyMode = .dualLayer
            material.diffuse.contents = NSUIColor(displayP3Red: 0.3, green: 0.3, blue: 0.4, alpha: 0.75)
        }
        return box
    }
}

protocol FocusBoxLayoutEngine {
    func layout(_ box: FocusBox)
}
