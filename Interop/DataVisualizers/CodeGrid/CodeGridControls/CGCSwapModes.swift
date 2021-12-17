//
//  CGCSwapModes.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/16/21.
//

import Foundation
import SceneKit

func CGCSwapModes(_ targetGrid: CodeGrid) -> CodeGridControl {
    weak var weakTargetGrid = targetGrid
    
    func swapModes(_ control: CodeGridControl) {
        guard let strongGrid = weakTargetGrid else { return }
        
        switch strongGrid.displayMode {
        case .glyphs:
            strongGrid.displayMode = .layers
        case .layers, .all:
            strongGrid.displayMode = .glyphs
        }
    }
    
    let settings = CodeGridControl.Settings(
        name: "Swap Modes",
        action: swapModes
    )
    
    return CodeGridControl(targetGrid: targetGrid).setup(settings)
}

func CGCAddToFocus(_ targetGrid: CodeGrid, _ controller: CodeGridFocusController) -> CodeGridControl {
    weak var weakTargetGrid = targetGrid
    weak var weakController = controller
    
    func moveToMainFocus(_ control: CodeGridControl) {
        guard let strongGrid = weakTargetGrid,
              let strongController = weakController
        else { return }
        
        if let _ = strongController.mainFocus.bimap[strongGrid] {
            strongController.removeGridFromFocus(strongGrid)
            strongGrid.measures.position = strongController.mainFocus.rootNode.position
        } else {
            strongGrid.rootNode.removeFromParentNode()
            strongController.addGridToFocus(strongGrid, strongController.mainFocus.deepestDepth + 1)
        }
    }
    
    let settings = CodeGridControl.Settings(
        name: "Add to Focus",
        action: moveToMainFocus
    )
    
    return CodeGridControl(targetGrid: targetGrid).setup(settings)
}
