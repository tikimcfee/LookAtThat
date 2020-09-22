import Foundation
import SceneKit
import Combine

enum SceneType {
    case source
    case dictionary
}

protocol MousePositionReceiver: class {
    var mousePosition: CGPoint { get set }
    var scrollEvent: NSEvent { get set }
}

class CustomSceneView: SCNView {
    weak var positionReceiver: MousePositionReceiver?
    var trackingArea : NSTrackingArea?

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

    private let mouseSubject = CurrentValueSubject<CGPoint, Never>(CGPoint.zero)
    private let scrollSubject = CurrentValueSubject<NSEvent, Never>(NSEvent())
    let sharedMouse: AnyPublisher<CGPoint, Never>
    let sharedScroll: AnyPublisher<NSEvent, Never>
    var mousePosition: CGPoint = CGPoint.zero {
        didSet { mouseSubject.send(mousePosition) }
    }
    var scrollEvent: NSEvent = NSEvent() {
        didSet { scrollSubject.send(scrollEvent) }
    }

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

        // Unsafe initialization from .global ... more refactoring inc?
        self.sharedMouse = mouseSubject.share().eraseToAnyPublisher()
        self.sharedScroll = scrollSubject.share().eraseToAnyPublisher()
        self.currentController = codePagesController
        self.currentMode = .source
        self.sharedSceneView.positionReceiver = self

        codePages()
    }

    func customText() {
        currentController.sceneInactive()
        customTextController.setupScene()
        currentController = customTextController
        currentController.sceneActive()
    }

    func dictionary() {
        currentController.sceneInactive()
        dictionaryController.setupScene()
        currentController = dictionaryController
        currentMode = .dictionary
        currentController.sceneActive()
    }

    func codePages() {
        currentController.sceneInactive()
        codePagesController.setupScene()
        currentController = codePagesController
        currentMode = .source
        currentController.sceneActive()
    }
    
}
