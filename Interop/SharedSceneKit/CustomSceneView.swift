import Foundation
import SceneKit

#if os(iOS)
import ARKit

protocol MousePositionReceiver: class {
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
}

enum KeyEvent {
    case none
    case event(_ event: NSEvent)
}

protocol KeyDownReceiver: AnyObject {
    var lastEvent: KeyEvent { get set }
}

extension KeyDownReceiver {
    private var event: NSEvent? {
        switch lastEvent {
        case .none: return nil
        case .event(let event): return event
        }
    }
    
    var lastFullString: String { event?.characters ?? "" }
    var lastString: String { event?.charactersIgnoringModifiers ?? "" }
    
}

class CustomSceneView: SCNView {
    weak var positionReceiver: MousePositionReceiver?
    weak var keyDownReceiver: KeyDownReceiver?
    var trackingArea : NSTrackingArea?

    func setupDefaultLighting() {
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
        super.scrollWheel(with: event)
        guard let receiver = positionReceiver,
              event.type == .scrollWheel else { return }
        receiver.scrollEvent = event
    }

    override func updateTrackingAreas() {
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited,
                      .mouseMoved,
                      .activeInKeyWindow,
                      .activeAlways],
            owner: self,
            userInfo: nil
        )
        self.addTrackingArea(trackingArea!)
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        guard let receiver = positionReceiver else { return }
        let convertedPosition = convert(event.locationInWindow, from: nil)
        receiver.mousePosition = convertedPosition
    }

    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        guard let receiver = positionReceiver else { return }
        receiver.mouseDownEvent = event
    }
    
    override func keyDown(with event: NSEvent) {
        let keyEvent = KeyEvent.event(event)
        keyDownReceiver?.lastEvent = keyEvent
    }
    
    override var acceptsFirstResponder: Bool {
        true
    }
}

#endif
