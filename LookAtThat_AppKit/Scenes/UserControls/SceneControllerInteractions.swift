import Foundation
import SwiftUI
import SceneKit

typealias PanReceiver = (ModifiersPanGestureRecognizer) -> Void
typealias MagnificationReceiver = (ModifiersMagnificationGestureRecognizer) -> Void

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
        onPan(receiver)
    }

    @objc func magnify(_ receiver: ModifiersMagnificationGestureRecognizer) {
        onMagnify(receiver)
    }
}

extension NSGestureRecognizer.State: CustomStringConvertible {
    public var description: String {
        switch self {
        case .began:
            return "began"
        case .cancelled:
            return "cancelled"
        case .changed:
            return "changed"
        case .ended:
            return "ended"
        case .failed:
            return "failed"
        case .possible:
            return "possible"
        @unknown default:
            print("Uknown gesture type: \(self)")
            return "unknown_new_type"
        }
    }
}

extension BaseSceneController {
    func attachMagnificationRecognizer() {
        sceneView.addGestureRecognizer(panGestureShim.magnificationRecognizer)
    }

    func magnify(_ receiver: ModifiersMagnificationGestureRecognizer) {
        switch receiver.state {
        case .began:
            touchState.magnify.lastScaleZ = sceneCameraNode.scale.z
        case .changed:
            let magnification = receiver.magnification + 1.0;
            let newScaleZ = touchState.magnify.lastScaleZ * magnification;
            sceneTransaction(0) {
                self.sceneCameraNode.scale = SCNVector3Make(1, 1, newScaleZ);
            }
        default:
            break
        }
    }
}

// Adapted from https://stackoverflow.com/questions/48970111/rotating-scnnode-on-y-axis-based-on-pan-gesture
extension BaseSceneController {
    func attachPanRecognizer() {
        sceneView.addGestureRecognizer(panGestureShim.panRecognizer)
    }

    func pan(_ receiver: ModifiersPanGestureRecognizer) {
        let currentTouchLocation = receiver.location(in: sceneView)

        if receiver.state == .began {
            let hitTestResults = sceneView.hitTestCodeSheet(with: currentTouchLocation)
            guard let firstResult = hitTestResults.first,
                  let positioningNode = firstResult.node.parent else {
                return
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

        guard touchState.pan.valid else { return }

        switch receiver.pressingOption {
        case false:
            let newLocationProjection = touchState.pan.computedEndUnprojection(with: currentTouchLocation, in: sceneView)
            let dX = newLocationProjection.x - touchState.pan.computedStartUnprojection.x
            let dY = newLocationProjection.y - touchState.pan.computedStartUnprojection.y

            touchState.pan.positioningNodeEulers = touchState.pan.positioningNode.eulerAngles

            sceneTransaction(0) {
                touchState.pan.positioningNode.position =
                    touchState.pan.positioningNodeStart.translated(dX: dX, dY: dY)
            }
        case true:
            let startPosition = receiver[.option]!
            let endPosition = receiver.currentLocation
            let translation = CGPoint(x: endPosition.x - startPosition.x,
                                      y: endPosition.y - startPosition.y)

            guard translation.x != 0.0 || translation.y != 0.0 else { return }

            var newAngleY = translation.x * CGFloat(Double.pi/180.0)
            var newAngleX = -translation.y * CGFloat(Double.pi/180.0)
            newAngleY += touchState.pan.positioningNodeEulers.y
            newAngleX += touchState.pan.positioningNodeEulers.x

            sceneTransaction(0) {
                touchState.pan.positioningNode.eulerAngles.y = newAngleY
                touchState.pan.positioningNode.eulerAngles.x = newAngleX
            }

            // Reset position 'start' position after rotation
            touchState.pan.gesturePoint = currentTouchLocation
            touchState.pan.positioningNodeStart = touchState.pan.positioningNode.position
            touchState.pan.projectionDepthPosition = sceneView.projectPoint(touchState.pan.positioningNode.position)
            touchState.pan.computeStartUnprojection(in: sceneView)
        }

        if receiver.state == .ended {
            touchState.pan = TouchStart()
            touchState.pan.valid = false
            print("-- Ended pan")
        }
    }
}

class TouchState {
    var pan = TouchStart()
    var magnify = MagnifyStart()
    var mouse = Mouse()
}

class Mouse {
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
    var positioningNodeEulers = SCNVector3Zero

    var projectionDepthPosition = SCNVector3Zero
    var computedStartUnprojection = SCNVector3Zero

    func computeStartUnprojection(in scene: SCNView) {
        computedStartUnprojection = scene.unprojectPoint(
            SCNVector3(
                x: gesturePoint.x,
                y: gesturePoint.y,
                z: projectionDepthPosition.z
            )
        )
    }

    func computedEndUnprojection(with location: CGPoint, in scene: SCNView) -> SCNVector3 {
        return scene.unprojectPoint(
            SCNVector3(
                x: location.x,
                y: location.y,
                z: projectionDepthPosition.z
            )
        )
    }
}
