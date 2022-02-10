//
//  GridControlAddToFocus.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/20/21.
//

import Foundation
import SceneKit

func GridControlAddToFocus(_ targetGrid: CodeGrid, _ controller: CodeGridFocusController) -> CodeGridControl {
    let userController = controller.userController

    func moveToMainFocus(_ control: CodeGridControl) {
        sceneTransaction {
            if let _ = userController.userDepthFor(targetGrid) {
                userController.detatchFromUserFocus(targetGrid)
                userController.finishUserUpdates()
                
                controller.attachToTargetFocus(targetGrid, controller.deepestDepth + 1)
                controller.finishUpdates()
            } else if let _ = controller.depthFor(targetGrid) {
                controller.removeGridFromFocus(targetGrid)
                controller.finishUpdates()
                
                userController.attachToUserFocus(targetGrid, userController.userDeepestDepth + 1)
                userController.finishUserUpdates()
            }
        }
    }
    
    let settings = CodeGridControl.Settings(
        name: "Add to Focus",
        action: moveToMainFocus
    )
    
    return CodeGridControl(
        targetGrid: targetGrid,
        parser: controller.controller.codeGridParser
    ).setup(settings)
}
