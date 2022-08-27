//  ATTRIBUTION TO:
//  [Created by Szymon Błaszczyński on 26/08/2021.]
// https://gist.githubusercontent.com/buahaha/19b27170e629276606ab2e057823de70/raw/a8c45e38988dc3654fb41ecec5411cef7849f3b5/MetalView.swift

import Foundation
import MetalKit
import SwiftUI

struct MetalView: NSUIViewRepresentable {
    var mtkView: CustomMTKView
    
    init() throws {
        self.mtkView = GlobalInstances.rootCustomMTKView
    }
    
    #if os(iOS)
    func makeUIView(context: Context) -> some UIView {
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = false
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float
        return mtkView
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    #elseif os(macOS)
    func makeNSView(context: NSViewRepresentableContext<MetalView>) -> CustomMTKView {
        mtkView.preferredFramesPerSecond = 60
        mtkView.enableSetNeedsDisplay = true
        mtkView.isPaused = false
        mtkView.colorPixelFormat = .bgra8Unorm
        mtkView.depthStencilPixelFormat = .depth32Float
        return mtkView
    }
    
    func updateNSView(_ nsView: CustomMTKView, context: NSViewRepresentableContext<MetalView>) {
        
    }
    #endif
    
    func makeCoordinator() -> Coordinator {
        try! Coordinator(self, mtkView: mtkView)
    }
}

import Combine
extension MetalView {
    class Coordinator {
        var parent: MetalView
        
        var link: MetalLink
        var renderer: MetalLinkRenderer
        
        init(_ parent: MetalView, mtkView: CustomMTKView) throws {
            self.parent = parent
            guard let link = try? MetalLink(view: mtkView),
                  let renderer = try? MetalLinkRenderer(link: link)
            else { throw CoreError.noMetalDevice }
            
            self.link = link
            self.renderer = renderer
            
            mtkView.keyDownReceiver = link.input
            mtkView.positionReceiver = link.input
            
//            print("-- Metal Gesture Recognizers --")
//            print("This will disable some view events by default, like 'drag'")
//            mtkView.addGestureRecognizer(link.input.gestureShim.tapGestureRecognizer)
//            mtkView.addGestureRecognizer(link.input.gestureShim.magnificationRecognizer)
//            mtkView.addGestureRecognizer(link.input.gestureShim.panRecognizer)
//            print("-------------------------------")
            
            mtkView.delegate = renderer
            mtkView.framebufferOnly = false
            mtkView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 0)
            mtkView.drawableSize = mtkView.frame.size
            mtkView.enableSetNeedsDisplay = true
        }
    }
}

class CustomMTKView: MTKView {
    weak var positionReceiver: MousePositionReceiver?
    weak var keyDownReceiver: KeyDownReceiver?
    
    #if os(iOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touches.forEach { touch in
            
        }
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
