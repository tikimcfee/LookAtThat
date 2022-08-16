//
//  DefaultInputReceiver.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/9/22.
//

import Combine
import SceneKit

#if os(OSX)
import AppKit
class DefaultInputReceiver: ObservableObject, MousePositionReceiver, KeyDownReceiver {
    private let mouseSubject = PassthroughSubject<CGPoint, Never>()
    private let scrollSubject = PassthroughSubject<OSEvent, Never>()
    private let mouseDownSubject = PassthroughSubject<OSEvent, Never>()
    private let mouseUpSubject = PassthroughSubject<OSEvent, Never>()
    private let keyEventSubject = PassthroughSubject<OSEvent, Never>()
    
    lazy var sharedMouse = mouseSubject.share().eraseToAnyPublisher()
    lazy var sharedScroll = scrollSubject.share().eraseToAnyPublisher()
    lazy var sharedMouseDown = mouseDownSubject.share().eraseToAnyPublisher()
    lazy var sharedMouseUp = mouseUpSubject.share().eraseToAnyPublisher()
    lazy var sharedKeyEvent = keyEventSubject.share().eraseToAnyPublisher()
    
    lazy var touchState: TouchState = TouchState()
    lazy var gestureShim: GestureShim = GestureShim(
        { self.pan($0) },
        { self.magnify($0) },
        { self.onTap($0) }
    )
    
    var mousePosition: CGPoint = CGPoint.zero {
        didSet { mouseSubject.send(mousePosition) }
    }
    
    var scrollEvent: NSEvent = NSEvent() {
        didSet { scrollSubject.send(scrollEvent) }
    }
    
    var mouseDownEvent: NSEvent = NSEvent() {
        didSet { mouseDownSubject.send(mouseDownEvent) }
    }
    
    var mouseUpEvent: NSEvent = NSEvent() {
        didSet { mouseUpSubject.send(mouseUpEvent) }
    }
    
    var lastKeyEvent: NSEvent = NSEvent() {
        didSet { keyEventSubject.send(lastKeyEvent) }
    }
}
#elseif os(iOS)
import UIKit
class DefaultInputReceiver: ObservableObject, MousePositionReceiver, KeyDownReceiver {
    
    private let mouseSubject = PassthroughSubject<CGPoint, Never>()
    private let scrollSubject = PassthroughSubject<OSEvent, Never>()
    private let mouseDownSubject = PassthroughSubject<OSEvent, Never>()
    private let mouseUpSubject = PassthroughSubject<OSEvent, Never>()
    private let keyEventSubject = PassthroughSubject<OSEvent, Never>()
    
    lazy var sharedMouse = mouseSubject.share().eraseToAnyPublisher()
    lazy var sharedScroll = scrollSubject.share().eraseToAnyPublisher()
    lazy var sharedMouseDown = mouseDownSubject.share().eraseToAnyPublisher()
    lazy var sharedMouseUp = mouseUpSubject.share().eraseToAnyPublisher()
    lazy var sharedKeyEvent = keyEventSubject.share().eraseToAnyPublisher()
    
    lazy var touchState: TouchState = TouchState()
    lazy var gestureShim: GestureShim = GestureShim(
        { self.pan($0) },
        { self.magnify($0) },
        { self.onTap($0) }
    )
    
    var mousePosition: CGPoint = CGPoint.zero {
        didSet { mouseSubject.send(mousePosition) }
    }
    
    var scrollEvent: OSEvent = OSEvent() {
        didSet { scrollSubject.send(scrollEvent) }
    }
    
    var mouseDownEvent: OSEvent = OSEvent() {
        didSet { mouseDownSubject.send(mouseDownEvent) }
    }
    
    var mouseUpEvent: OSEvent = OSEvent() {
        didSet { mouseUpSubject.send(mouseUpEvent) }
    }
    
    var lastKeyEvent: OSEvent = OSEvent() {
        didSet { keyEventSubject.send(lastKeyEvent) }
    }
}
#endif

// MARK: - Tap / Click

extension DefaultInputReceiver {
    func onTap(_ event: GestureEvent) {
        print("Got gesture event: \(event)")
    }
}

// MARK: - Magnify

extension DefaultInputReceiver {
    func magnify(_ event: MagnificationEvent) {
        switch event.state {
        case .began:
            break
        case .changed:
            break
        default:
            break
        }
    }
}

// MARK: - Pan

extension DefaultInputReceiver {
    func pan(_ panEvent: PanEvent) {
        
    }
}
