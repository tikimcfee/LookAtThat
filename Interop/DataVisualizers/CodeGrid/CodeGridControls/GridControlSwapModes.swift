//
//  CGCSwapModes.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/16/21.
//

import Foundation
import SceneKit

func GridControlSwapModes(_ targetGrid: CodeGrid, _ controller: CodeGridFocusController) -> CodeGridControl {
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
    
    return CodeGridControl(
        targetGrid: targetGrid,
        parser: controller.controller.codeGridParser
    ).setup(settings)
}
