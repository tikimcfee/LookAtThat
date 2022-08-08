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
    fileprivate lazy var cylinderGeometry: SCNCylinder = makeCylinder()
    
    lazy var snapping: WorldGridSnapping = WorldGridSnapping()
    private var engine: FocusBoxLayoutEngine { focus.controller.compat.engine }
    
    var id: String
    var gridId: String { id + "-grid" }
    var focus: CodeGridFocusController
    
    var focusedGrid: CodeGrid?
    var layoutMode: LayoutMode = .cylinder
    var displayMode: DisplayMode = .boundingBox
    lazy var bimap: BiMap<CodeGrid, Int> = BiMap()
    lazy var childFocusBimap: BiMap<FocusBox, Int> = BiMap()
    var parentFocus: FocusBox?
    var rootFocus: FocusBox {
        guard let parent = parentFocus else { return self }
        return parent.rootFocus
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
}

extension FocusBox {
    static func nextId() -> String { "\(kFocusBoxContainerName)-\(UUID().uuidString)" }
    
    static func makeNext(_ controller: CodeGridFocusController) -> FocusBox {
        return FocusBox(id: nextId(), inFocus: controller)
    }
    
    func detachSelf() {
        rootNode.removeFromParentNode()
    }
}

extension FocusBox {
    var isEmpty: Bool {
        bimap.keysToValues.isEmpty
        && childFocusBimap.keysToValues.isEmpty
    }
    
    var deepestDepth: Int {
        bimap.valuesToKeys.keys.max() ?? -1
    }
    
    var childFocusDepth: Int {
        childFocusBimap.valuesToKeys.keys.max() ?? -1
    }
    
    var depthInFocusHierarchy: Int {
        if let parent = parentFocus {
            return parent.depthInFocusHierarchy + 1
        } else {
            return 0
        }
    }
    
    var geometryBounds: Bounds {
        geometryNode.boundingBox
    }
    
    var geometryBoundsInParent: Bounds {
        geometryNode.boundsInParent
    }
    
    var bounds: Bounds {
        get { rootNode.boundingBox }
        set { engine.onSetBounds(FBLEContainer(box: self), newValue) }
    }
    
    var boundsInParent: Bounds {
        get { rootNode.boundsInParent }
    }
    
    func addChildFocus(_ focus: FocusBox) {
        childFocusBimap[focus] = childFocusDepth + 1
        rootNode.addChildNode(focus.rootNode)
        if focus.parentFocus != nil {
            print("-- Resetting focus parent to \(id)")
        }
        focus.parentFocus = self
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
    
    func bringToDeepest(_ grid: CodeGrid) {
        guard let _ = bimap[grid] else { return }
        bimap[grid] = nil
        snapping.detachRetaining(grid)
        bimap.valuesToKeys
            .sorted(by: { $0.key < $1.key })
            .enumerated()
            .forEach { index, element in
                bimap[index] = element.value
            }
        bimap[deepestDepth + 1] = grid
        focusedGrid = grid
        
        if let previous = bimap[deepestDepth - 1] {
            snapping.connectWithInverses(sourceGrid: previous, to: makeNextDirection(grid))
        }
    }
        
    
    func contains(grid: CodeGrid) -> Bool {
        bimap[grid] != nil
    }
    
    func depthOf(grid: CodeGrid) -> Int? {
        bimap[grid]
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
        updateSharedGeometryBounds()
    }
    
    func layoutFocusedGrids() {
        engine.layout(FBLEContainer(box: self))
    }
}

extension FocusBox {
    enum DisplayMode {
        case invisible
        case boundingBox
    }
    
    func updateDisplayMode(_ mode: DisplayMode) {
        displayMode = mode
        updateNodeDisplay()
    }
}

extension FocusBox {
    enum LayoutMode: CaseIterable {
        case horizontal
        case stacked
        case userStack
        case cylinder
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
        case .cylinder: return .right
        }
    }
    
