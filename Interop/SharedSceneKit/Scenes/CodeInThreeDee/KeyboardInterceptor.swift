//
//  KeyboardCameraController.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/4/21.
//

import Foundation
import SceneKit

private var default_MovementSpeed: Int = 2
private var default_ModifiedMovementSpeed: Int = Int(ceil(Double(default_MovementSpeed) * 2.5))
private let default_UpdateDeltaMillis = 16

typealias FileOperationReceiver = (FileOperation) -> Void
enum FileOperation {
    case openDirectory
}

class KeyboardInterceptor {
    
//    private let lockingKeyCache: DirectionLock
    private let movementQueue = DispatchQueue(label: "KeyboardCamera", qos: .userInteractive)
    private let cacheQueue = DispatchQueue(label: "KeyboardCamera-Cache", qos: .userInteractive)
    private var _directionCache: Set<SelfRelativeDirection>
    
    private var movementDirections: Set<SelfRelativeDirection> = []
    private var running: Bool = false
    
    var targetCameraNode: SCNNode
    var onNewFileOperation: FileOperationReceiver?
    
    init(targetCameraNode: SCNNode,
        onNewFileOperation: FileOperationReceiver? = nil) {
        self.targetCameraNode = targetCameraNode
        self.onNewFileOperation = onNewFileOperation
        self._directionCache = []
    }
    
    private var dispatchTimeNext: DispatchTime {
        let next = DispatchTime.now() + .milliseconds(default_UpdateDeltaMillis)
        return next
    }
    
    private func synchronizedDirectionCache(_ receiver: (inout Set<SelfRelativeDirection>) -> Void) {
        cacheQueue.sync { receiver(&_directionCache) }
    }
    
    func onNewKeyEvent(_ event: NSEvent) {
        movementQueue.async {
            self.enqueuedKeyConsume(event)
        }
    }
    
    private func startMovement(_ direction: SelfRelativeDirection) {
        synchronizedDirectionCache { lockingKeyCache in
            guard !lockingKeyCache.contains(direction) else { return }
            
            print("start", direction)
            lockingKeyCache.insert(direction)
            
            guard !running else { return }
            enqueueRunLoop()
        }
    }
    
    private func stopMovement(_ direction: SelfRelativeDirection) {
        synchronizedDirectionCache { lockingKeyCache in
            guard lockingKeyCache.contains(direction) else { return }
            
            print("stop", direction)
            lockingKeyCache.remove(direction)
            
            guard !running else { return }
            enqueueRunLoop()
        }
        
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
            self.synchronizedDirectionCache { lockingKeyCache in
                lockingKeyCache.forEach { direction in
//                    print(direction)
                    self.doDirectionDelta(direction)
                }
                
                guard !lockingKeyCache.isEmpty else {
                    self.running = false
                    return
                }
                
                self.movementQueue.asyncAfter(deadline: self.dispatchTimeNext) {
                    self.enqueueRunLoop()
                }       
            }
        }
    }
    
    private func doDirectionDelta(_ direction: SelfRelativeDirection) {
        var finalGet: SCNVector3 {
            var final = targetCameraNode.position.translated()
            
            switch direction {
            case .forward, .backward, .forwardModified, .backwardModified:
                final.z += direction.relativeVelocity * 0.8
                
            case .left, .right, .leftModified, .rightModified:
                final.x += direction.relativeVelocity * 0.8
                
            case .up, .down, .upModified, .downModified:
                final.y += direction.relativeVelocity * 0.8
            }
            
            return final
        }
        DispatchQueue.main.async {
            self.targetCameraNode.position = finalGet
        }
    }
}

enum SelfRelativeDirection: Hashable {
    case forward(_ velocity: Int)
    case forwardModified(_ velocity: Int)
    
    case backward(_ velocity: Int)
    case backwardModified(_ velocity: Int)
    
    case left(_ velocity: Int)
    case leftModified(_ velocity: Int)
    
    case right(_ velocity: Int)
    case rightModified(_ velocity: Int)
    
    case up(_ velocity: Int)
    case upModified(_ velocity: Int)
    
    case down(_ velocity: Int)
    case downModified(_ velocity: Int)
    
