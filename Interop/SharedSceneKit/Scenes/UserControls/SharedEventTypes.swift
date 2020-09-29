import Foundation
import SceneKit

enum EventState {
    case began, changed, ended
}

struct MagnificationEvent {
    let state: EventState?

    let rawMagnification: CGFloat
    var magnification: CGFloat {
        #if os(iOS)
        return rawMagnification
        #elseif os(OSX)
        return rawMagnification + 1
        #endif
    }
}

struct PanEvent {
    let state: EventState?

    let currentLocation: CGPoint

    var commandStart: CGPoint?
    var pressingCommand: Bool { commandStart != nil }

    var optionStart: CGPoint?
    var pressingOption: Bool { optionStart != nil }

    var controlStart: CGPoint?
    var pressingControl: Bool { controlStart != nil }
}
