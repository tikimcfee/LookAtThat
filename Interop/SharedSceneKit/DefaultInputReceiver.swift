//
//  DefaultInputReceiver.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/9/22.
//

import Combine

extension DefaultInputReceiver {
    static var shared = DefaultInputReceiver()
}

class DefaultInputReceiver: ObservableObject, MousePositionReceiver, KeyDownReceiver {
    private let mouseSubject = PassthroughSubject<OSEvent, Never>()
    private let scrollSubject = PassthroughSubject<OSEvent, Never>()
    private let mouseDownSubject = PassthroughSubject<OSEvent, Never>()
    private let mouseUpSubject = PassthroughSubject<OSEvent, Never>()
    private let keyEventSubject = PassthroughSubject<OSEvent, Never>()
    
    lazy var sharedMouse = mouseSubject.share().eraseToAnyPublisher()
    lazy var sharedScroll = scrollSubject.share().eraseToAnyPublisher()
    lazy var sharedMouseDown = mouseDownSubject.share().eraseToAnyPublisher()
    lazy var sharedMouseUp = mouseUpSubject.share().eraseToAnyPublisher()
    lazy var sharedKeyEvent = keyEventSubject.share().eraseToAnyPublisher()
    
    var mousePosition: OSEvent = OSEvent() {
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
    
    lazy var touchState: TouchState = TouchState()
    lazy var gestureShim: GestureShim = GestureShim(
        { print(#line, "DefaultInput received: \($0)") },
        { print(#line, "DefaultInput received: \($0)") },
        { print(#line, "DefaultInput received: \($0)") }
    )
}
