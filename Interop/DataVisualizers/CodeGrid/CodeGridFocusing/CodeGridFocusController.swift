//
//  CodeGridFocus.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/1/21.
//

import Foundation
import SceneKit

class CodeGridFocusController {
    lazy var bimap: BiMap<SCNNode, Int> = BiMap()
    lazy var mainFocus = makeNewFocusBox()
    
    let controller: CodePagesController
    
    init(controller: CodePagesController) {
        self.controller = controller
    }
    
    func removeGridFromFocus(_ grid: CodeGrid) {
        grid.rootNode.position = SCNVector3Zero
        bimap[grid.rootNode] = nil
        
        mainFocus.detachGrid(grid)
    }

    func addGridToFocus(_ grid: CodeGrid, _ depth: Int) {
        grid.rootNode.position = SCNVector3Zero
        bimap[grid.rootNode] = depth
        
        mainFocus.attachGrid(grid)
    }
    
    func makeNewFocusBox() -> FocusBox {
        return FocusBox(self)
    }
}