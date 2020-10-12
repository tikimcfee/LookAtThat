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

    func newMouseDown(_ event: NSEvent) {
        var safePoint: CGPoint?
        DispatchQueue.main.sync {
            safePoint = sceneView.convert(event.locationInWindow, to: nil)
        }
        guard let point = safePoint else { return }

        guard let clickedSheet = sceneView.hitTestCodeSheet(
            with: point, .all, .rootCodeSheet
        ).first?.node.parent else { return }

        let maybeSheet = syntaxNodeParser.allRootContainerNodes[clickedSheet]
        print("Clicked \(maybeSheet?.id ?? "<nothing, no sheet found>")")
        touchState.mouse.currentClickedSheet = maybeSheet
        codeSheetSelected(maybeSheet)
    }

    func newMousePosition(_ point: CGPoint) {
        let hoverTranslationY = CGFloat(50)

        let newHitTestedSheet = sceneView.hitTestCodeSheet(
            with: point, .all, .rootCodeSheet
        ).first?.node.parent

        sceneTransaction {
            let lastSheet = touchState.mouse.currentHoveredSheet
            if lastSheet != newHitTestedSheet {
                lastSheet?.position.y -= hoverTranslationY
                newHitTestedSheet?.position.y += hoverTranslationY
            }
        }
        touchState.mouse.currentHoveredSheet = newHitTestedSheet

    }

    func codeSheetSelected(_ sheet: CodeSheet?) {
        
    }
    #endif
}
