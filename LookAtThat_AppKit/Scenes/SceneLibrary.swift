import Foundation
import SceneKit

enum SceneType {
    case source
    case dictionary
}

class SceneLibrary: ObservableObject {
    public static let global = SceneLibrary()

    let wordNodeBuilder = WordNodeBuilder()
    let customTextController: CustomTextParser
    let codePagesController: CodePagesController
    let dictionaryController: DictionarySceneController

    let sharedSceneView: SCNView = {
        let sceneView = SCNView()
        return sceneView
    }()

    @Published var currentMode: SceneType
    var currentController: SceneControls

    private init() {
        self.customTextController =
            CustomTextParser(sceneView: sharedSceneView,
                             wordNodeBuilder: wordNodeBuilder)
        self.codePagesController =
            CodePagesController(sceneView: sharedSceneView,
                                wordNodeBuilder: wordNodeBuilder)
        self.dictionaryController =
            DictionarySceneController(sceneView: sharedSceneView,
                                      wordNodeBuilder: wordNodeBuilder)

        codePagesController.setupScene()
        currentController = codePagesController
        currentMode = .source
    }

    func customText() {
        customTextController.setupScene()
        currentController = customTextController
    }

    func dictionary() {
        dictionaryController.setupScene()
        currentController = dictionaryController
        currentMode = .dictionary
    }

    func codePages() {
        codePagesController.setupScene()
        currentController = codePagesController
        currentMode = .source
    }
    
}