    private var previousDirectionForMode: SelfRelativeDirection {
        switch layoutMode {
        case .stacked: return .backward
        case .userStack: return .backward
        case .horizontal: return .left
        case .cylinder: return .left
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
//        return gridNode.computeBoundingBox(false)
        return gridNode.boundingBox
    }
}

extension FocusBox {
    func layoutChildrenRecursive() {
//        childFocusBimap.keysToValues.keys.forEach {
//            $0.layoutChildrenRecursive()
//        }
//        finishUpdates()
        finishUpdates()
        parentFocus?.layoutChildrenRecursive()
    }
}

private extension FocusBox {
    private func setup() {
        rootNode.addChildNode(geometryNode)
        rootNode.addChildNode(gridNode)
        rootNode.addWireframeBox()
        
        updateNodeDisplay()
        updateGeometryForLayoutType()
    }
    
    func makeRootNode() -> SCNNode {
        let root = SCNNode()
        root.name = id
        root.renderingOrder = -1
        return root
    }
    
    func makeGridNode() -> SCNNode {
        let root = SCNNode()
        root.name = gridId
        root.renderingOrder = -1
        return root
    }
    
    func makeGeometryNode() -> SCNNode {
        let root = SCNNode()
        root.name = id
        root.renderingOrder = 1
        return root
    }
    
    func updateSharedGeometryBounds() {
        cylinderGeometry.radius = (BoundsWidth(bounds) / 2.0).cg
        cylinderGeometry.height = (BoundsHeight(bounds)).cg
    }
    
    func updateGeometryForLayoutType() {
        switch layoutMode {
        case .cylinder:
            geometryNode.geometry = rootGeometry
        case .horizontal, .stacked, .userStack:
            geometryNode.geometry = rootGeometry
        }
    }
    
    func updateNodeDisplay() {
        geometryNode.categoryBitMask = HitTestType.codeGridFocusBox.rawValue
        switch displayMode {
        case .invisible:
//            geometryNode.categoryBitMask = 0
//            rootGeometry.materials = []
            rootGeometry.firstMaterial?.diffuse.contents = NSUIColor.clear
        case .boundingBox:
//            geometryNode.categoryBitMask = HitTestType.codeGridFocusBox.rawValue
            rootGeometry.firstMaterial?.diffuse.contents = geometryContents
        }
    }
    
    var geometryContents: Any? {
#if os(macOS)
        NSUIColor(displayP3Red: 0.3, green: 0.3, blue: 0.4, alpha: 0.60)
#else
        NSUIColor(displayP3Red: 0.3, green: 0.3, blue: 0.4, alpha: 1.0)
#endif
    }

    func makeCylinder() -> SCNCylinder {
        let cylinder = SCNCylinder()
        if let material = cylinder.firstMaterial {
            material.isDoubleSided = true
#if os(macOS)
//            material.transparency = 0.125
            material.diffuse.contents = geometryContents
            material.transparencyMode = .dualLayer
#elseif os(iOS)
            material.transparency = 0.40
            material.diffuse.contents = geometryContents
            material.transparencyMode = .default
#endif
        }
        return cylinder
    }
    
