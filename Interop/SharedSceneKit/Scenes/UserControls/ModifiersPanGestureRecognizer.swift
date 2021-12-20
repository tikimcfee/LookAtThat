import Foundation
import SceneKit
import SwiftUI

extension GestureRecognizer {
    var currentLocation: CGPoint { return location(in: view!) }
}

#if os(iOS)
extension UITapGestureRecognizer {
    var makeGestureEvent: GestureEvent {
        return GestureEvent(
            state: state.translated,
            type: .deviceTap,
            currentLocation: currentLocation,
            commandStart: nil,
            optionStart: nil
        )
    }
}

extension UIPanGestureRecognizer {
    var makePanEvent: PanEvent {
        return PanEvent(
            state: state.translated,
            currentLocation: currentLocation,
            commandStart: nil,
            optionStart: nil
        )
    }
}
extension UIPinchGestureRecognizer {
    var makeMagnificationEvent: MagnificationEvent {
        return MagnificationEvent(
            state: state.translated,
            rawMagnification: scale
        )
    }
}

extension UIGestureRecognizer.State {
    var translated: EventState? {
        switch self {
        case .began:
            return .began
        case .ended:
            return .ended
        case .changed:
            return .changed
        case .cancelled, .failed, .possible:
            return nil
        @unknown default:
            return nil
        }
    }
}
#elseif os(OSX)
extension GestureRecognizer {
    var makeTapEvent: GestureEvent {
        return GestureEvent(
            state: state.translated,
            type: .deviceTap,
            currentLocation: currentLocation,
            commandStart: nil,
            optionStart: nil,
            controlStart: nil
        )
    }
}

class ModifierStore {
    var modifierFlags = NSEvent.ModifierFlags()
    var positionsForFlagChanges = [NSEvent.ModifierFlags: CGPoint]()

    var pressingOption: Bool {
        modifierFlags.contains(.option)
    }

    var pressingCommand: Bool {
//        modifierFlags.contains(.command)
        modifierFlags.contains(.shift)
    }

    var pressingControl: Bool {
        modifierFlags.contains(.control)
    }

    func computePositions(_ currentLocation: CGPoint) {
        positionsForFlagChanges[.option] = pressingOption ? currentLocation : nil
//        positionsForFlagChanges[.command] = pressingCommand ? currentLocation : nil
        positionsForFlagChanges[.shift] = pressingCommand ? currentLocation : nil
        positionsForFlagChanges[.control] = pressingControl ? currentLocation : nil
    }
}

class ModifiersMagnificationGestureRecognizer: MagnificationGestureRecognizer {
    private var store = ModifierStore()
    var pressingOption: Bool { store.pressingOption }
    var pressingCommand: Bool { store.pressingCommand }

    override func flagsChanged(with event: NSEvent) {
        super.flagsChanged(with: event)
        store.modifierFlags = event.modifierFlags
        store.computePositions(location(in: view!))
    }

    subscript(index: NSEvent.ModifierFlags) -> CGPoint? {
        return store.positionsForFlagChanges[index]
    }

    var makeMagnificationEvent: MagnificationEvent {
        return MagnificationEvent(
            state: state.translated,
            rawMagnification: magnification
        )
    }
}

class ModifiersPanGestureRecognizer: PanGestureRecognizer {
    private var store = ModifierStore()
    var pressingOption: Bool { store.pressingOption }
    var pressingCommand: Bool { store.pressingCommand }
    var pressingControl: Bool { store.pressingControl }

    override func flagsChanged(with event: NSEvent) {
        super.flagsChanged(with: event)
        store.modifierFlags = event.modifierFlags
        store.computePositions(currentLocation)
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        store.modifierFlags = event.modifierFlags
        store.computePositions(currentLocation)
    }

    subscript(index: NSEvent.ModifierFlags) -> CGPoint? {
        return store.positionsForFlagChanges[index]
    }

    var makePanEvent: PanEvent {
        return PanEvent(
            state: state.translated,
            currentLocation: currentLocation,
//            commandStart: self[.command],
            commandStart: self[.shift],
            optionStart: self[.option],
            controlStart: self[.control]
        )
    }
}

extension NSGestureRecognizer.State {
    var translated: EventState? {
        switch self {
        case .began:
            return .began
        case .ended:
            return .ended
        case .changed:
            return .changed
        case .cancelled, .failed, .possible:
            return nil
        @unknown default:
            return nil
        }
    }
}

extension NSGestureRecognizer.State: CustomStringConvertible {
    public var description: String {
        switch self {
        case .began:
            return "began"
        case .cancelled:
            return "cancelled"
        case .changed:
            return "changed"
        case .ended:
            return "ended"
        case .failed:
            return "failed"
        case .possible:
            return "possible"
        @unknown default:
            print("Uknown gesture type: \(self)")
            return "unknown_new_type"
        }
    }
}

extension NSEvent.ModifierFlags: Hashable {
    public var hashValue: Int {
        return rawValue.hashValue
    }
}
#endif
