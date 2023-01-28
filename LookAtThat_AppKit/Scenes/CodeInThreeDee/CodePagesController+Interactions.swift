import SceneKit
import Foundation
import Combine

extension CodePagesController {
    func newScrollEvent(_ event: NSEvent) {
        sceneTransaction(0) {
            let sensitivity = CGFloat(1.5)
            let scaledX = -event.deltaX * sensitivity
            let scaledY = event.deltaY * sensitivity
            if event.modifierFlags.contains(.command) {
                let translate = SCNMatrix4MakeTranslation(scaledX, scaledY, 0)
                sceneCameraNode.transform = SCNMatrix4Mult(translate, sceneCameraNode.transform)
            } else {
                let translate = SCNMatrix4MakeTranslation(scaledX, 0, scaledY)
                sceneCameraNode.transform = SCNMatrix4Mult(translate, sceneCameraNode.transform)
            }
        }
    }

    func newMousePosition(_ point: CGPoint) {
//        let hoverTranslationY = CGFloat(50)
//
//        let newMouseHoverSheet =
//            self.sceneView.hitTestCodeSheet(with: point).first?.node.parent
//
//        let currentHoveredSheet =
//            touchState.mouse.currentHoveredSheet
//
//        if currentHoveredSheet == nil, let newSheet = newMouseHoverSheet {
//            touchState.mouse.currentHoveredSheet = newSheet
//            sceneTransaction {
//                newSheet.position.y += hoverTranslationY
//            }
//        } else if let currentSheet = currentHoveredSheet, currentSheet != newMouseHoverSheet {
//            touchState.mouse.currentHoveredSheet = newMouseHoverSheet
//            sceneTransaction {
//                currentSheet.position.y -= hoverTranslationY
//                newMouseHoverSheet?.position.y += hoverTranslationY
//            }
//        }
    }
}
