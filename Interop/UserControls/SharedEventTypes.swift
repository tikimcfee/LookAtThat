import Foundation

enum EventState {
    case began, changed, ended
}

enum EventType {
    case deviceTap
}

struct MagnificationEvent {
    let state: EventState?

    let rawMagnification: VectorFloat
    var magnification: VectorFloat {
        #if os(iOS)
        return rawMagnification
        #elseif os(OSX)
        return rawMagnification + 1
        #endif
    }
}

struct PanEvent {
    let state: EventState?

    let currentLocation: LFloat2

    var commandStart: LFloat2?
    var pressingCommand: Bool { commandStart != nil }

    var optionStart: LFloat2?
    var pressingOption: Bool { optionStart != nil }

    var controlStart: LFloat2?
    var pressingControl: Bool { controlStart != nil }
}

public struct GestureEvent {
    let state: EventState?
    let type: EventType?
    
    let currentLocation: LFloat2
    
    var commandStart: LFloat2?
    var pressingCommand: Bool { commandStart != nil }
    
    var optionStart: LFloat2?
    var pressingOption: Bool { optionStart != nil }
    
    var controlStart: LFloat2?
    var pressingControl: Bool { controlStart != nil }
}
