#if os(OSX)
import AppKit
#elseif os(iOS)
import UIKit
#endif

protocol KeyDownReceiver: AnyObject {
    var lastKeyEvent: OSEvent { get set }
}

#if os(iOS)

protocol MousePositionReceiver: AnyObject {
    var mousePosition: OSEvent { get set }
    var scrollEvent: OSEvent { get set }
    var mouseDownEvent: OSEvent { get set }
}

#elseif os(OSX)

protocol MousePositionReceiver: AnyObject {
    var mousePosition: OSEvent { get set }
    var scrollEvent: OSEvent { get set }
    var mouseDownEvent: OSEvent { get set }
    var mouseUpEvent: OSEvent { get set }
}

#endif
