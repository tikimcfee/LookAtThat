//
//  FocusControlShiftFocus.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/20/21.
//

import Foundation

func FocusControlShiftFocus(_ targetFocus: FocusBox, _ controller: CodeGridFocusController) -> FocusBoxControl {
    weak var weakTargetFocus = targetFocus
    
    func shiftFocus(_ control: FocusBoxControl) {
        guard let strongTarget = weakTargetFocus else { return }
        
        if let focusedGrid = targetFocus.focusedGrid,
           let parent = focusedGrid.rootNode.parent {
            
            
        }
    }
    
    let settings = FocusBoxControl.Settings(
        name: "Shift Back",
        action: shiftFocus
    )
    
    return FocusBoxControl(
        targetBox: targetFocus,
        parser: controller.controller.codeGridParser
    ).setup(settings)
}

