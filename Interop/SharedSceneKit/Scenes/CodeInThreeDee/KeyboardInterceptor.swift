//
//  KeyboardCameraController.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/4/21.
//

import Foundation
import SceneKit

private var defaultMovementSpeed: Int = 2
private let updateDeltaMillis = 16

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
        let next = DispatchTime.now() + .milliseconds(updateDeltaMillis)
        return next
    }
    
    private func synchronizedDirectionCache(_ receiver: (inout Set<SelfRelativeDirection>) -> Void) {
        cacheQueue.sync { receiver(&_directionCache) }
    }
    
    func onNewKeyEvent(_ event: NSEvent) {
        switch (event.type, event.characters) {
        case (.keyDown, .some(let characters)):
            switch characters {
            case "w", "W": startMovement(.forward(modifiedSpeed(event)))
            case "s", "S": startMovement(.backward(modifiedSpeed(event)))
            case "a", "A": startMovement(.left(modifiedSpeed(event)))
            case "d", "D": startMovement(.right(modifiedSpeed(event)))
            case "j", "J": startMovement(.down(modifiedSpeed(event)))
            case "k", "K": startMovement(.up(modifiedSpeed(event)))
            case "o" where event.modifierFlags.contains(.command):
                onNewFileOperation?(.openDirectory)
                break
            default: break
            }
        case (.keyUp, .some(let characters)):
            switch characters {
            case "w", "W": stopMovement(.forward(modifiedSpeed(event)))
            case "s", "S": stopMovement(.backward(modifiedSpeed(event)))
            case "a", "A": stopMovement(.left(modifiedSpeed(event)))
            case "d", "D": stopMovement(.right(modifiedSpeed(event)))
            case "j", "J": stopMovement(.down(modifiedSpeed(event)))
            case "k", "K": stopMovement(.up(modifiedSpeed(event)))
            default: break
            }
        default:
            break
        }
    }
    
    private func modifiedSpeed(_ event: NSEvent) -> Int {
        if event.modifierFlags.contains(.shift) {
            return Int(ceil(Double(defaultMovementSpeed) * 2.5))
        } else {
            return defaultMovementSpeed
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
                    print(direction)
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
        var final = targetCameraNode.position.translated()
        
        switch direction {
        case .forward, .backward:
            final.z += direction.relativeVelocity * 0.8
            
        case .left, .right:
            final.x += direction.relativeVelocity * 0.8
            
        case .up, .down:
            final.y += direction.relativeVelocity * 0.8
        }
        
        DispatchQueue.main.async {
            self.targetCameraNode.position = final
        }
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
        case .forward: return "forward\(keySuffix)"
        case .backward: return "backward\(keySuffix)"
        case .left: return "left\(keySuffix)"
        case .right: return "right\(keySuffix)"
        case .up: return "up\(keySuffix)"
        case .down: return "down\(keySuffix)"
        }
    }
    
    var keySuffix: String {
        isModifiedVelocity
            ? "-modified"
            : ""
    }
    
    var isModifiedVelocity: Bool {
        abs(relativeVelocity) != abs(VectorFloat(defaultMovementSpeed))
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
