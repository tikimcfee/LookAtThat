//
//  KeyboardCameraController.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/4/21.
//

import Foundation
import SceneKit

private var default_MovementSpeed: VectorFloat = 2.0
private var default_ModifiedMovementSpeed: VectorFloat = default_MovementSpeed * 5.0
private let default_UpdateDeltaMillis = 16

typealias FileOperationReceiver = (FileOperation) -> Void
enum FileOperation {
    case openDirectory
}

typealias FocusChangeReceiver = (SelfRelativeDirection) -> Void

class KeyboardInterceptor {

    private let movementQueue = DispatchQueue(label: "KeyboardCamera", qos: .userInteractive)
    private let cacheQueue = DispatchQueue(label: "KeyboardCamera-Cache", qos: .userInteractive)
    private var _directionCache: Set<SelfRelativeDirection>
    
    private var movementDirections: Set<SelfRelativeDirection> = []
    private var currentModifiers: NSEvent.ModifierFlags = .init()
    private var running: Bool = false
    
    var targetCameraNode: SCNNode
    var targetCamera: SCNCamera
    var onNewFileOperation: FileOperationReceiver?
    var onNewFocusChange: FocusChangeReceiver?
    
    init(targetCamera: SCNCamera,
         targetCameraNode: SCNNode,
        onNewFileOperation: FileOperationReceiver? = nil) {
        self.targetCamera = targetCamera
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
            self.synchronizedDirectionCache { lockingKeyCache in
//                let finalDelta = self.currentModifiers.contains(.shift)
//                    ? default_ModifiedMovementSpeed
//                    : default_MovementSpeed
                let finalDelta = default_ModifiedMovementSpeed
                
                lockingKeyCache.forEach { direction in
                    self.doDirectionDelta(direction, finalDelta)
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
    
    private func doDirectionDelta(
        _ direction: SelfRelativeDirection,
        _ finalDelta: VectorFloat
    ) {
        func update() {
            switch direction {
            case .forward:
                targetCameraNode.simdPosition += targetCameraNode.simdWorldFront * Float(finalDelta)
            case .backward:
                targetCameraNode.simdPosition += targetCameraNode.simdWorldFront * -Float(finalDelta)
                
            case .right:
                targetCameraNode.simdPosition += targetCameraNode.simdWorldRight * Float(finalDelta)
            case .left:
                targetCameraNode.simdPosition += targetCameraNode.simdWorldRight * -Float(finalDelta)
                
            case .up:
                targetCameraNode.simdPosition += targetCameraNode.simdWorldUp * Float(finalDelta)
            case .down:
                targetCameraNode.simdPosition += targetCameraNode.simdWorldUp * -Float(finalDelta)
            }
        }
        
        DispatchQueue.main.async {
            update()
        }
    }
}

private extension KeyboardInterceptor {
    
    // Accessing fields from incorrect NSEvent types is incredibly unsafe.
    //  You must check type before access, and ensure any fields are expected to be returned.
    //  E.g., `event.characters` results in an immediate fatal exception thrown if the type is NOT .keyDown or .keyUp
    // We break up the fields on type to make slightly safer assumptions in the implementation
    func enqueuedKeyConsume(_ event: NSEvent) {
        switch event.type {
        case .keyDown:
            onKeyDown(event.characters ?? "", event)
        case .keyUp:
            onKeyUp(event.characters ?? "", event)
//        case .flagsChanged:
//            onFlagsChanged(event.modifierFlags, event)
        default:
            break
        }
    }
    
    private func onKeyDown(_ characters: String, _ event: NSEvent) {
        switch characters {
        case "a", "A": startMovement(.left)
        case "d", "D": startMovement(.right)
        case "w", "W": startMovement(.forward)
        case "s", "S": startMovement(.backward)
        
        case "z", "Z": startMovement(.down)
        case "x", "X": startMovement(.up)
            
        case _ where event.specialKey == .leftArrow: changeFocus(.left)
        case _ where event.specialKey == .rightArrow: changeFocus(.right)
        case _ where event.specialKey == .upArrow: changeFocus(.forward)
        case _ where event.specialKey == .downArrow: changeFocus(.backward)
            
        case "h", "H": changeFocus(.left)
        case "l", "L": changeFocus(.right)
        case "j", "J": changeFocus(.forward)
        case "k", "K": changeFocus(.backward)
            
        case "n", "N": changeFocus(.up)
        case "m", "M": changeFocus(.down)
            
        case "o" where event.modifierFlags.contains(.command):
            onNewFileOperation?(.openDirectory)
            
        default:
            break
        }
    }
    
    private func onKeyUp(_ characters: String, _ event: NSEvent) {
        switch characters {
        case "w", "W": stopMovement(.forward)
        case "s", "S": stopMovement(.backward)
        case "a", "A": stopMovement(.left)
        case "d", "D": stopMovement(.right)
            
        case "z", "Z": stopMovement(.down)
        case "x", "X": stopMovement(.up)
            
        default:
            break
        }
    }
    
    private func onFlagsChanged(_ flags: NSEvent.ModifierFlags, _ event: NSEvent) {
        synchronizedDirectionCache { _ in
            currentModifiers = flags
            enqueueRunLoop()
        }
    }
    
    private func changeFocus(_ focusDirection: SelfRelativeDirection) {
        onNewFocusChange?(focusDirection)
    }
}
