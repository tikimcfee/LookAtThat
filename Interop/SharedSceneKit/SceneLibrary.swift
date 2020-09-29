import Foundation
import SceneKit
import Combine

enum SceneType {
    case source
    case dictionary
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
    var cancellables = Set<AnyCancellable>()

    #if os(OSX)
    private let mouseSubject = CurrentValueSubject<CGPoint, Never>(CGPoint.zero)
    private let scrollSubject = CurrentValueSubject<NSEvent, Never>(NSEvent())
    private let mouseDownSubject = CurrentValueSubject<NSEvent, Never>(NSEvent())
    let sharedMouse: AnyPublisher<CGPoint, Never>
    let sharedScroll: AnyPublisher<NSEvent, Never>
    let sharedMouseDown: AnyPublisher<NSEvent, Never>
    var mousePosition: CGPoint = CGPoint.zero {
        didSet { mouseSubject.send(mousePosition) }
    }
    var scrollEvent: NSEvent = NSEvent() {
        didSet { scrollSubject.send(scrollEvent) }
    }
    var mouseDownEvent: NSEvent = NSEvent() {
        didSet { mouseDownSubject.send(mouseDownEvent) }
    }
    #elseif os(iOS)
    var mousePosition: CGPoint = CGPoint.zero {
        didSet { }
    }
    var scrollEvent: UIEvent = UIEvent() {
        didSet { }
    }
    var mouseDownEvent: UIEvent = UIEvent() {
        didSet { }
    }
    #endif

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
        #if os(OSX)
        self.sharedMouse = mouseSubject.share().eraseToAnyPublisher()
        self.sharedScroll = scrollSubject.share().eraseToAnyPublisher()
        self.sharedMouseDown = mouseDownSubject.share().eraseToAnyPublisher()
        #endif
        self.currentController = codePagesController
        self.currentMode = .source
        self.sharedSceneView.positionReceiver = self

        codePages()
        attachSheetStream()
    }

    func attachSheetStream() {
        #if os(iOS)
        MultipeerConnectionManager.shared.codeSheetStream
            .subscribe(on: DispatchQueue.global())
            .receive(on: RunLoop.main)
            .sink{ [weak self] codeSheets in
                print("Updating code sheets...")
                guard let newSheet = codeSheets.last else {
                    print("It was empty... but why?")
                    return
                }
                sceneTransaction {
                    let sheetNode = newSheet.containerNode
                    sheetNode.scale = SCNVector3Make(0.001, 0.001, 0.001)
                    sheetNode.position =
                        self?.currentController.sceneView.pointOfView?.position.translated(dZ: -0.5)
                        ?? SCNVector3Make(0.0, 0.0, -0.5)
                    self?.currentController.scene.rootNode.addChildNode(sheetNode)
                    print("Adding sheet to ", sheetNode.position, "|", sheetNode.lengthX)
                }
            }
            .store(in: &cancellables)
        #endif
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
