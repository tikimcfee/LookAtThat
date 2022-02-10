//
//  UserFocusController.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 2/9/22.
//

import SceneKit
import Foundation

// MARK: - User Focus

class CodeGridUserFocusController {
    private lazy var userFocusPlacementNode: SCNNode = rootController.makeNewPlacementNode()
    private lazy var userFocus: FocusBox = makeNewUserFocusBox()
    
    private let rootController: CodeGridFocusController
    private var focusCache: FocusCache { rootController.focusCache }
    private var codePageController: CodePagesController { rootController.controller }
    
    internal init(rootController: CodeGridFocusController) {
        self.rootController = rootController
    }
    
    func attachToUserFocus(_ grid: CodeGrid, _ depth: Int) {
        userFocus.attachGrid(grid, depth)
    }
    
    func detatchFromUserFocus(_ grid: CodeGrid) {
        userFocus.detachGrid(grid)
    }
    
    func userDepthFor(_ grid: CodeGrid) -> Int? {
        userFocus.bimap[grid]
    }
    
    var userDeepestDepth: Int {
        userFocus.deepestDepth
    }
    
    func finishUserUpdates() {
        userFocus.finishUpdates()
    }
    
    func resetUserBounds() {
        userFocus.finishUpdates()
    }
    
    func userLayout(_ receiver: (CodeGridUserFocusController, FocusBox) -> Void) {
        receiver(self, userFocus)
        finishUserUpdates()
    }
    
    func userResize(_ receiver: (CodeGridUserFocusController, FocusBox) -> Void) {
        receiver(self, userFocus)
        resetUserBounds()
    }
    
    func makeNewUserFocusBox() -> FocusBox {
        let newFocus = focusCache.cacheNewFocus()
        newFocus.layoutMode = .userStack
        
        let placementNode = userFocusPlacementNode
        placementNode.addingChild(newFocus.rootNode)
        
        codePageController.codeGridParser.editorWrapper.doInWorld { camera, rootNode in
            placementNode.addConstraint(makeCameraConstraint(camera))
            camera.addChildNode(placementNode)
        }
        
        return newFocus
    }
}

#if os(macOS)
private extension CodeGridUserFocusController {
    func makeCameraConstraint(_ camera: SCNNode) -> SCNConstraint {
        let depth = Float(128)
        let dZ = CGFloat(-1.0 * depth)
        
        let position = SCNTransformConstraint(
            inWorldSpace: true,
            with: { node, currentTransform in
                return SCNMatrix4Translate(
                    camera.transform,
                    0.0,
                    0.0,
                    dZ
                )
            }
        )
        
        return position
    }
}

#elseif os(iOS)
private extension CodeGridUserFocusController {
    func makeCameraConstraint(_ camera: SCNNode) -> SCNConstraint {
        let depth = VectorFloat(0.2)
        
        let position = SCNTransformConstraint(
            inWorldSpace: true,
            with: { node, currentTransform in
                node.simdPosition = camera.simdWorldPosition
                node.simdPosition += camera.simdWorldFront * depth
                node.simdOrientation = camera.simdOrientation
                return node.transform
            }
        )
        
        return position
    }
}
#endif
