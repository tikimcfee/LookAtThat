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
        return self[id]
    }
    
    func cacheNewFocus() -> FocusBox {
        return self[FocusBox.nextId()]
    }
    
    override func make(_ key: String, _ store: inout [String : FocusBox]) -> FocusBox {
        return FocusBox(id: key, inFocus: parentController)
    }
}

class CodeGridFocusController {
    private(set) lazy var focusCache = FocusCache(parentController: self)
    private(set) lazy var currentTargetFocus: FocusBox = makeNewFocusBox()
    private(set) lazy var userController = CodeGridUserFocusController(rootController: self)

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
        // NOTE: this does not clone grids, and does not guard against other actions in
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
    
    func appendToTarget(focus: FocusBox) {
        currentTargetFocus.addChildFocus(focus)
    }
    
    func append(grid: CodeGrid, to target: FocusBox) {
        target.attachGrid(grid, target.deepestDepth + 1)
    }
    
    func appendToTarget(grid: CodeGrid) {
        currentTargetFocus.attachGrid(grid, deepestDepth + 1)
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
    
    func doRender(
        on target: FocusBox,
        _ receiver: () -> Void
    ) {
        sceneTransaction(0) {
            receiver()
            target.finishUpdates()
        }
        target.resetBounds()
    }
    
    func makeNewPlacementNode() -> SCNNode {
        let placementNode = SCNNode()
        return placementNode
    }
}

// MARK: - Setup

private extension CodeGridFocusController {
    
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
}
