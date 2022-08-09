//
//  KeyboardCameraController.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/4/21.
//

import Foundation
import SceneKit

private var default_MovementSpeed: VectorFloat = 2
private var default_ModifiedMovementSpeed: VectorFloat = 20
private let default_UpdateDeltaMillis = 16

typealias FileOperationReceiver = (FileOperation) -> Void
enum FileOperation {
    case openDirectory
}

typealias FocusChangeReceiver = (SelfRelativeDirection) -> Void

class KeyboardInterceptor {

    private let movementQueue = DispatchQueue(label: "KeyboardCamera", qos: .userInteractive)
    private var directionCache: Set<SelfRelativeDirection>
    
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
        self.directionCache = []
    }
    
    private var dispatchTimeNext: DispatchTime {
        let next = DispatchTime.now() + .milliseconds(default_UpdateDeltaMillis)
        return next
    }
    
    func onNewKeyEvent(_ event: NSEvent) {
        movementQueue.async {
            self.enqueuedKeyConsume(event)
        }
    }
    
    private func enqueueRunLoop() {
        guard !running else { return }
        running = true
        runLoopImplementation()
    }
    
    private func runLoopImplementation() {
        guard !directionCache.isEmpty else {
            running = false
            return
        }
        
        let finalDelta = currentModifiers.contains(.shift)
            ? default_ModifiedMovementSpeed
            : default_MovementSpeed
        
        directionCache.forEach { direction in
//            print("--> \(direction)")
            doDirectionDelta(direction, finalDelta)
        }
        
        movementQueue.asyncAfter(deadline: dispatchTimeNext) {
            self.runLoopImplementation()
        }
    }
    
    private func startMovement(_ direction: SelfRelativeDirection) {
        guard !directionCache.contains(direction) else { return }
        print("start", direction)
        directionCache.insert(direction)
        enqueueRunLoop()
    }
    
    private func stopMovement(_ direction: SelfRelativeDirection) {
        print("stop", direction)
        directionCache.remove(direction)
        enqueueRunLoop()
    }
}

private extension KeyboardInterceptor {
    func doDirectionDelta(
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
            sceneTransaction(0.0835, .easeOut) {
                update()
            }
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
        default:
            onFlagsChanged(event.modifierFlags, event)
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
        case "a", "A": stopMovement(.left)
        case "d", "D": stopMovement(.right)
        case "w", "W": stopMovement(.forward)
        case "s", "S": stopMovement(.backward)
        case "z", "Z": stopMovement(.down)
        case "x", "X": stopMovement(.up)
        default:
            break
        }
    }
    
    private func onFlagsChanged(_ flags: NSEvent.ModifierFlags, _ event: NSEvent) {
        self.currentModifiers = flags
        self.enqueueRunLoop()
    }
    
    private func changeFocus(_ focusDirection: SelfRelativeDirection) {
        onNewFocusChange?(focusDirection)
    }
}
