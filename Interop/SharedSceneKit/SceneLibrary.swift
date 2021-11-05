import Foundation
import SceneKit
import Combine

enum SceneType {
    case source
    case dictionary
}

class SceneLibrary: ObservableObject, MousePositionReceiver, KeyDownReceiver  {
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
    private let keyEventSubject = CurrentValueSubject<NSEvent, Never>(NSEvent())
    private let keyDownEventSubject = CurrentValueSubject<NSEvent, Never>(NSEvent())
    private let keyUpEventSubject = CurrentValueSubject<NSEvent, Never>(NSEvent())
    
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
    
    let sharedKeyEvent: AnyPublisher<NSEvent, Never>
    let sharedKeyUpEvent: AnyPublisher<NSEvent, Never>
    let sharedKeyDownEvent: AnyPublisher<NSEvent, Never>
    var lastKeyDownEvent: NSEvent = NSEvent() {
        didSet { keyDownEventSubject.send(lastKeyDownEvent) }
    }
    var lastKeyUpEvent: NSEvent = NSEvent() {
        didSet { keyUpEventSubject.send(lastKeyUpEvent) }
    }
    var lastKeyEvent: NSEvent = NSEvent() {
        didSet { keyEventSubject.send(lastKeyEvent) }
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
    var lastKeyEvent: KeyEvent = .none {
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
        // Mouse movement
        self.sharedMouse = mouseSubject.share().eraseToAnyPublisher()
        self.sharedScroll = scrollSubject.share().eraseToAnyPublisher()
        self.sharedMouseDown = mouseDownSubject.share().eraseToAnyPublisher()
        
        // Keyboard events
        self.sharedKeyEvent = keyEventSubject
            .filter { event in event.type == .keyDown || event.type == .keyUp }
            .share().eraseToAnyPublisher()
        self.sharedKeyDownEvent = keyDownEventSubject
            .filter { event in event.type == .keyDown }
            .share().eraseToAnyPublisher()
        self.sharedKeyUpEvent = keyUpEventSubject
            .filter { event in event.type == .keyUp }
            .share().eraseToAnyPublisher()
        #endif
        
        self.currentController = codePagesController
        self.currentMode = .source
        self.sharedSceneView.positionReceiver = self
        self.sharedSceneView.keyDownReceiver = self

        codePages()
        attachSheetStream()
    }

    func attachSheetStream() {
        #if os(iOS)
        MultipeerConnectionManager.shared.codeSheetStream
            .subscribe(on: DispatchQueue.global())
            .receive(on: RunLoop.main)
            .sink{ [weak self] codeSheets in
                self?.receiveSheets(codeSheets)
            }
            .store(in: &cancellables)
        #endif
    }

    private func receiveSheets(_ codeSheets: [CodeSheet]) {
        print("Updating code sheets...")
        guard let newSheet = codeSheets.last else {
            print("It was empty... but why?")
            return
        }

        let sheetNode = newSheet.containerNode
        sheetNode.scale = SCNVector3Make(0.001, 0.001, 0.001)
        sheetNode.position =
            currentController.sceneView.pointOfView?.position.translated(dZ: -0.5)
            ?? SCNVector3Make(0.0, 0.0, -0.5)

        DispatchQueue.main.async {
            print("Adding sheet to ", sheetNode.position, "|", sheetNode.lengthX)
            sceneTransaction(0) {
                self.currentController.scene.rootNode.addChildNode(sheetNode)
            }
        }

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
