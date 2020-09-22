import Foundation
import SceneKit
import SwiftUI

class ModifierStore {
    var modifierFlags = NSEvent.ModifierFlags()
    var positionsForFlagChanges = [NSEvent.ModifierFlags: CGPoint]()

    var pressingOption: Bool {
        modifierFlags.contains(.option)
    }

    var pressingCommand: Bool {
        modifierFlags.contains(.command)
    }

    func computePositions(_ currentLocation: CGPoint) {
        positionsForFlagChanges[.option] = pressingOption ? currentLocation : nil
        positionsForFlagChanges[.command] = pressingCommand ? currentLocation : nil
    }
}

extension GestureRecognizer {
    var currentLocation: CGPoint { return location(in: view!) }
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
}

class ModifiersPanGestureRecognizer: PanGestureRecognizer {
    private var store = ModifierStore()
    var pressingOption: Bool { store.pressingOption }
    var pressingCommand: Bool { store.pressingCommand }

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
}

extension NSEvent.ModifierFlags: Hashable {
    public var hashValue: Int {
        return rawValue.hashValue
    }
}
