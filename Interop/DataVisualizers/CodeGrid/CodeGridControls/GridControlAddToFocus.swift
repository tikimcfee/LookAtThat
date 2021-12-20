//
//  GridControlAddToFocus.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/20/21.
//

import Foundation
import SceneKit

func CGCAddToFocus(_ targetGrid: CodeGrid, _ controller: CodeGridFocusController) -> CodeGridControl {
    weak var weakTargetGrid = targetGrid
    weak var weakController = controller
    
    func moveToMainFocus(_ control: CodeGridControl) {
        guard let strongGrid = weakTargetGrid,
              let strongController = weakController
        else { return }
        
        sceneTransaction {
            if let _ = strongController.userDepthFor(strongGrid) {
                strongController.detatchFromUserFocus(strongGrid)
                strongController.finishUserUpdates()
                
                strongController.attachToTargetFocus(strongGrid, strongController.deepestDepth + 1)
                strongController.finishUpdates()
            } else if let _ = strongController.depthFor(strongGrid) {
                strongController.removeGridFromFocus(strongGrid)
                strongController.finishUpdates()
                
                strongController.attachToUserFocus(strongGrid, strongController.userDeepestDepth + 1)
                strongController.finishUserUpdates()
            }
        }
        
    }
    
    let settings = CodeGridControl.Settings(
        name: "Add to Focus",
        action: moveToMainFocus
    )
    
    return CodeGridControl(targetGrid: targetGrid).setup(settings)
}
