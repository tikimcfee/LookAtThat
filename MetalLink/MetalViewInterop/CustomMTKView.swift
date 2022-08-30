//
//  CustomMTKView.swift
//  LookAtThat_AppKit
//
//  Created by Ivan Lugo on 8/29/22.
//

import Foundation
import MetalKit
import SwiftUI


class CustomMTKView: MTKView {
    weak var positionReceiver: MousePositionReceiver?
    weak var keyDownReceiver: KeyDownReceiver?
    
#if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
//        touches.forEach { touch in
//
//        }
    }
    
    override func touchesEnded(with event: NSEvent) {
        super.touchesEnded(with: event)
    }
#endif
    
#if os(macOS)
    var trackingArea : NSTrackingArea?
    
    override func scrollWheel(with event: NSEvent) {
        // WARNING
        // DO NOT access NSEvents off of the main thread. Copy whatever information you need.
        // It is NOT SAFE to access these objects outside of this call scope.
        super.scrollWheel(with: event)
        guard let receiver = positionReceiver,
              event.type == .scrollWheel else { return }
        receiver.scrollEvent = event.copy() as! NSEvent
    }
    
    override func updateTrackingAreas() {
        // WARNING
        // DO NOT access NSEvents off of the main thread. Copy whatever information you need.
        // It is NOT SAFE to access these objects outside of this call scope.
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [
                .mouseMoved,
                .enabledDuringMouseDrag,
                .inVisibleRect,
                .activeAlways
            ],
            owner: self,
            userInfo: nil
        )
        self.addTrackingArea(trackingArea!)
    }
    
    override func mouseMoved(with event: NSEvent) {
        // WARNING
        // DO NOT access NSEvents off of the main thread. Copy whatever information you need.
        // It is NOT SAFE to access these objects outside of this call scope.
        super.mouseMoved(with: event)
        guard let receiver = positionReceiver else { return }
        receiver.mousePosition = event.copy() as! NSEvent
    }
    
    override func mouseDown(with event: NSEvent) {
        // WARNING
        // DO NOT access NSEvents off of the main thread. Copy whatever information you need.
        // It is NOT SAFE to access these objects outside of this call scope.
        super.mouseDown(with: event)
        guard let receiver = positionReceiver else { return }
        receiver.mouseDownEvent = event.copy() as! NSEvent
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        guard let receiver = positionReceiver else { return }
        receiver.mouseUpEvent = event.copy() as! NSEvent
    }
    
    override func keyDown(with event: NSEvent) {
        // WARNING
        // DO NOT access NSEvents off of the main thread. Copy whatever information you need.
        // It is NOT SAFE to access these objects outside of this call scope.
        keyDownReceiver?.lastKeyEvent = event.copy() as! NSEvent
    }
    
    override func keyUp(with event: NSEvent) {
        // WARNING
        // DO NOT access NSEvents off of the main thread. Copy whatever information you need.
        // It is NOT SAFE to access these objects outside of this call scope.
        keyDownReceiver?.lastKeyEvent = event.copy() as! NSEvent
    }
    
    override func otherMouseDragged(with event: NSEvent) {
        super.otherMouseDragged(with: event)
        guard let receiver = positionReceiver else { return }
        receiver.mousePosition = event.copy() as! NSEvent
    }
    
    override func rightMouseDragged(with event: NSEvent) {
        super.rightMouseDragged(with: event)
        guard let receiver = positionReceiver else { return }
        receiver.mousePosition = event.copy() as! NSEvent
    }
    
    override func mouseDragged(with event: NSEvent) {
        // WARNING
        // DO NOT access NSEvents off of the main thread. Copy whatever information you need.
        // It is NOT SAFE to access these objects outside of this call scope.
        super.mouseDragged(with: event)
        guard let receiver = positionReceiver else { return }
        receiver.mousePosition = event.copy() as! NSEvent
    }
    
    override func flagsChanged(with event: NSEvent) {
        // WARNING
        // DO NOT access NSEvents off of the main thread. Copy whatever information you need.
        // It is NOT SAFE to access these objects outside of this call scope.
        keyDownReceiver?.lastKeyEvent = event.copy() as! NSEvent
    }
    
    override var acceptsFirstResponder: Bool {
        true
    }
#endif
}
