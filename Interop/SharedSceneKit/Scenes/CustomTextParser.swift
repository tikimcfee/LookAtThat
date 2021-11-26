import Foundation
import SwiftUI
import SceneKit

class CustomTextParser: BaseSceneController {
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
        
    }
}
