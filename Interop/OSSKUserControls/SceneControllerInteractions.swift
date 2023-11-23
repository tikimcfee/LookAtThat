import Foundation
import SwiftUI
import SceneKit

extension MainSceneController {
    func attachPanRecognizer() {
        sceneView.addGestureRecognizer(panGestureRecognizer)

    }

    @objc func pan(_ receiver: ModifiersPanGestureRecognizer) {
        let currentTouchLocation = receiver.location(in: sceneView)

        if receiver.state == .began {
            let hitTestResults = sceneView.hitTestCodeSheet(with: currentTouchLocation)
            guard let firstResult = hitTestResults.first,
                  let positioningNode = firstResult.node.parent else {
                return
            }
            touchState.start.gesturePoint = currentTouchLocation
            touchState.start.positioningNode = positioningNode
            touchState.start.positioningNodeStart = positioningNode.position
            touchState.start.positioningNodeEulers = positioningNode.eulerAngles
            touchState.start.projectionDepthPosition = sceneView.projectPoint(positioningNode.position)
            touchState.start.computeStartUnprojection(in: sceneView)
            touchState.valid = true
            print("-- Found a node; touch valid")
        }

        guard touchState.valid else { return }

        switch receiver.pressingOption {
        case false:
            let newLocationProjection = touchState.start.computedEndUnprojection(with: currentTouchLocation, in: sceneView)
            let dX = newLocationProjection.x - touchState.start.computedStartUnprojection.x
            let dY = newLocationProjection.y - touchState.start.computedStartUnprojection.y

            touchState.start.positioningNodeEulers = touchState.start.positioningNode.eulerAngles

            sceneTransaction(0) {
                touchState.start.positioningNode.position =
                    touchState.start.positioningNodeStart.translated(dX: dX, dY: dY)
            }
        case true:
            let startPosition = receiver[.option]!
            let endPosition = receiver.currentLocation
            let translation = CGPoint(x: endPosition.x - startPosition.x,
                                      y: endPosition.y - startPosition.y)

            guard translation.x != 0.0 || translation.y != 0.0 else { return }

            var newAngleY = translation.x * CGFloat(Double.pi/180.0)
            var newAngleX = -translation.y * CGFloat(Double.pi/180.0)
            newAngleY += touchState.start.positioningNodeEulers.y
            newAngleX += touchState.start.positioningNodeEulers.x

            sceneTransaction(0) {
                touchState.start.positioningNode.eulerAngles.y = newAngleY
                touchState.start.positioningNode.eulerAngles.x = newAngleX
            }

            // Reset position 'start' position after rotation
            touchState.start.gesturePoint = currentTouchLocation
            touchState.start.positioningNodeStart = touchState.start.positioningNode.position
            touchState.start.projectionDepthPosition = sceneView.projectPoint(touchState.start.positioningNode.position)
            touchState.start.computeStartUnprojection(in: sceneView)
        }

        if receiver.state == .ended {
            touchState.start = TouchStart()
            touchState.valid = false
            print("-- Ended pan")
        }
    }
}

struct TouchState {
    var valid: Bool = false
    var start = TouchStart()
}

struct TouchStart {
    var gesturePoint = CGPoint()
    var positioningNode = SCNNode()

    var positioningNodeStart = SCNVector3Zero
    var positioningNodeEulers = SCNVector3Zero
    var projectionDepthPosition = SCNVector3Zero
    var computedStartUnprojection = SCNVector3Zero

    mutating func computeStartUnprojection(in scene: SCNView) {
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
