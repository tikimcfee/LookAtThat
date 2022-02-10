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
    lazy var rootNode: SCNNode = makeRootNode()
    lazy var gridNode: SCNNode = makeGridNode()
    fileprivate lazy var geometryNode: SCNNode = makeGeometryNode()
    fileprivate lazy var rootGeometry: SCNBox = makeGeometry()
    
    lazy var snapping: WorldGridSnapping = WorldGridSnapping()
    private var engine: FocusBoxLayoutEngine { focus.controller.compat.engine }
    
    var id: String
    var focus: CodeGridFocusController
    
    var focusedGrid: CodeGrid?
    var layoutMode: LayoutMode = .horizontal
    lazy var bimap: BiMap<CodeGrid, Int> = BiMap()
        
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
}

extension FocusBox {
    static func nextId() -> String { "\(kFocusBoxContainerName)-\(UUID().uuidString)" }
    
    static func makeNext(_ controller: CodeGridFocusController) -> FocusBox {
        return FocusBox(id: nextId(), inFocus: controller)
    }
}

extension FocusBox {
    var deepestDepth: Int {
        bimap.valuesToKeys.keys.max() ?? -1
    }
    
    var bounds: Bounds {
        get { rootGeometry.boundingBox }
        set { engine.onSetBounds(FBLEContainer(box: self), newValue) }
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
        
        focusedGrid = grid
        if let previous = bimap[depth - 1] {
            snapping.connectWithInverses(sourceGrid: previous, to: makeNextDirection(grid))
        }
        
        if let next = bimap[depth + 1] {
            snapping.connectWithInverses(sourceGrid: next, to: makePreviousDirection(grid))
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
    
    func layoutFocusedGrids() {
        engine.layout(FBLEContainer(box: self))
    }
}

extension FocusBox {
    enum LayoutMode: CaseIterable {
        case horizontal
        case stacked
        case userStack
    }
    
    private typealias GridDirection = WorldGridSnapping.RelativeGridMapping
    
    private func makeNextDirection(_ grid: CodeGrid) -> GridDirection {
        return GridDirection.make(nextDirectionForMode, grid)
    }
    
    private func makePreviousDirection(_ grid: CodeGrid) -> WorldGridSnapping.RelativeGridMapping {
        return GridDirection.make(previousDirectionForMode, grid)
    }
    
    private var nextDirectionForMode: SelfRelativeDirection {
        switch layoutMode {
        case .stacked: return .forward
        case .userStack: return .forward
        case .horizontal: return .right
        }
    }
    
    private var previousDirectionForMode: SelfRelativeDirection {
        switch layoutMode {
        case .stacked: return .backward
        case .userStack: return .backward
        case .horizontal: return .left
        }
    }
}

private extension FocusBox {
    func iterateGrids(_ receiver: (CodeGrid?, CodeGrid, Int) -> Void) {
        var previousGrid: CodeGrid?
        let sorted = bimap.keysToValues.sorted(by: { leftTuple, rightTuple in
            return leftTuple.key.measures.lengthY < rightTuple.key.measures.lengthY
        })
        
        sorted.enumerated().forEach { index, tuple in
            receiver(previousGrid, tuple.0, index)
            previousGrid = tuple.0
        }
    }
    
    func recomputeGridNodeBounds() -> Bounds {
        // It's mostly safe to assume the child code grids
        // aren't changing bounds, so we just need to calculate
        // this grid itself. Not really useful to cache it either
        // since it's expected to update frequently.
        return gridNode.computeBoundingBox(false)
    }
}

private extension FocusBox {
    private func setup() {
        rootNode.addChildNode(geometryNode)
        rootNode.addChildNode(gridNode)
        rootNode.addWireframeBox()
        
        geometryNode.geometry = rootGeometry
    }
    
    func makeRootNode() -> SCNNode {
        let root = SCNNode()
        root.name = id
        root.renderingOrder = -1
        return root
    }
    
    func makeGridNode() -> SCNNode {
        let root = SCNNode()
        root.name = id
        root.renderingOrder = -1
        return root
    }
    
    func makeGeometryNode() -> SCNNode {
        let root = SCNNode()
        root.name = id
        root.categoryBitMask = HitTestType.codeGridFocusBox.rawValue
        root.renderingOrder = 1
        return root
    }
    
    func makeGeometry() -> SCNBox {
        let box = SCNBox()
        if let material = box.firstMaterial {
#if os(macOS)
            box.chamferRadius = 4.0
            material.transparency = 0.125
            material.diffuse.contents = NSUIColor(displayP3Red: 0.3, green: 0.3, blue: 0.4, alpha: 0.65)
            material.transparencyMode = .dualLayer
#elseif os(iOS)
            box.width = DeviceScale.cg
            box.height = DeviceScale.cg
            box.length = DeviceScale.cg
//            material.transparency = 0.40
            material.diffuse.contents = NSUIColor(displayP3Red: 0.3, green: 0.3, blue: 0.4, alpha: 0.35)
            material.transparencyMode = .dualLayer
#endif
            
        }
        return box
    }
}

struct FBLEContainer {
    let box: FocusBox
    
    var geometryNode: SCNNode { box.geometryNode }
    var rootGeometry: SCNBox { box.rootGeometry }
}

protocol FocusBoxLayoutEngine {
    func onSetBounds(_ container: FBLEContainer, _ newValue: Bounds)
    func layout(_ container: FBLEContainer)
}
