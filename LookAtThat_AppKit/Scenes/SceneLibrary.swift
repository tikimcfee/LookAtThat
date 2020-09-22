import Foundation
import SceneKit

enum SceneType {
    case source
    case dictionary
}

protocol MousePositionReceiver: class {
    var mousePosition: CGPoint { get set }
}

class CustomSceneView: SCNView {

    lazy var trackingOptions: NSTrackingArea.Options =
        [.mouseEnteredAndExited, .mouseMoved, .activeInKeyWindow, .activeAlways]

    var trackingArea : NSTrackingArea?

    weak var positionReceiver: MousePositionReceiver?

    override func updateTrackingAreas() {
        if let trackingArea = trackingArea {
            removeTrackingArea(trackingArea)
        }
        trackingArea = NSTrackingArea(rect: bounds,
                                      options: trackingOptions,
                                      owner: self,
                                      userInfo: nil)
        self.addTrackingArea(trackingArea!)
    }

    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        guard let receiver = positionReceiver else { return }
        let convertedPosition = convert(event.locationInWindow, from: nil)
        receiver.mousePosition = convertedPosition
    }
}

class SceneLibrary: ObservableObject, MousePositionReceiver {
    public static let global = SceneLibrary()

    let wordNodeBuilder = WordNodeBuilder()
    let customTextController: CustomTextParser
    let codePagesController: CodePagesController
    let dictionaryController: DictionarySceneController

    let sharedSceneView: CustomSceneView = {
        let sceneView = CustomSceneView()
        return sceneView
    }()

    @Published var currentMode: SceneType
    var currentController: SceneControls
    var mousePosition: CGPoint = CGPoint.zero

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
        sharedSceneView.positionReceiver = self
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
