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
        mainFocus.rootNode.position = mainFocus.rootNode.position.translated(
            dX: -mainFocus.rootNode.lengthX * 1.2
        )
        mainFocus = makeNewFocusBox()
    }
    
    func removeGridFromFocus(_ grid: CodeGrid) {
        mainFocus.detachGrid(grid)
    }

    func addGridToFocus(_ grid: CodeGrid, _ depth: Int) {
        mainFocus.attachGrid(grid, depth)
    }
    
    private func makeNewFocusBox() -> FocusBox {
        return focusCache.cacheNewFocus()
    }
}