    func makeGeometry() -> SCNBox {
        let box = SCNBox()
        if let material = box.firstMaterial {
#if os(macOS)
            box.chamferRadius = 4.0
            material.transparency = 0.125
            material.diffuse.contents = geometryContents
            material.transparencyMode = .dualLayer
#elseif os(iOS)
            box.chamferRadius = 4.0
            box.width = DeviceScale.cg
            box.height = DeviceScale.cg
            box.length = DeviceScale.cg
            material.transparency = 0.40
            material.diffuse.contents = geometryContents
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

extension FocusBoxLayoutEngine {
    func defaultOnSetBounds(_ container: FBLEContainer, _ newValue: Bounds) {
        // Set the size of the box to match
        let pad: VectorFloat = 32.0
        let halfPad: VectorFloat = pad / 2.0
        
        container.rootGeometry.width = (BoundsWidth(newValue) + pad).cg
        container.rootGeometry.height = (BoundsHeight(newValue) + pad).cg
        container.rootGeometry.length = (BoundsLength(newValue) + pad).cg
        
        let rootWidth = container.rootGeometry.width.vector
        let rootHeight = container.rootGeometry.height.vector
        let rootLength = container.rootGeometry.length.vector
        
        /// translate geometry:
        /// 1. so it's top-left-front is at (0, 0, 1/2 length)
        /// 2. so it's aligned with the bounds of the grids themselves.
        /// Note: this math assumes nothing has been moved from the origin
        /// Note: -1.0 as multiple is explicit to remain compatiable between iOS macOS; '-' operand isn't universal
        let translateX = -1.0 * rootWidth / 2.0 - newValue.min.x + halfPad
        let translateY = rootHeight / 2.0 - newValue.max.y - halfPad
        let translateZ = rootLength / 2.0 - newValue.max.z - halfPad
        let newPivot = SCNMatrix4MakeTranslation(
            translateX, translateY, translateZ
        )
        
        container.geometryNode.pivot = newPivot
    }
    
    func defaultCylinderLayout(_ container: FBLEContainer) {
        // TODO: I'm not using the snap connection here. There's no direction connection to how it was laid you.
        // TODO: Add a 'path' to Snapping that let's you follow the default forward / backward direction
        let allGrids = container.box.bimap.keysToValues.keys
        allGrids
            .sorted(by: { $0.measures.lengthY < $1.measures.lengthY })
            .enumerated()
            .forEach { index, grid in
                grid.zeroedPosition()
                grid.translated(dZ: -128.0 * VectorVal(index))
            }
        
        let containerGeometryBounds = container.box.geometryBoundsInParent
        let focusChildStartPosition = SCNVector3(
            x: containerGeometryBounds.max.x + 4.0,
            y: containerGeometryBounds.min.y - 4.0,
            z: containerGeometryBounds.min.z - 4.0
        )
        
        var lastFocus: FocusBox?
        container
            .box.childFocusBimap.keysToValues.keys
            .forEach { childFocus in
                if let lastFocus = lastFocus {
                    let referencePosition = lastFocus.rootNode.position
                    let referenceBounds = lastFocus.bounds
                    childFocus.rootNode.position = SCNVector3(
                        x: referencePosition.x + referenceBounds.max.x + 16.0,
                        y: referencePosition.y,
                        z: referencePosition.z
                    )
                } else {
                    childFocus.rootNode.position = focusChildStartPosition
                }
                
                lastFocus = childFocus
            }
    }
}

class CircleFun {
    let twoPi = 2.0 * VectorVal.pi
    
    @inline(__always)
    func subdividedRadians(
        count: VectorVal,
        offset: SCNVector3 = SCNVector3Zero,
        magnitude: VectorVal,
        receiver: (SCNVector3) -> Void
    ) {
        let subdivisions = twoPi / count
        let radianStride = stride(from: 0.0, to: twoPi, by: subdivisions)
        radianStride.forEach { radians in
            let dX =  (cos(radians) * (magnitude + offset.x))
            let dY = -(sin(radians) * (magnitude + offset.x))
            receiver(SCNVector3(x: dX, y: dY, z: offset.z))
        }
    }
    
    func subdividedRadians(count: VectorVal, magnitude: VectorVal) -> [SCNVector3] {
        var points = [SCNVector3]()
        subdividedRadians(count: count, magnitude: magnitude) { points.append($0) }
        return points
    }
    
    func defaultCylinderLayout_x(_ container: FBLEContainer) {
        let allGrids = container.box.bimap.keysToValues.keys
//        let gridCount = allGrids.count
        let allChildFoci = container.box.childFocusBimap.keysToValues.keys
        let childCount = allChildFoci.count
        
//        let gridRadians = twoPi / VectorVal(gridCount)
//        let gridRadianStride = stride(from: 0.0, to: twoPi, by: gridRadians)
        let fileBounds = BoundsComputing()
                
        allGrids.enumerated().forEach { index, grid in
            grid.zeroedPosition()
            grid.translated(dZ: -16.0 * VectorVal(index))
            fileBounds.consumeBounds(grid.rootNode.boundingBox)
        }
        
        let finalGridBounds = fileBounds.bounds
        let childRadians = twoPi / VectorVal(childCount)
        let childRadianStride = stride(from: 0.0, to: twoPi, by: childRadians)
        
        zip(allChildFoci, childRadianStride).forEach { focus, radians in
            let magnitude = VectorVal(400.0)
            let dX =  (cos(radians) * (magnitude + finalGridBounds.max.x))
            let dY = finalGridBounds.min.y - 16.0
            let dZ = -(sin(radians) * (magnitude + finalGridBounds.max.x))
            
            // translate dY unit vector along z-axis, rotating the unit circle along x
            focus.rootNode.position = SCNVector3Zero
            focus.rootNode.translate(
                dX: dX,
                dY: dY,
                dZ: dZ
            )
            focus.rootNode.eulerAngles.y = radians
        }
    }
}
