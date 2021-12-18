//
//  ControlleriOSInputCompat.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 12/17/21.
//

import Foundation
import SceneKit

class CodePagesInput {
    let controller: CodePagesController
    
    init(controller: CodePagesController) {
        self.controller = controller
    }
    
    var touchState: TouchState { controller.touchState }
    var sceneCameraNode: SCNNode { controller.sceneCameraNode }
    var sceneView: SCNView { controller.sceneView }
    var codeGridParser: CodeGridParser { controller.codeGridParser }
    
}
