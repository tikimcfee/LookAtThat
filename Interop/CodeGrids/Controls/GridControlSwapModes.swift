//
//  CGCSwapModes.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/16/21.
//

import Foundation
import SceneKit

func GridControlSwapModes(_ targetGrid: CodeGrid, _ controller: CodeGridFocusController) -> CodeGridControl {
    func swapModes(_ control: CodeGridControl) {
        targetGrid.toggleGlyphs()
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
