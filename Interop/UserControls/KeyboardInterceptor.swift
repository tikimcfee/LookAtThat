//
//  KeyboardCameraController.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 11/4/21.
//

import SceneKit
import Combine

let default_MovementSpeed: VectorFloat = 500
let default_ModifiedMovementSpeed: VectorFloat = 1000
private let default_UpdateDeltaMillis = 16

typealias FileOperationReceiver = (FileOperation) -> Void
enum FileOperation {
    case openDirectory
}

typealias FocusChangeReceiver = (SelfRelativeDirection) -> Void

extension KeyboardInterceptor {
    class State: ObservableObject {
        @Published var directions: Set<SelfRelativeDirection> = []
#if os(iOS)
        @Published var currentModifiers: OSEvent.ModifierFlags = OSEvent.ModifierFlags.none
#else
        @Published var currentModifiers: OSEvent.ModifierFlags = OSEvent.ModifierFlags()
#endif
        
        // TODO: Track all focus directions and provide a trail?
        @Published var focusPath: [SelfRelativeDirection] = []
    }
    
    class Positions: ObservableObject {
        @Published var totalOffset: LFloat3 = .zero
        @Published var travelOffset: LFloat3 = .zero
        @Published var rotationOffset: LFloat3 = .zero
        @Published var rotationDelta: LFloat3 = .zero
        
        func reset() {
            totalOffset = .zero
            travelOffset = .zero
            rotationOffset = .zero
            rotationDelta = .zero
        }
    }
}

protocol KeyboardPositionSource {
    var worldUp: LFloat3 { get }
    var worldRight: LFloat3 { get }
    var worldFront: LFloat3 { get }
    var rotation: LFloat3 { get }
}

extension KeyboardInterceptor {
    struct CameraTarget: KeyboardPositionSource {
        var targetCamera: MetalLinkCamera
        var bag = Set<AnyCancellable>()

        var worldUp: LFloat3 { targetCamera.worldUp }
        var worldRight: LFloat3 { targetCamera.worldRight }
        var worldFront: LFloat3 { targetCamera.worldFront }
        var current: LFloat3 { targetCamera.position }
        var rotation: LFloat3 { targetCamera.rotation }
        
        init(targetCamera: MetalLinkCamera,
             interceptor: KeyboardInterceptor
        ) {
            self.targetCamera = targetCamera
            
            interceptor.positions.$travelOffset.sink { offset in
                targetCamera.position += offset
            }.store(in: &bag)
        }
    }
}

class KeyboardInterceptor {

    private let movementQueue = DispatchQueue(label: "KeyboardCamera", qos: .userInteractive)
    
    private(set) var state = State()
    private(set) var positions = Positions()
    private(set) var running: Bool = false
    
    var onNewFileOperation: FileOperationReceiver?
    var onNewFocusChange: FocusChangeReceiver?
    var positionSource: KeyboardPositionSource?
    
    private var dispatchTimeNext: DispatchTime {
        let next = DispatchTime.now() + .milliseconds(default_UpdateDeltaMillis)
        return next
    }
    
    init(onNewFileOperation: FileOperationReceiver? = nil) {
        self.onNewFileOperation = onNewFileOperation
    }
    
    func resetPositions() {
        positions.reset()
    }
    
    func onNewKeyEvent(_ event: OSEvent) {
        movementQueue.sync {
            self.enqueuedKeyConsume(event)
        }
    }
    
    private func enqueueRunLoop() {
        guard !running else { return }
        running = true
        runLoopImplementation()
    }
    
    private func runLoopImplementation() {
        guard !state.directions.isEmpty else {
            running = false
            return
        }
        
        let finalDelta = state.currentModifiers.contains(.shift)
            ? default_ModifiedMovementSpeed
            : default_MovementSpeed
        
        state.directions.forEach { direction in
            doDirectionDelta(direction, finalDelta)
        }
        
        movementQueue.asyncAfter(deadline: dispatchTimeNext) {
            self.runLoopImplementation()
        }
    }
    
    private func startMovement(_ direction: SelfRelativeDirection) {
        guard !state.directions.contains(direction) else { return }
        print("start", direction)
        state.directions.insert(direction)
        enqueueRunLoop()
    }
    
    private func stopMovement(_ direction: SelfRelativeDirection) {
        print("stop", direction)
        state.directions.remove(direction)
        enqueueRunLoop()
    }
}

private extension KeyboardInterceptor {
    func doDirectionDelta(
        _ direction: SelfRelativeDirection,
        _ finalDelta: VectorFloat
    ) {
        weak var weakSelf = self
        
        DispatchQueue.main.async {
            doDelta()
        }
        
        func doDelta() {
            guard let self = weakSelf else { return }
            guard let source = self.positionSource else { return }
            
            var positionOffset: LFloat3 = .zero
            var rotationOffset: LFloat3 = .zero
            
            switch direction {
            case .forward:
                positionOffset = source.worldFront * Float(finalDelta)
            case .backward:
                positionOffset = source.worldFront * -Float(finalDelta)
                
            case .right:
                positionOffset = source.worldRight * Float(finalDelta)
            case .left:
                positionOffset = source.worldRight * -Float(finalDelta)
                
            case .up:
                positionOffset = source.worldUp * Float(finalDelta)
            case .down:
                positionOffset = source.worldUp * -Float(finalDelta)
                
            case .yawLeft:
                rotationOffset = LFloat3(0, -5, 0)
            case .yawRight:
                rotationOffset = LFloat3(0, 5, 0)
            }
            
            positions.totalOffset += positionOffset
            positions.travelOffset = positionOffset
            positions.rotationOffset += rotationOffset
            positions.rotationDelta = rotationOffset
        }
    }
}