    var relativeVelocity: VectorFloat {
        switch self {
        case let .left(velocity), let .leftModified(velocity),
            let .down(velocity), let .downModified(velocity),
            let .forward(velocity), let .forwardModified(velocity):
            return -VectorFloat(velocity)
            
        case let .backward(velocity), let .backwardModified(velocity),
            let .right(velocity), let .rightModified(velocity),
            let .up(velocity), let .upModified(velocity):
            return VectorFloat(velocity)
        }
    }
}

private class DirectionLock: LockingCache<SelfRelativeDirection, SelfRelativeDirection> {
    override func make(_ key: Key, _ store: inout [Key: Value]) -> SelfRelativeDirection {
        return key
    }
}


private extension KeyboardInterceptor {
    func enqueuedKeyConsume(_ event: NSEvent) {
        switch (event.type) {
        
            
            // vvvv Key down
        case (.keyDown) where !event.modifierFlags.contains(.shift) && !event.isARepeat:
            let characters = event.characters
            switch characters {
            case "w", "W": startMovement(.forward(default_MovementSpeed))
            case "s", "S": startMovement(.backward(default_MovementSpeed))
            case "a", "A": startMovement(.left(default_MovementSpeed))
            case "d", "D": startMovement(.right(default_MovementSpeed))
            case "j", "J": startMovement(.down(default_MovementSpeed))
            case "k", "K": startMovement(.up(default_MovementSpeed))
            case "o" where event.modifierFlags.contains(.command):
                onNewFileOperation?(.openDirectory)
            default: break
            }
            
        case (.keyDown) where event.modifierFlags.contains(.shift) && !event.isARepeat:
            let characters = event.characters
            switch characters {
            case "w", "W": startMovement(.forwardModified(modifiedSpeed(event)))
            case "s", "S": startMovement(.backwardModified(modifiedSpeed(event)))
            case "a", "A": startMovement(.leftModified(modifiedSpeed(event)))
            case "d", "D": startMovement(.rightModified(modifiedSpeed(event)))
            case "j", "J": startMovement(.downModified(modifiedSpeed(event)))
            case "k", "K": startMovement(.upModified(modifiedSpeed(event)))
            case "o" where event.modifierFlags.contains(.command):
                onNewFileOperation?(.openDirectory)
            default: break
            }
            
            // ^^^^ Key up
        case (.keyUp) where !event.isARepeat:
            let characters = event.characters
            switch characters {
            case "w", "W":
                stopMovement(.forwardModified(modifiedSpeed(event)))
                stopMovement(.forward(modifiedSpeed(event)))
            case "s", "S":
                stopMovement(.backwardModified(modifiedSpeed(event)))
                stopMovement(.backward(modifiedSpeed(event)))
            case "a", "A":
                stopMovement(.leftModified(modifiedSpeed(event)))
                stopMovement(.left(modifiedSpeed(event)))
            case "d", "D":
                stopMovement(.rightModified(modifiedSpeed(event)))
                stopMovement(.right(modifiedSpeed(event)))
            case "j", "J":
                stopMovement(.downModified(modifiedSpeed(event)))
                stopMovement(.down(modifiedSpeed(event)))
            case "k", "K":
                stopMovement(.upModified(modifiedSpeed(event)))
                stopMovement(.up(modifiedSpeed(event)))
            default:
                break
            }
            
        case (.flagsChanged):
            
            stopMovement(.forwardModified(modifiedSpeed(event)))
            stopMovement(.backwardModified(modifiedSpeed(event)))
            stopMovement(.leftModified(modifiedSpeed(event)))
            stopMovement(.rightModified(modifiedSpeed(event)))
            stopMovement(.downModified(modifiedSpeed(event)))
            stopMovement(.upModified(modifiedSpeed(event)))
            
        default:
//            print(event)
            break
        }
        
    }
    
    func modifiedSpeed(_ event: NSEvent) -> Int {
        switch (
            event.modifierFlags.contains(.shift),
            event.modifierFlags.contains(.command)
        ) {
        case (true, _):
            return default_ModifiedMovementSpeed
        case (false, _):
            return default_MovementSpeed
        }
    }
}
