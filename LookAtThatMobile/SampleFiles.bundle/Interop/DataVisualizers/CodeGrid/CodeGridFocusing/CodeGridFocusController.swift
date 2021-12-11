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
    
    func cacheNewFocus() -> FocusBox {
        return self[FocusBox.nextId()]
    }
    
    override func make(_ key: String, _ store: inout [String : FocusBox]) -> FocusBox {
        return FocusBox(id: key, inFocus: parentController)
    }
}

class CodeGridFocusController {
    lazy var focusCache = FocusCache(parentController: self)
    lazy var mainFocus = makeNewFocusBox()
    
    let controller: CodePagesController
    
    init(controller: CodePagesController) {
        self.controller = controller
    }
    
    func setNewFocus() {
        // ------------------------------------------------
        // This is absolutely freaking nuts.
        // Because most of the highlight selection stuff is metainfo based,
        // and because the `clone()` function is so damn beautifully recursive,
        // cloning the root of the focus gets you an instant and free copy of your
        // state. Names are preserved, so hit tests work as well.
        if let parent = mainFocus.rootNode.parent {
            mainFocus.rootNode.removeFromParentNode()
            mainFocus.rootNode = mainFocus.rootNode.clone()
            parent.addChildNode(mainFocus.rootNode)
        }
        // ------------------------------------------------
        
        mainFocus = makeNewFocusBox()
    }
    
    func resetState() {
        mainFocus.snapping.clearAll()
        mainFocus.focusedGrid = nil
        mainFocus.bimap.keysToValues.removeAll()
        mainFocus.bimap.valuesToKeys.removeAll()
    }
    
    func resetBounds() {
        mainFocus.resetBounds()
    }
    
    func layoutFocusedGrids() {
        mainFocus.layoutFocusedGrids()
    }
    
    func finishUpdates() {
        mainFocus.finishUpdates()
    }
    
    func removeGridFromFocus(_ grid: CodeGrid) {
        mainFocus.detachGrid(grid)
    }
    
    func addGridToFocus(_ grid: CodeGrid, _ depth: Int) {
        mainFocus.attachGrid(grid, depth)
    }
    
    func setFocusedDepth(_ depth: Int) {
        mainFocus.setFocusedGrid(depth)
    }
    
    func setNewFocus(inDirection direction: SelfRelativeDirection) -> CodeGrid? {
        guard let focus = mainFocus.focusedGrid,
              let firstFocused = mainFocus.snapping.gridsRelativeTo(focus, direction).first?.targetGrid
        else { return nil }
        
        mainFocus.focusedGrid = firstFocused
        return firstFocused
    }
    
    func currentDirections() -> WorldGridSnapping.RelativeMappings {
        guard let focus = mainFocus.focusedGrid else { return [] }
        return mainFocus.snapping.gridsRelativeTo(focus)
    }
    
    private func makeNewFocusBox() -> FocusBox {
        return focusCache.cacheNewFocus()
    }
}
