//
//  KeyboardCameraController.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/4/21.
//

import Foundation
import SceneKit

class KeyboardCameraControls {
    enum SelfRelativeDirection: Hashable {
        case forward(_ velocity: Int)
        case backward(_ velocity: Int)
        case left(_ velocity: Int)
        case right(_ velocity: Int)
        case up(_ velocity: Int)
        case down(_ velocity: Int)
        
        var relativeVelocity: VectorFloat {
            switch self {
            case let .left(velocity),
                let .down(velocity),
                let .forward(velocity):
                return -VectorFloat(velocity)
                
            case let .backward(velocity),
                let .right(velocity),
                let .up(velocity):
                return VectorFloat(velocity)
            }
        }
        
        var key: String {
            switch self {
            case .forward: return "forward"
            case .backward: return "backward"
            case .left: return "left"
            case .right: return "right"
            case .up: return "up"
            case .down: return "down"
            }
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(key)
        }
    }
    
    private let movementQueue = DispatchQueue(label: "KeyboardCamera", qos: .userInteractive)
    private var movementDirections: Set<SelfRelativeDirection> = []
    private var running: Bool = false
    
    private var defaultMovementSpeed: Int = 2
    private let updateDeltaMillis = 33
    
    private var dispatchTimeNext: DispatchTime {
        let next = DispatchTime.now() + .milliseconds(updateDeltaMillis)
        return next
        
    }
    private let lockingKeyCache: DirectionLock
    
    private class DirectionLock: LockingCache<SelfRelativeDirection, SelfRelativeDirection> {
        override func make(_ key: Key, _ store: inout [Key: Value]) -> SelfRelativeDirection {
            return key
        }
    }
    
    var targetCameraNode: SCNNode
    
    init(targetCameraNode: SCNNode) {
        self.targetCameraNode = targetCameraNode
        self.lockingKeyCache = DirectionLock()
    }
    
    func onNewKeyEvent(_ event: NSEvent) {
        switch (event.type, event.characters) {
        case (.keyDown, .some(let characters)):
            switch characters {
            case "w", "W": startMovement(.forward(defaultMovementSpeed))
            case "s", "S": startMovement(.backward(defaultMovementSpeed))
            case "a", "A": startMovement(.left(defaultMovementSpeed))
            case "d", "D": startMovement(.right(defaultMovementSpeed))
            default: break
            }
        case (.keyUp, .some(let characters)):
            switch characters {
            case "w", "W": stopMovement(.forward(defaultMovementSpeed))
            case "s", "S": stopMovement(.backward(defaultMovementSpeed))
            case "a", "A": stopMovement(.left(defaultMovementSpeed))
            case "d", "D": stopMovement(.right(defaultMovementSpeed))
            default: break
            }
        default:
            break
        }
    }
    
    private func startMovement(_ direction: SelfRelativeDirection) {
        guard !lockingKeyCache.contains(direction) else { return }
        print("start", direction)
        lockingKeyCache[direction] = direction
        guard !running else { return }
        enqueueRunLoop()
    }
    
    private func stopMovement(_ direction: SelfRelativeDirection) {
        guard lockingKeyCache.contains(direction) else { return }
        print("stop", direction)
        lockingKeyCache.remove(direction)
        guard !running else { return }
        enqueueRunLoop()
    }
    
    private func enqueueRunLoop() {
        self.running = true
        movementQueue.async() {
//            sceneTransaction {
//                self.lockingKeyCache.doOnEach { direction, _ in
//                    print(direction)
//                    self.doDirectionDelta(direction)
//                }
//            }
            
            DispatchQueue.main.async {
                self.lockingKeyCache.doOnEach { direction, _ in
                    print(direction)
                    self.doDirectionDelta(direction)
                }
            }

            guard !self.lockingKeyCache.isEmpty() else {
                self.running = false
                return
            }
            
            self.movementQueue.asyncAfter(deadline: self.dispatchTimeNext) {
                self.enqueueRunLoop()
            }
        }
    }
    
    private func doDirectionDelta(_ direction: SelfRelativeDirection) {
        var final = targetCameraNode.position.translated()
        
        switch direction {
        case .forward, .backward:
            final.z += direction.relativeVelocity * 0.8
            
        case .left, .right:
            final.x += direction.relativeVelocity
            
        case .up, .down:
            final.y += direction.relativeVelocity
        }
        
        targetCameraNode.position = final
    }
}
