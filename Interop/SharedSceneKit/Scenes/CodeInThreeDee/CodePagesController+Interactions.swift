import SceneKit
import Foundation
import Combine
import SwiftUI

extension CodePagesController {
    #if os(OSX)
    func newScrollEvent(_ event: NSEvent) {
        
        let sensitivity = CGFloat(1.5)
        let scaledX = -event.deltaX * sensitivity
        let scaledY = event.deltaY * sensitivity
        
        moveCamera(scaledX: scaledX, scaledY: scaledY, event)
    }
    
    private func moveCamera(scaledX: CGFloat, scaledY: CGFloat, _ event: NSEvent? = nil) {
        let translation: SCNMatrix4
        let targetNode: SCNNode
        if let hoveredSheet = touchState.mouse.currentHoveredSheet,
           event?.modifierFlags.contains(.control) == true {
            translation = SCNMatrix4MakeTranslation(scaledX, 0, scaledY)
            targetNode = hoveredSheet
        }
//        else if event?.modifierFlags.contains(.command) == true {
        else if event?.modifierFlags.contains(.shift) == true {
            translation = SCNMatrix4MakeTranslation(scaledX, 0, scaledY)
            targetNode = sceneCameraNode
        } else {
            translation = SCNMatrix4MakeTranslation(scaledX, scaledY, 0)
            targetNode = sceneCameraNode
        }
        
        sceneTransaction(0) {
            let translate4x4 = simd_float4x4(translation)
            let target4x4 = simd_float4x4(targetNode.transform)
            let multiplied = simd_mul(translate4x4, target4x4)
            targetNode.simdTransform = multiplied
            //            targetNode.transform = SCNMatrix4Mult(translation, targetNode.transform)
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

        let maybeSheet = codeSheetParser.codeSheetVisitor.allRootContainerNodes[clickedSheet]
        print("Clicked \(maybeSheet?.id ?? "<nothing, no sheet found>")")
        touchState.mouse.currentClickedSheet = maybeSheet
        codeSheetSelected(maybeSheet)
    }
    
    func newKeyEvent(_ event: NSEvent) {
        keyboardInterceptor.onNewKeyEvent(event)
    }
	
    func newMousePosition(_ point: CGPoint) {
		// this should be a single walk with a switch that handles the node each time. this is slow otherwise, lots of
		// O(M * N) operations on each position update which is Woof.
		doCodeGridHover(point)		
	}
	
	private func doCodeGridHover(_ point: CGPoint) {
		let grids = sceneView.hitTest(location: point, .codeGridToken)
		
		guard let firstHoveredGrid = grids.first,
			  let codeGridIdFromNode = firstHoveredGrid.node.name
		else { return }
		
		let nodeSet = codeGridParser.tokenCache[codeGridIdFromNode]
		touchState.mouse.hoverTracker.newSetHovered(nodeSet)
		hoveredToken = codeGridIdFromNode
	}

    func codeSheetSelected(_ sheet: CodeSheet?) {
        main.async {
            self.selectedSheet = sheet
        }
    }
    #endif
}
 
class TokenHoverInteractionTracker {
	typealias Key = SCNNode
	
	var currentHoveredSet: Set<Key> = []
	
	func newSetHovered(_ results: Set<Key>) {
		let newlyHovered = results.subtracting(currentHoveredSet)
		let toRemove = currentHoveredSet.subtracting(results)
		
		// you can get a fun hover effect by moving each node in a transaction;
		// sorta a matrix fly-in as each transaction completes.
		sceneTransaction {
			newlyHovered.forEach { focusNode($0) }
			toRemove.forEach { unfocusNode($0) }
		}
	}
	
	private func focusNode(_ result: Key) {
		guard !currentHoveredSet.contains(result) else { return }
		currentHoveredSet.insert(result)
		
		result.position.z += 5.0
	}
	
	private func unfocusNode(_ result: Key) {
		guard currentHoveredSet.contains(result) else { return }
		currentHoveredSet.remove(result)
		
		result.position.z -= 5.0
	}
}
