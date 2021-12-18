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
    var layoutMode: LayoutMode = .horizontal
    lazy var bimap: BiMap<CodeGrid, Int> = BiMap()
    lazy var rootNode: SCNNode = makeRootNode()
    lazy var gridNode: SCNNode = makeGridNode()
    private lazy var geometryNode: SCNNode = makeGeometryNode()
    private lazy var rootGeometry: SCNBox = makeGeometry()
    lazy var snapping: WorldGridSnapping = WorldGridSnapping()
    
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
        guard let first = bimap[0] else {
            print("No depth-0 grid to start layout")
            return
        }
        
        
        let xLengthPadding = 8.0
        let zLengthPadding = 150.0
        
        sceneTransaction {
            switch layoutMode {
            case .horizontal:
                horizontalLayout()
            case .stacked:
                stackLayout()
            }
        }
        
        func horizontalLayout() {
            snapping.iterateOver(first, direction: .right) { previous, current, _ in
                if let previous = previous {
                    current.measures
                        .setTop(previous.measures.top)
                        .setLeading(previous.measures.trailing + xLengthPadding)
                        .setBack(previous.measures.back)
                } else {
                    current.zeroedPosition()
                }
            }
        }
        
        func stackLayout() {
            snapping.iterateOver(first, direction: .forward) { previous, current, _ in
                if let previous = previous {
                    current.measures
                        .setTop(previous.measures.top)
                        .alignedCenterX(previous)
                        .setBack(previous.measures.back - zLengthPadding)
                } else {
                    current.zeroedPosition()
                }
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
            material.transparency = 0.125
            material.transparencyMode = .dualLayer
            material.diffuse.contents = NSUIColor(displayP3Red: 0.3, green: 0.3, blue: 0.4, alpha: 0.75)
        }
        return box
    }
}
