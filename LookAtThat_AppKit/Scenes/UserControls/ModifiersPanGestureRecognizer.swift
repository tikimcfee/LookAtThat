import Foundation
import SceneKit
import SwiftUI

class ModifiersPanGestureRecognizer: PanGestureRecognizer {
    var modifierFlags = NSEvent.ModifierFlags()

    var positionsForFlagChanges = [NSEvent.ModifierFlags: CGPoint]()
    var currentLocation: CGPoint { return location(in: view!) }

    var pressingOption: Bool {
        modifierFlags.contains(.option)
    }

    var pressingCommand: Bool {
        modifierFlags.contains(.command)
    }

    override func flagsChanged(with event: NSEvent) {
        super.flagsChanged(with: event)
        modifierFlags = event.modifierFlags
        computePositions()
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        modifierFlags = event.modifierFlags
        computePositions()
    }

    func computePositions() {
        let currentLocation = location(in: view!)
        positionsForFlagChanges[.option] = pressingOption ? currentLocation : nil
        positionsForFlagChanges[.command] = pressingCommand ? currentLocation : nil
    }

    subscript(index: NSEvent.ModifierFlags) -> CGPoint? {
        return positionsForFlagChanges[index]
    }
}

extension NSEvent.ModifierFlags: Hashable {
    public var hashValue: Int {
        return rawValue.hashValue
    }
}