#if os(iOS)
extension OSEvent {
    class ModifierFlags: Equatable {
        static let none = ModifierFlags(-1)
        static let shift = ModifierFlags(0)
        static let command = ModifierFlags(1)
        static let options = ModifierFlags(2)
        let id: Int
        private init(_ id: Int) { self.id = id }
        
        static func == (lhs: UIEvent.ModifierFlags, rhs: UIEvent.ModifierFlags) -> Bool {
            return lhs.id == rhs.id
        }
        
        func contains(_ flags: ModifierFlags) -> Bool {
            id == flags.id
        }
    }
    
    static let LeftDragKeydown = OSEvent()
    static let LeftDragKeyup = OSEvent()
    
    static let RightDragKeydown = OSEvent()
    static let RightDragKeyup = OSEvent()
    
    static let DownDragKeydown = OSEvent()
    static let DownDragKeyup = OSEvent()
    
    static let UpDragKeydown = OSEvent()
    static let UpDragKeyup = OSEvent()
    
    static let InDragKeydown = OSEvent()
    static let InDragKeyup = OSEvent()
    
    static let OutDragKeydown = OSEvent()
    static let OutDragKeyup = OSEvent()
}

private extension KeyboardInterceptor {
    func enqueuedKeyConsume(_ event: OSEvent) {
        switch event {
        case .RightDragKeydown: startMovement(.right)
        case .RightDragKeyup: stopMovement(.right)
            
        case .LeftDragKeydown: startMovement(.left)
        case .LeftDragKeyup: stopMovement(.left)
            
        case .UpDragKeydown: startMovement(.down)
        case .UpDragKeyup: stopMovement(.down)
            
        case .DownDragKeydown: startMovement(.up)
        case .DownDragKeyup: stopMovement(.up)
            
        case .InDragKeydown: startMovement(.forward)
        case .InDragKeyup: stopMovement(.forward)
            
        case .OutDragKeydown: startMovement(.backward)
        case .OutDragKeyup: stopMovement(.backward)
        
        default: break
        }
    }
}
#elseif os(macOS)
private extension KeyboardInterceptor {
    
    // Accessing fields from incorrect NSEvent types is incredibly unsafe.
    //  You must check type before access, and ensure any fields are expected to be returned.
    //  E.g., `event.characters` results in an immediate fatal exception thrown if the type is NOT .keyDown or .keyUp
    // We break up the fields on type to make slightly safer assumptions in the implementation
    func enqueuedKeyConsume(_ event: OSEvent) {
        switch event.type {
        case .keyDown:
            onKeyDown(event.characters ?? "", event)
        case .keyUp:
            onKeyUp(event.characters ?? "", event)
        default:
            onFlagsChanged(event.modifierFlags, event)
        }
    }
    
    private func onKeyDown(_ characters: String, _ event: OSEvent) {
        if let moveDirection = directionForKey(characters) {
            startMovement(moveDirection)
        } else if let focusDirection = focusDirectionForKey(characters, event) {
            changeFocus(focusDirection)
        } else {
            switch characters {
                
            case "o" where event.modifierFlags.contains(.command):
                onNewFileOperation?(.openDirectory)
                
            default:
                break
            }
        }
    }
    
    private func onKeyUp(_ characters: String, _ event: OSEvent) {
        guard let direction = directionForKey(characters) else { return }
        stopMovement(direction)
    }
    
    private func onFlagsChanged(_ flags: OSEvent.ModifierFlags, _ event: OSEvent) {
        state.currentModifiers = flags
        enqueueRunLoop()
    }
    
    private func changeFocus(_ focusDirection: SelfRelativeDirection) {
        state.focusPath.append(focusDirection)
        onNewFocusChange?(focusDirection)
    }
}
#endif

func directionForKey(_ key: String) -> SelfRelativeDirection? {
    switch key {
    case "a", "A": return .left
    case "d", "D": return .right
    case "w", "W": return .forward
    case "s", "S": return .backward
    case "z", "Z": return .down
    case "x", "X": return .up
    case "q", "Q": return .yawLeft
    case "e", "E": return .yawRight
    default: return nil
    }
}

func focusDirectionForKey(_ key: String, _ event: OSEvent) -> SelfRelativeDirection? {
    switch key {
    case "h", "H": return .left
    case "l", "L": return .right
    case "j", "J": return .up
    case "k", "K": return .down
    case "n", "N": return .forward
    case "m", "M": return .backward
    #if os(macOS)
    case _ where event.specialKey == .leftArrow: return .left
    case _ where event.specialKey == .rightArrow: return .right
    case _ where event.specialKey == .upArrow && event.modifierFlags.contains(.shift): return .forward
    case _ where event.specialKey == .downArrow && event.modifierFlags.contains(.shift): return .backward
    case _ where event.specialKey == .upArrow: return .up
    case _ where event.specialKey == .downArrow: return .down
    #endif
    default: return nil
    }
}
