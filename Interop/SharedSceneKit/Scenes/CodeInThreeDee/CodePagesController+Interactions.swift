import SceneKit
import Foundation
import Combine

extension CodePagesController {
    #if os(OSX)
    func newScrollEvent(_ event: NSEvent) {
        sceneTransaction(0) {
            let sensitivity = CGFloat(1.5)
            let scaledX = -event.deltaX * sensitivity
            let scaledY = event.deltaY * sensitivity
            let translation: SCNMatrix4
            let targetNode: SCNNode
            if let hoveredSheet = touchState.mouse.currentHoveredSheet,
               event.modifierFlags.contains(.control) {
                translation = SCNMatrix4MakeTranslation(scaledX, 0, scaledY)
                targetNode = hoveredSheet
            }
            else if event.modifierFlags.contains(.command) {
                translation = SCNMatrix4MakeTranslation(scaledX, 0, scaledY)
                targetNode = sceneCameraNode
            } else {
                translation = SCNMatrix4MakeTranslation(scaledX, scaledY, 0)
                targetNode = sceneCameraNode
            }
            targetNode.transform = SCNMatrix4Mult(translation, targetNode.transform)
        }
    }

    func newMousePosition(_ point: CGPoint) {
//        let hoverTranslationY = CGFloat(50)
//
        let hoveredSheet =
            sceneView.hitTestCodeSheet(with: point).first?.node.parent
        touchState.mouse.currentHoveredSheet = hoveredSheet

//        let currentHoveredSheet =
//            touchState.mouse.currentHoveredSheet
//
//        if currentHoveredSheet == nil, let newSheet = hoveredSheet {
//            touchState.mouse.currentHoveredSheet = newSheet
//            sceneTransaction {
//                newSheet.position.y += hoverTranslationY
//            }
//        } else if let currentSheet = currentHoveredSheet, currentSheet != hoveredSheet {
//            touchState.mouse.currentHoveredSheet = hoveredSheet
//            sceneTransaction {
//                currentSheet.position.y -= hoverTranslationY
//                hoveredSheet?.position.y += hoverTranslationY
//            }
//        }
    }
    #endif
}
