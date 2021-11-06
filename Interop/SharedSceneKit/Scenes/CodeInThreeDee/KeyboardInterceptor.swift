//
//  KeyboardCameraController.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/4/21.
//

import Foundation
import SceneKit

typealias FileOperationReceiver = (FileOperation) -> Void
enum FileOperation {
    case openDirectory
}


class KeyboardInterceptor {
    
    private let lockingKeyCache: DirectionLock
    private let movementQueue = DispatchQueue(label: "KeyboardCamera", qos: .userInteractive)
    private var movementDirections: Set<SelfRelativeDirection> = []
    private var running: Bool = false
    
    private var defaultMovementSpeed: Int = 2
    private let updateDeltaMillis = 16
    
    var targetCameraNode: SCNNode
    var onNewFileOperation: FileOperationReceiver?
    
    init(targetCameraNode: SCNNode,
        onNewFileOperation: FileOperationReceiver? = nil) {
        self.targetCameraNode = targetCameraNode
        self.onNewFileOperation = onNewFileOperation
        self.lockingKeyCache = DirectionLock()
    }
    
    private var dispatchTimeNext: DispatchTime {
        let next = DispatchTime.now() + .milliseconds(updateDeltaMillis)
        return next
    }
    
    func onNewKeyEvent(_ event: NSEvent) {
        switch (event.type, event.characters) {
        case (.keyDown, .some(let characters)):
            switch characters {
            case "w", "W": startMovement(.forward(defaultMovementSpeed))
            case "s", "S": startMovement(.backward(defaultMovementSpeed))
            case "a", "A": startMovement(.left(defaultMovementSpeed))
            case "d", "D": startMovement(.right(defaultMovementSpeed))
            case "j", "J": startMovement(.down(defaultMovementSpeed))
            case "k", "K": startMovement(.up(defaultMovementSpeed))
            case "o" where event.modifierFlags.contains(.command):
                onNewFileOperation?(.openDirectory)
                break
            default: break
            }
        case (.keyUp, .some(let characters)):
            switch characters {
            case "w", "W": stopMovement(.forward(defaultMovementSpeed))
            case "s", "S": stopMovement(.backward(defaultMovementSpeed))
            case "a", "A": stopMovement(.left(defaultMovementSpeed))
            case "d", "D": stopMovement(.right(defaultMovementSpeed))
            case "j", "J": stopMovement(.down(defaultMovementSpeed))
            case "k", "K": stopMovement(.up(defaultMovementSpeed))
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
            final.x += direction.relativeVelocity * 0.8
            
        case .up, .down:
            final.y += direction.relativeVelocity * 0.8
        }
        
        targetCameraNode.position = final
    }
}

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

private class DirectionLock: LockingCache<SelfRelativeDirection, SelfRelativeDirection> {
    override func make(_ key: Key, _ store: inout [Key: Value]) -> SelfRelativeDirection {
        return key
    }
}
