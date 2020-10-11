import Foundation
import SwiftUI
import SceneKit

typealias PanReceiver = (PanEvent) -> Void
typealias MagnificationReceiver = (MagnificationEvent) -> Void

#if os(OSX)

class GestureShim {
    lazy var panRecognizer =
        ModifiersPanGestureRecognizer(target: self, action: #selector(pan))
    let onPan: PanReceiver

    lazy var magnificationRecognizer =
        ModifiersMagnificationGestureRecognizer(target: self, action: #selector(magnify))
    let onMagnify: MagnificationReceiver

    init(_ onPan: @escaping PanReceiver,
         _ onMagnify: @escaping MagnificationReceiver) {
        self.onPan = onPan
        self.onMagnify = onMagnify
    }

    @objc func pan(_ receiver: ModifiersPanGestureRecognizer) {
        onPan(receiver.makePanEvent)
    }

    @objc func magnify(_ receiver: ModifiersMagnificationGestureRecognizer) {
        onMagnify(receiver.makeMagnificationEvent)
    }
}

#elseif os(iOS)

class GestureShim {
    lazy var panRecognizer =
        PanGestureRecognizer(target: self, action: #selector(pan))
    let onPan: PanReceiver

    lazy var magnificationRecognizer =
        MagnificationGestureRecognizer(target: self, action: #selector(magnify))
    let onMagnify: MagnificationReceiver

    init(_ onPan: @escaping PanReceiver,
         _ onMagnify: @escaping MagnificationReceiver) {
        self.onPan = onPan
        self.onMagnify = onMagnify
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
        } else if touchState.pan.valid {
            if panEvent.pressingOption, let start = panEvent.optionStart {
                panHoldingOption(panEvent, start)
            } else {
                panOnNode(panEvent)
            }
        }

        if panEvent.state == .ended {
            touchState.pan = TouchStart()
            touchState.pan.valid = false
            print("-- Ended pan")
        }
    }

    private func panBegan(_ event: PanEvent) {
        touchState.pan.cameraNodeEulers = sceneCameraNode.eulerAngles
        let currentTouchLocation = event.currentLocation
        let hitTestResults = sceneView.hitTestCodeSheet(with: currentTouchLocation)
        guard let firstResult = hitTestResults.first,
              var positioningNode = firstResult.node.parent else {
            return
        }

        if HitTestType.semanticTab.rawValue == firstResult.node.categoryBitMask {
            // SemanticInfo is setup as a child of the container.
            // we want to position the parent itself when dragged, so move up the hierarchy.
            positioningNode = positioningNode.parent!
        }

        touchState.pan.gesturePoint = currentTouchLocation
        touchState.pan.positioningNode = positioningNode
        touchState.pan.positioningNodeStart = positioningNode.position
        touchState.pan.positioningNodeEulers = positioningNode.eulerAngles
        touchState.pan.projectionDepthPosition = sceneView.projectPoint(positioningNode.position)
        touchState.pan.computeStartUnprojection(in: sceneView)
        touchState.pan.valid = true
        print("-- Found a node; touch valid")
    }

    private func panOnNode(_ event: PanEvent) {
        let currentTouchLocation = event.currentLocation
        let newLocationProjection = touchState.pan.computedEndUnprojection(with: currentTouchLocation, in: sceneView)
        let dX = newLocationProjection.x - touchState.pan.computedStartUnprojection.x
        let dY = newLocationProjection.y - touchState.pan.computedStartUnprojection.y

        touchState.pan.positioningNodeEulers = touchState.pan.positioningNode.eulerAngles

        sceneTransaction(0) {
            touchState.pan.positioningNode.position =
                touchState.pan.positioningNodeStart.translated(dX: dX, dY: dY)
        }
    }

    private func panHoldingOption(_ event: PanEvent, _ start: CGPoint) {
        let end = event.currentLocation
        let rotation = rotationBetween(start, end, using: touchState.pan.positioningNodeEulers)
        guard rotation.x != 0.0 || rotation.y != 0 else { return }
        sceneTransaction(0) {
            touchState.pan.positioningNode.eulerAngles.y = rotation.y.vector
            touchState.pan.positioningNode.eulerAngles.x = rotation.x.vector
        }

        // Reset position 'start' position after rotation
        touchState.pan.gesturePoint = event.currentLocation
        touchState.pan.positioningNodeStart = touchState.pan.positioningNode.position
        touchState.pan.projectionDepthPosition = sceneView.projectPoint(touchState.pan.positioningNode.position)
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
        guard rotation.x != 0.0 || rotation.y != 0 else { return }

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

    private func setPositionOf(_ node: SCNNode,
                               to position: SCNVector3,
                               relativeTo referenceNode: SCNNode) {
        let referenceNodeTransform = matrix_float4x4(referenceNode.transform)

        // Setup a translation matrix with the desired position
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.x = Float(position.x)
        translationMatrix.columns.3.y = Float(position.y)
        translationMatrix.columns.3.z = Float(position.z)

        // Combine the configured translation matrix with the referenceNode's transform to get the desired position AND orientation
        let updatedTransform = matrix_multiply(referenceNodeTransform, translationMatrix)
        node.transform = SCNMatrix4(updatedTransform)
    }
}

class TouchState {
    var pan = TouchStart()
    var magnify = MagnifyStart()
    var mouse = Mouse()
}

class Mouse {
    var currentHoveredSheet: SCNNode?
    var currentClickedSheet: CodeSheet?
}

class MagnifyStart {
    var lastScaleZ = CGFloat(1.0)
}

class TouchStart {
    var valid: Bool = false
    var gesturePoint = CGPoint()

    var positioningNode = SCNNode()
    var positioningNodeStart = SCNVector3Zero
    var positioningNodeEulers = SCNVector3Zero

    var projectionDepthPosition = SCNVector3Zero
    var computedStartUnprojection = SCNVector3Zero

    var cameraNodeEulers = SCNVector3Zero

    func computeStartUnprojection(in scene: SCNView) {
        computedStartUnprojection = scene.unprojectPoint(
            SCNVector3(
                x: gesturePoint.x.vector,
                y: gesturePoint.y.vector,
                z: projectionDepthPosition.z.vector
            )
        )
    }

    func computedEndUnprojection(with location: CGPoint, in scene: SCNView) -> SCNVector3 {
        return scene.unprojectPoint(
            SCNVector3(
                x: location.x.vector,
                y: location.y.vector,
                z: projectionDepthPosition.z.vector
            )
        )
    }
}
