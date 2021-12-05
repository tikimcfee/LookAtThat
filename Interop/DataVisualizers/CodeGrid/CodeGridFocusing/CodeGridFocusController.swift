//
//  CodeGridFocus.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/1/21.
//

import Foundation
import SceneKit

class CodeGridFocusController {
    
    lazy var mainFocus = makeNewFocusBox()
    
    let controller: CodePagesController
    
    init(controller: CodePagesController) {
        self.controller = controller
    }
    
    func removeGridFromFocus(_ grid: CodeGrid) {
        mainFocus.detachGrid(grid)
    }

    func addGridToFocus(_ grid: CodeGrid, _ depth: Int) {
        mainFocus.attachGrid(grid, depth)
    }
    
    func makeNewFocusBox() -> FocusBox {
        return FocusBox(self)
    }
}
