import Foundation
import SceneKit

protocol KeyDownReceiver: AnyObject {
    var lastKeyEvent: OSEvent { get set }
}

#if os(iOS)
import ARKit

protocol MousePositionReceiver: AnyObject {
    var mousePosition: CGPoint { get set }
    var scrollEvent: UIEvent { get set }
    var mouseDownEvent: UIEvent { get set }
}

class CustomSceneView: ARSCNView {
    weak var positionReceiver: MousePositionReceiver?

    func setupDefaultLighting() {
        
    }
}

#elseif os(OSX)

protocol MousePositionReceiver: AnyObject {
    var mousePosition: CGPoint { get set }
    var scrollEvent: NSEvent { get set }
    var mouseDownEvent: NSEvent { get set }
    var mouseUpEvent: NSEvent { get set }
}

class CustomSceneView: SCNView {
    weak var positionReceiver: MousePositionReceiver?
    weak var keyDownReceiver: KeyDownReceiver?
    var trackingArea : NSTrackingArea?

    func setupDefaultLighting() {
        // WARNING
        // DO NOT access NSEvents off of the main thread. Copy whatever information you need.
        // It is NOT SAFE to access these objects outside of this call scope.
        showsStatistics = true

        backgroundColor = NSUIColor.gray

        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = NSUIColor(white: 0.67, alpha: 1.0)
        scene?.rootNode.addChildNode(ambientLightNode)

        let omniLightNode = SCNNode()
        omniLightNode.light = SCNLight()
        omniLightNode.light!.type = SCNLight.LightType.omni
        omniLightNode.light!.color = NSUIColor(white: 0.75, alpha: 1.0)
        omniLightNode.position = SCNVector3Make(0, 50, 50)
        scene?.rootNode.addChildNode(omniLightNode)
    }

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
            options: [.mouseEnteredAndExited,
                      .mouseMoved,
                      .enabledDuringMouseDrag,
                      .activeInKeyWindow,
                      .activeAlways],
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
        let convertedPosition = convert(event.locationInWindow, from: nil)
        receiver.mousePosition = convertedPosition
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
        super.mouseDown(with: event)
        guard let receiver = positionReceiver else { return }
        receiver.mouseDownEvent = event.copy() as! NSEvent
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
    
    override func flagsChanged(with event: NSEvent) {
        // WARNING
        // DO NOT access NSEvents off of the main thread. Copy whatever information you need.
        // It is NOT SAFE to access these objects outside of this call scope.
        keyDownReceiver?.lastKeyEvent = event.copy() as! NSEvent
    }
    
    override var acceptsFirstResponder: Bool {
        true
    }
}

#endif
