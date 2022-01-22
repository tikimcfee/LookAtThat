//
//  CodeGridFocus.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/1/21.
//

import Foundation
import SceneKit

class FocusCache: LockingCache<String, FocusBox> {
    let parentController: CodeGridFocusController
    
    init(parentController: CodeGridFocusController) {
        self.parentController = parentController
    }
    
    func maybeGet(_ id: FocusBox.ID) -> FocusBox? {
        var box: FocusBox?
        lockAndDo { box = $0[id] }
        return box
    }
    
    func cacheNewFocus() -> FocusBox {
        return self[FocusBox.nextId()]
    }
    
    override func make(_ key: String, _ store: inout [String : FocusBox]) -> FocusBox {
        return FocusBox(id: key, inFocus: parentController)
    }
}

class CodeGridFocusController {
    lazy var focusCache = FocusCache(parentController: self)

    private lazy var currentTargetFocus: FocusBox = makeNewFocusBox()
    
    private lazy var userFocusPlacementNode: SCNNode = makeNewPlacementNode()
    private lazy var userFocus: FocusBox = makeNewUserFocusBox()
    
    let controller: CodePagesController
    
    init(controller: CodePagesController) {
        self.controller = controller
    }
}

// MARK: - Current Target Focus

extension CodeGridFocusController {
    func depthFor(_ grid: CodeGrid) -> Int? {
        currentTargetFocus.bimap[grid]
    }
    
    var deepestDepth: Int {
        currentTargetFocus.deepestDepth
    }
    
    func setNewFocus() {
        // ------------------------------------------------
        // This is absolutely freaking nuts.
        // Because most of the highlight selection stuff is metainfo based,
        // and because the `clone()` function is so damn beautifully recursive,
        // cloning the root of the focus gets you an instant and free copy of your
        // state. Names are preserved, so hit tests work as well.
        if let parent = currentTargetFocus.rootNode.parent {
            currentTargetFocus.rootNode.removeFromParentNode()
            currentTargetFocus.rootNode = currentTargetFocus.rootNode.clone()
            parent.addChildNode(currentTargetFocus.rootNode)
        }
        // ------------------------------------------------
        
        currentTargetFocus = makeNewFocusBox()
    }
    
    func updateBoxFocusedGrid(inDirection direction: SelfRelativeDirection) -> CodeGrid? {
        guard let focus = currentTargetFocus.focusedGrid,
              let firstFocused = currentTargetFocus.snapping.gridsRelativeTo(focus, direction).first?.targetGrid
        else { return nil }
        
        currentTargetFocus.focusedGrid = firstFocused
        return firstFocused
    }
    
    func resetState() {
        currentTargetFocus.snapping.clearAll()
        currentTargetFocus.focusedGrid = nil
        currentTargetFocus.bimap.keysToValues.removeAll()
        currentTargetFocus.bimap.valuesToKeys.removeAll()
    }
    
    func currentDirections() -> [WorldGridSnapping.RelativeGridMapping] {
        guard let focus = currentTargetFocus.focusedGrid else { return [] }
        return currentTargetFocus.snapping.gridsRelativeTo(focus)
    }
    
    func addNodeToMainFocusGrid(_ node: SCNNode) {
        currentTargetFocus.gridNode.addChildNode(node)
    }
    
    func addGridToFocus(_ grid: CodeGrid, _ depth: Int) {
        currentTargetFocus.attachGrid(grid, depth)
    }
    
    func removeGridFromFocus(_ grid: CodeGrid) {
        currentTargetFocus.detachGrid(grid)
    }
    
    func attachToTargetFocus(_ grid: CodeGrid, _ depth: Int) {
        currentTargetFocus.attachGrid(grid, depth)
    }
    
    func resetBounds() {
        currentTargetFocus.resetBounds()
    }
    
    func layoutFocusedGrids() {
        currentTargetFocus.layoutFocusedGrids()
    }
    
