import SceneKit
import Foundation
import Combine
import SwiftUI

class HoverClones: LockingCache<SCNNode, SCNNode> {
    override func make(_ key: SCNNode, _ store: inout [SCNNode : SCNNode]) -> SCNNode {
        let newClone = key.clone()
        newClone.geometry = key.geometry?.deepCopy()
        return newClone
    }
}

class TokenHoverInteractionTracker {
	typealias Key = SCNNode
	
	var currentHoveredSet: Set<Key> = []
    private var hoverClones = HoverClones()
    
    lazy var onFocused: (Key, Key) -> Void = self.defaultFocusNode
    lazy var onUnfocused: (Key, Key) -> Void = self.defaultUnfocusNode
    
    func clearCurrent() {
        hoverClones.doOnEach { _, clone in clone.removeFromParentNode() }
        currentHoveredSet.removeAll()
    }
    
    func diff(_ results: Set<Key>) -> (Set<Key>, Set<Key>) {
        let newlyHovered = results.subtracting(currentHoveredSet)
        let toRemove = currentHoveredSet.subtracting(results)
        return (newlyHovered, toRemove)
    }
	
    func newSetHovered(_ results: Set<Key>, inTransaction: Bool = true) {
		let newlyHovered = results.subtracting(currentHoveredSet)
		let toRemove = currentHoveredSet.subtracting(results)
		
		if inTransaction {
            sceneTransaction {
                // you can get a fun hover effect by moving each node in a transaction;
                // sorta a matrix fly-in as each transaction completes.
                newlyHovered.forEach { focusNode($0) }
                toRemove.forEach { unfocusNode($0) }
            }
        } else {
            newlyHovered.forEach { focusNode($0) }
            toRemove.forEach { unfocusNode($0) }
        }
	}
    
    func cacheNode(_ result: Key) {
        _ = hoverClones[result]
    }
	
	func focusNode(_ result: Key) {
		guard !currentHoveredSet.contains(result) else { return }
		currentHoveredSet.insert(result)
        
        let safeClone = hoverClones[result]
        onFocused(result, safeClone)
	}
	
	func unfocusNode(_ result: Key) {
		guard currentHoveredSet.contains(result) else { return }
		currentHoveredSet.remove(result)
        
        let safeClone = hoverClones[result]
        onUnfocused(result, safeClone)
	}
    
    private func defaultFocusNode(_ source: Key, _ safeClone: Key) {
        safeClone.position.z += 5.0
        safeClone.geometry?.firstMaterial?.multiply.contents = NSUIColor.red
    }
    
    private func defaultUnfocusNode(_ source: Key, _ safeClone: Key) {
        safeClone.position.z -= 5.0
        safeClone.geometry?.firstMaterial?.multiply.contents = NSUIColor.white
    }
}
