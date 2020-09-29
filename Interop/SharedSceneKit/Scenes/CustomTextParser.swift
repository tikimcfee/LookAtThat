import Foundation
import SwiftUI
import SceneKit

class CustomTextParser: BaseSceneController {

    let wordParser = WordParser()
    let iteratorY = WordPositionIterator()
    let wordNodeBuilder: WordNodeBuilder

    init(sceneView: CustomSceneView,
         wordNodeBuilder: WordNodeBuilder) {
        self.wordNodeBuilder = wordNodeBuilder
        super.init(sceneView: sceneView)
    }

    override func onSceneStateReset() {
        iteratorY.reset()
    }

    private func customRender() {
        wordParser.testSourceFileLines.forEach{ sourceLine in // source; "x = x + 1"
            let lineNode = SCNNode()
            lineNode.position = iteratorY.nextPosition()
            sourceLine.splitToWordsAndSpaces
                .map{ wordNodeBuilder.node(for: $0) }
                .arrangeInLine(on: lineNode)

            sceneTransaction {
                self.sceneState.rootGeometryNode.addChildNode(lineNode)
            }
        }
    }
}
