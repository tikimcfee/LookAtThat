import Foundation
import SceneKit

class DragonAnimationLoop {
    let LENGTH = CGFloat(25)
    let DURATION = 2.0
    var randomLength: CGFloat { return (Bool.random() ? -1 : 1) * LENGTH }

    let targetNode: SCNNode

    func makeNewConfigs() -> [(String, CGFloat, CGFloat)] {
        return [
            // kept the keypath name in case we use CAAnimations again
            ("position.x", targetNode.position.x, targetNode.position.x + randomLength),
            ("position.y", targetNode.position.y, targetNode.position.y + randomLength),
            ("position.z", targetNode.position.z, targetNode.position.z + randomLength)
        ]
    }

    func makeMoveVector() -> SCNVector3 {
        let configs = makeNewConfigs()
        return SCNVector3(x: configs[0].2, y: configs[1].2, z: configs[2].2)
    }

    func makeMoveAction() -> SCNAction {
        let action = SCNAction.move(to: makeMoveVector(), duration: DURATION)
        action.timingMode = .linear
        return action
    }

    @discardableResult
    init(_ node: SCNNode) {
        self.targetNode = node
        simpleLoop()
    }

    private func simpleLoop() {
        targetNode.runAction(makeMoveAction()) {
            sceneTransaction {
                self.simpleLoop()
            }
        }
    }

    private func bezierLoop() {
        let bezier = (0..<5).map{ _ in makeMoveVector() }
        let path = SCNAction.moveAlong(bezier: bezier, duration: 5.0)
        targetNode.runAction(path) {
            sceneTransaction {
                self.bezierLoop()
            }
        }
    }
}
