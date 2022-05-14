import Foundation
import SwiftUI
import SceneKit

typealias PanReceiver = (PanEvent) -> Void
typealias MagnificationReceiver = (MagnificationEvent) -> Void
typealias TapReceiver = (GestureEvent) -> Void

#if os(OSX)

class GestureShim {
    lazy var panRecognizer =
        ModifiersPanGestureRecognizer(target: self, action: #selector(pan))
    let onPan: PanReceiver

    lazy var magnificationRecognizer =
        ModifiersMagnificationGestureRecognizer(target: self, action: #selector(magnify))
    let onMagnify: MagnificationReceiver
    
    lazy var tapGestureRecognizer =
        TapGestureRecognizer(target: self, action: #selector(noop))
    let onTap: TapReceiver

    init(_ onPan: @escaping PanReceiver,
         _ onMagnify: @escaping MagnificationReceiver,
         _ onTap: @escaping TapReceiver) {
        self.onPan = onPan
        self.onMagnify = onMagnify
        self.onTap = onTap
        
        tapGestureRecognizer.isEnabled = false
    }

    @objc func pan(_ receiver: ModifiersPanGestureRecognizer) {
        onPan(receiver.makePanEvent)
    }

    @objc func magnify(_ receiver: ModifiersMagnificationGestureRecognizer) {
        onMagnify(receiver.makeMagnificationEvent)
    }
    
    @objc func noop(_ receiver: TapGestureRecognizer) { }
}

#elseif os(iOS)

class GestureShim {
    lazy var panRecognizer =
        PanGestureRecognizer(target: self, action: #selector(pan))
    let onPan: PanReceiver

    lazy var magnificationRecognizer =
        MagnificationGestureRecognizer(target: self, action: #selector(magnify))
    let onMagnify: MagnificationReceiver
    
    lazy var tapGestureRecognizer =
        TapGestureRecognizer(target: self, action: #selector(tap))
    let onTap: TapReceiver

    init(_ onPan: @escaping PanReceiver,
         _ onMagnify: @escaping MagnificationReceiver,
         _ onTap: @escaping TapReceiver) {
        self.onPan = onPan
        self.onMagnify = onMagnify
        self.onTap = onTap
    }
    
    @objc func tap(_ receiver: TapGestureRecognizer) {
        onTap(receiver.makeGestureEvent)
    }

    @objc func pan(_ receiver: PanGestureRecognizer) {
        onPan(receiver.makePanEvent)
    }

    @objc func magnify(_ receiver: MagnificationGestureRecognizer) {
        onMagnify(receiver.makeMagnificationEvent)
    }
}

#endif

extension BaseSceneController {
    func attachTapGestureRecognizer() {
        sceneView.addGestureRecognizer(panGestureShim.tapGestureRecognizer)
    }
    
    func onTap(_ event: GestureEvent) {
        onTapGesture(event)
    }
}

extension BaseSceneController {
    func attachMagnificationRecognizer() {
        sceneView.addGestureRecognizer(panGestureShim.magnificationRecognizer)
    }

    func magnify(_ event: MagnificationEvent) {
        switch event.state {
        case .began:
            touchState.magnify.lastScaleZ = sceneCameraNode.scale.z.cg
        case .changed:
            let magnification = event.magnification
            let newScaleZ = max(
                touchState.magnify.lastScaleZ * magnification,
                CGFloat(0.25)
            ).vector
            sceneTransaction(0) {
                self.sceneCameraNode.scale = SCNVector3Make(1, 1, newScaleZ);
            }
        default:
            break
        }
    }
}

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return sqrt(pow(point.x - x, 2) + pow(point.y - y, 2))
    }

    func scaled(_ factor: CGFloat) -> CGPoint {
        return CGPoint(x: x * factor, y: y * factor)
    }
}

// Adapted from https://stackoverflow.com/questions/48970111/rotating-scnnode-on-y-axis-based-on-pan-gesture
extension BaseSceneController {
    func attachPanRecognizer() {
        sceneView.addGestureRecognizer(panGestureShim.panRecognizer)
    }

    func pan(_ panEvent: PanEvent) {
        if panEvent.state == .began {
            panBegan(panEvent)
        }

        if panEvent.pressingCommand, let start = panEvent.commandStart {
            // Can always rotate the camera
            panHoldingCommand(panEvent, start)
            panOnNode(panEvent)
        } else if touchState.pan.valid {
            if panEvent.pressingOption, let start = panEvent.optionStart {
                panHoldingOption(panEvent, start)
            } else {
                panOnNode(panEvent)
            }
        }

        if panEvent.state == .ended {
            touchState.pan = TouchStart()
            print("-- Ended pan")
        }
    }
    
    private func panBegan(_ event: PanEvent) {
        touchState.pan.cameraNodeEulers = sceneCameraNode.eulerAngles
        let currentTouchLocation = event.currentLocation
        
        let evaluator = HitTestEvaluator(controller: SceneLibrary.global.codePagesController)
        
        let first = evaluator.testAndEval(currentTouchLocation, [
            .codeGrid, .codeGridGlyphs, .semanticTab, .codeGridSnapshot, .codeGridFocusBox
        ]).sorted(by: { left, right in
            return left.defaultSortOrder < right.defaultSortOrder
        }).first
        
        guard let first = first else { return }
        print("interacting with \(first)")
        
        let positioningNode = first.positionNode
        
        touchState.pan.gesturePoint = currentTouchLocation
        touchState.pan.positioningNode = positioningNode
        touchState.pan.computeStartPosition()
        touchState.pan.computeStartEulers()
        touchState.pan.computeProjectedDepthPosition(in: sceneView)
        touchState.pan.computeStartUnprojection(in: sceneView)
        touchState.pan.valid = true
        print("-- Found a node; touch valid")
    }

    private func panOnNode(_ event: PanEvent) {
        touchState.pan.computedEndUnprojection(with: event.currentLocation, in: sceneView)
        
        let startUnprojection = touchState.pan.computedStartUnprojectionWorld
        let newLocationProjection = touchState.pan.computedEndUnprojectionWorld
        let dX = newLocationProjection.x - startUnprojection.x
        let dY = newLocationProjection.y - startUnprojection.y
        let dZ = newLocationProjection.z - startUnprojection.z

        touchState.pan.computeStartEulers()

        sceneTransaction(0) {
            touchState.pan.setWorldTranslatedPosition(dX, dY, dZ)
        }
    }

    private func panHoldingOption(_ event: PanEvent, _ start: CGPoint) {
        let end = event.currentLocation
        let rotation = rotationBetween(start, end, using: touchState.pan.positioningNodeEulers)
        guard rotation.x != 0.0 || rotation.y != 0 else { return }
        sceneTransaction(0) {
            touchState.pan.positioningNode.eulerAngles.x = rotation.x.vector
            touchState.pan.positioningNode.eulerAngles.y = rotation.y.vector
        }

        // Reset position 'start' position after rotation
        touchState.pan.gesturePoint = event.currentLocation
        touchState.pan.computeStartPosition()
        touchState.pan.computeProjectedDepthPosition(in: sceneView)
        touchState.pan.computeStartUnprojection(in: sceneView)
    }

    private func panHoldingCommand(_ event: PanEvent, _ start: CGPoint) {
        let scaledStart = start.scaled(0.33)
        let end = event.currentLocation.scaled(0.33)
        if scaledStart == end  {
            touchState.pan.cameraNodeEulers = sceneCameraNode.eulerAngles
            return
        }

        // reverse start and end to reverse camera control style
        let rotation = rotationBetween(end, scaledStart, using: touchState.pan.cameraNodeEulers)
        guard rotation.x != 0.0 || rotation.y != 0.0 else { return }

        sceneTransaction(0) {
            sceneCameraNode.eulerAngles.y = rotation.y.vector
            sceneCameraNode.eulerAngles.x = rotation.x.vector
        }
    }

    private func rotationBetween(_ startPosition: CGPoint,
                                 _ endPosition: CGPoint,
                                 using currentAngles: SCNVector3) -> CGPoint {
        let translation = CGPoint(x: endPosition.x - startPosition.x,
                                  y: endPosition.y - startPosition.y)
        guard translation.x != 0.0 || translation.y != 0.0 else { return CGPoint.zero }
        var newAngleY = translation.x * CGFloat(Double.pi/180.0)
        var newAngleX = -translation.y * CGFloat(Double.pi/180.0)
        newAngleY += currentAngles.y.cg
        newAngleX += currentAngles.x.cg
        return CGPoint(x: newAngleX, y: newAngleY)
    }
}

class TouchState {
    var pan = TouchStart()
    var magnify = MagnifyStart()
    var mouse = Mouse()
}

class Mouse {
	let hoverTracker = TokenHoverInteractionTracker()
	
	var currentHoveredSheet: SCNNode?
}

class MagnifyStart {
    var lastScaleZ = CGFloat(1.0)
}

class TouchStart {
    var valid: Bool = false
    var gesturePoint = CGPoint()

    var positioningNode = SCNNode()
    var positioningNodeStart = SCNVector3Zero
    var positioningNodeStartWorld = SCNVector3Zero
    var positioningNodeEulers = SCNVector3Zero

    var projectionDepthPosition = SCNVector3Zero
    var projectionDepthPositionWorld = SCNVector3Zero
    var computedStartUnprojection = SCNVector3Zero
    var computedStartUnprojectionWorld = SCNVector3Zero
    var computedEndUnprojection = SCNVector3Zero
    var computedEndUnprojectionWorld = SCNVector3Zero

    var cameraNodeEulers = SCNVector3Zero

    // Starting values
    func computeStartPosition() {
        positioningNodeStart = positioningNode.position
        positioningNodeStartWorld = positioningNode.worldPosition
    }

    func computeStartEulers() {
        positioningNodeEulers = positioningNode.eulerAngles
    }

    func computeProjectedDepthPosition(in scene: SCNView) {
        projectionDepthPosition = scene.projectPoint(positioningNode.position)
        projectionDepthPositionWorld = scene.projectPoint(positioningNode.worldPosition)
    }

    func computeStartUnprojection(in scene: SCNView) {
        computedStartUnprojection = scene.unprojectPoint(
            SCNVector3(
                x: gesturePoint.x.vector,
                y: gesturePoint.y.vector,
                z: projectionDepthPosition.z.vector
            )
        )
        computedStartUnprojectionWorld = scene.unprojectPoint(
            SCNVector3(
                x: gesturePoint.x.vector,
                y: gesturePoint.y.vector,
                z: projectionDepthPositionWorld.z.vector
            )
        )
    }

    // End values
    func computedEndUnprojection(with location: CGPoint, in scene: SCNView) {
        computedEndUnprojection = scene.unprojectPoint(
            SCNVector3(
                x: location.x.vector,
                y: location.y.vector,
                z: projectionDepthPosition.z.vector
            )
        )
        computedEndUnprojectionWorld = scene.unprojectPoint(
            SCNVector3(
                x: location.x.vector,
                y: location.y.vector,
                z: projectionDepthPositionWorld.z.vector
            )
        )
    }

    // Setting values
    func setTranslatedPosition(_ dX: VectorFloat,
                               _ dY: VectorFloat,
                               _ dZ: VectorFloat) {
        positioningNode.position =
            positioningNodeStart.translated(dX: dX, dY: dY, dZ: dZ)
    }
    
    func setWorldTranslatedPosition(_ dX: VectorFloat,
                                    _ dY: VectorFloat,
                                    _ dZ: VectorFloat) {
        #if os(iOS)
        positioningNode.worldPosition =
            positioningNodeStartWorld.translated(dX: dX, dY: dY, dZ: dZ)
        #elseif os(macOS)
        positioningNode.worldPosition =
            positioningNodeStartWorld.translated(dX: dX, dY: dY, dZ: dZ)
        #endif
    }
}