    func finishUpdates() {
        currentTargetFocus.finishUpdates()
    }
    
    func setFocusedDepth(_ depth: Int) {
        currentTargetFocus.setFocusedGrid(depth)
    }
    
    func setLayoutModel(_ mode: FocusBox.LayoutMode) {
        currentTargetFocus.layoutMode = mode
    }
    
    func layout(_ receiver: (CodeGridFocusController, FocusBox) -> Void) {
        receiver(self, currentTargetFocus)
        finishUpdates()
    }
    
    func resize(_ receiver: (CodeGridFocusController, FocusBox) -> Void) {
        receiver(self, currentTargetFocus)
        resetBounds()
    }
}

// MARK: - User Focus

extension CodeGridFocusController {
    func attachToUserFocus(_ grid: CodeGrid, _ depth: Int) {
        userFocus.attachGrid(grid, depth)
    }
    
    func detatchFromUserFocus(_ grid: CodeGrid) {
        userFocus.detachGrid(grid)
    }
    
    func userDepthFor(_ grid: CodeGrid) -> Int? {
        userFocus.bimap[grid]
    }
    
    var userDeepestDepth: Int {
        userFocus.deepestDepth
    }
    
    func finishUserUpdates() {
        userFocus.finishUpdates()
    }
    
    func resetUserBounds() {
        userFocus.finishUpdates()
    }
    
    func userLayout(_ receiver: (CodeGridFocusController, FocusBox) -> Void) {
        receiver(self, userFocus)
        finishUserUpdates()
    }
    
    func userResize(_ receiver: (CodeGridFocusController, FocusBox) -> Void) {
        receiver(self, userFocus)
        resetUserBounds()
    }

}

// MARK: - Setup

private extension CodeGridFocusController {
    func makeNewPlacementNode() -> SCNNode {
        let placementNode = SCNNode()
        return placementNode
    }
    
    func makeNewFocusBox() -> FocusBox {
        let newFocus = focusCache.cacheNewFocus()
        controller.codeGridParser.editorWrapper.doInWorld { camera, rootNode in
#if os(macOS)
            let simdMultiple = camera.simdWorldFront * 128.0
#elseif os(iOS)
            let simdMultiple = camera.simdWorldFront * 0.03
#endif
            newFocus.rootNode.position = camera.position
            newFocus.rootNode.simdPosition += simdMultiple
            rootNode.addChildNode(newFocus.rootNode)
        }
        
        return newFocus
    }
    
    func makeNewUserFocusBox() -> FocusBox {
        let newFocus = focusCache.cacheNewFocus()
        newFocus.layoutMode = .userStack
        
        let placementNode = userFocusPlacementNode
        placementNode.addingChild(newFocus.rootNode)
        
        controller.codeGridParser.editorWrapper.doInWorld { camera, rootNode in
            placementNode.addConstraint(makeCameraConstraint(camera))
            camera.addChildNode(placementNode)
        }
        
        return newFocus
    }
}

#if os(macOS)
private extension CodeGridFocusController {
    func makeCameraConstraint(_ camera: SCNNode) -> SCNConstraint {
        let depth = Float(128)
        let dZ = CGFloat(-1.0 * depth)
        
        let position = SCNTransformConstraint(
            inWorldSpace: true,
            with: { node, currentTransform in
                return SCNMatrix4Translate(
                    camera.transform,
                    0.0,
                    0.0,
                    dZ
                )
            }
        )
        
        return position
    }
}

#elseif os(iOS)
private extension CodeGridFocusController {
    func makeCameraConstraint(_ camera: SCNNode) -> SCNConstraint {
        let depth = VectorFloat(0.2)
        
        let position = SCNTransformConstraint(
            inWorldSpace: true,
            with: { node, currentTransform in
                node.simdPosition = camera.simdWorldPosition
                node.simdPosition += camera.simdWorldFront * depth
                node.simdOrientation = camera.simdOrientation
                return node.transform
            }
        )
        
        return position
    }
}
#endif
