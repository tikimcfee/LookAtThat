import Foundation
import SceneKit
import Combine

enum SceneType {
    case source
    case dictionary
}

#if os(OSX)
extension SceneLibrary: KeyDownReceiver { }
#endif

class SceneLibrary: ObservableObject, MousePositionReceiver  {
    public static let global = SceneLibrary()

    let wordNodeBuilder = WordNodeBuilder()
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
    private let tracer = RuntimeTracer()
    
    private let mouseSubject = PassthroughSubject<CGPoint, Never>()
    private let scrollSubject = PassthroughSubject<NSEvent, Never>()
    private let mouseDownSubject = PassthroughSubject<NSEvent, Never>()
    private let keyEventSubject = PassthroughSubject<NSEvent, Never>()
    
    let sharedMouse: AnyPublisher<CGPoint, Never>
    let sharedScroll: AnyPublisher<NSEvent, Never>
    let sharedMouseDown: AnyPublisher<NSEvent, Never>
    let sharedKeyEvent: AnyPublisher<NSEvent, Never>
    
    var mousePosition: CGPoint = CGPoint.zero {
        didSet { mouseSubject.send(mousePosition) }
    }
    
    var scrollEvent: NSEvent = NSEvent() {
        didSet { scrollSubject.send(scrollEvent) }
    }
    
    var mouseDownEvent: NSEvent = NSEvent() {
        didSet { mouseDownSubject.send(mouseDownEvent) }
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
    var lastKeyEvent: UIEvent = UIEvent() {
        didSet { }
    }
    #endif

    private init() {
        self.codePagesController =
            CodePagesController(sceneView: sharedSceneView,
                                wordNodeBuilder: wordNodeBuilder)
        self.dictionaryController =
            DictionarySceneController(sceneView: sharedSceneView,
                                      wordNodeBuilder: wordNodeBuilder)

        // Unsafe initialization from .global ... more refactoring inc?
        
        self.currentController = codePagesController
        self.currentMode = .source
        
        #if os(OSX)
        // Mouse movement
        self.sharedMouse = mouseSubject.share().eraseToAnyPublisher()
        self.sharedScroll = scrollSubject.share().eraseToAnyPublisher()
        self.sharedMouseDown = mouseDownSubject.share().eraseToAnyPublisher()
        
        // Keyboard events
        self.sharedKeyEvent = keyEventSubject.share().eraseToAnyPublisher()
        self.sharedSceneView.keyDownReceiver = self
        #endif

        self.sharedSceneView.positionReceiver = self

        codePages()
        attachSheetStream()
    }

    func attachSheetStream() {
        #if os(iOS)
        MultipeerConnectionManager.shared.codeGridStream
            .subscribe(on: DispatchQueue.global())
            .receive(on: RunLoop.main)
            .sink{ [weak self] codeGrids in
                self?.receiveGrids(codeGrids)
            }
            .store(in: &cancellables)
        #endif
    }
    
    private func receiveGrids(_ codeGrids: [Data]) {
        print("Updating code grids boop beep...")
        guard let newGridData = codeGrids.last else {
            print("It was empty... but why?")
            return
        }
        
        guard let sourceString = String(data: newGridData, encoding: .utf8) else {
            print("After all that I didn't get a string? why are computers so hard even when they're easy?")
            return
        }
        
        codePagesController.codeGridParser.withNewGrid(sourceString) { world, grid in
            world.addInFrontOfCamera(grid: grid)
        }
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
