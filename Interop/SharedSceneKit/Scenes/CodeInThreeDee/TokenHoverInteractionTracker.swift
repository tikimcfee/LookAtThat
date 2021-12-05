import SceneKit
import Foundation
import Combine
import SwiftUI

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
        result.geometry = result.geometry?.deepCopy()
        result.geometry?.firstMaterial?.multiply.contents = NSUIColor.red
//        result.simdScale += result.simdWorldRight * 1.2
//        result.simdScale += result.simdWorldUp * 1.2
	}
	
	private func unfocusNode(_ result: Key) {
		guard currentHoveredSet.contains(result) else { return }
		currentHoveredSet.remove(result)
		
		result.position.z -= 5.0
        result.geometry?.firstMaterial?.multiply.contents = NSUIColor.white
//        result.geometry?.firstMaterial?.multiply.contents = NSUIColor(displayP3Red: 0.2, green: 0.2, blue: 0.2, alpha: 0.8)
//        result.simdScale -= result.simdWorldRight * 1.2
//        result.simdScale -= result.simdWorldUp * 1.2
	}
}
