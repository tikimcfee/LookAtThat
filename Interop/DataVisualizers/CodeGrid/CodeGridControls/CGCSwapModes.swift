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
        
        sceneTransaction {
            if let _ = strongController.userFocus.bimap[strongGrid] {
                strongController.userFocus.detachGrid(strongGrid)
                strongController.userFocus.finishUpdates()
                
                strongController.mainFocus.attachGrid(strongGrid, strongController.mainFocus.deepestDepth + 1)
                strongController.mainFocus.finishUpdates()
            } else if let _ = strongController.mainFocus.bimap[strongGrid] {
                strongController.mainFocus.detachGrid(strongGrid)
                strongController.mainFocus.finishUpdates()
                
                strongController.userFocus.attachGrid(strongGrid, strongController.userFocus.deepestDepth + 1)
                strongController.userFocus.finishUpdates()
            }
        }
        
    }
    
    let settings = CodeGridControl.Settings(
        name: "Add to Focus",
        action: moveToMainFocus
    )
    
    return CodeGridControl(targetGrid: targetGrid).setup(settings)
}
