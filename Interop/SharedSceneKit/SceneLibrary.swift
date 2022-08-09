import Foundation
import SceneKit
import Combine

enum SceneType {
    case source
}

#if os(OSX)
class DefaultInputReceiver: ObservableObject, MousePositionReceiver, KeyDownReceiver {
    private let mouseSubject = PassthroughSubject<CGPoint, Never>()
    private let scrollSubject = PassthroughSubject<NSEvent, Never>()
    private let mouseDownSubject = PassthroughSubject<NSEvent, Never>()
    private let mouseUpSubject = PassthroughSubject<NSEvent, Never>()
    private let keyEventSubject = PassthroughSubject<NSEvent, Never>()
    
    lazy var sharedMouse = mouseSubject.share().eraseToAnyPublisher()
    lazy var sharedScroll = scrollSubject.share().eraseToAnyPublisher()
    lazy var sharedMouseDown = mouseDownSubject.share().eraseToAnyPublisher()
    lazy var sharedMouseUp = mouseUpSubject.share().eraseToAnyPublisher()
    lazy var sharedKeyEvent = keyEventSubject.share().eraseToAnyPublisher()
    
    var mousePosition: CGPoint = CGPoint.zero {
        didSet { mouseSubject.send(mousePosition) }
    }
    
    var scrollEvent: NSEvent = NSEvent() {
        didSet { scrollSubject.send(scrollEvent) }
    }
    
    var mouseDownEvent: NSEvent = NSEvent() {
        didSet { mouseDownSubject.send(mouseDownEvent) }
    }
    
    var mouseUpEvent: NSEvent = NSEvent() {
        didSet { mouseUpSubject.send(mouseUpEvent) }
    }
    
    var lastKeyEvent: NSEvent = NSEvent() {
        didSet { keyEventSubject.send(lastKeyEvent) }
    }
}
#elseif os(iOS)
class DefaultInputReceiver: ObservableObject, MousePositionReceiver {
    private let mouseSubject = PassthroughSubject<CGPoint, Never>()
    private let scrollSubject = PassthroughSubject<NSEvent, Never>()
    private let mouseDownSubject = PassthroughSubject<NSEvent, Never>()
    private let mouseUpSubject = PassthroughSubject<NSEvent, Never>()
    
    lazy var sharedMouse = mouseSubject.share().eraseToAnyPublisher()
    lazy var sharedScroll = scrollSubject.share().eraseToAnyPublisher()
    lazy var sharedMouseDown = mouseDownSubject.share().eraseToAnyPublisher()
    lazy var sharedMouseUp = mouseUpSubject.share().eraseToAnyPublisher()
    lazy var sharedKeyEvent = keyEventSubject.share().eraseToAnyPublisher()
    
    var mousePosition: CGPoint = CGPoint.zero {
        didSet { mouseSubject.send(mousePosition) }
    }
    
    var scrollEvent: NSEvent = NSEvent() {
        didSet { scrollSubject.send(scrollEvent) }
    }
    
    var mouseDownEvent: NSEvent = NSEvent() {
        didSet { mouseDownSubject.send(mouseDownEvent) }
    }
    
    var mouseUpEvent: NSEvent = NSEvent() {
        didSet { mouseUpSubject.send(mouseUpEvent) }
    }
    
    var lastKeyEvent: NSEvent = NSEvent() {
        didSet { keyEventSubject.send(lastKeyEvent) }
    }
}
#endif

class SceneLibrary: ObservableObject   {
    public static let global = SceneLibrary()

    let codePagesController: CodePagesController

    let sharedSceneView: CustomSceneView = {
        let sceneView = CustomSceneView(
            
        )
        return sceneView
    }()

    @Published var currentMode: SceneType
    var currentController: SceneControls
    var cancellables = Set<AnyCancellable>()
    let input = DefaultInputReceiver()

    private init() {
        self.codePagesController = CodePagesController(sceneView: sharedSceneView)

        // Unsafe initialization from .global ... more refactoring inc?
        
        self.currentController = codePagesController
        self.currentMode = .source
        
        self.sharedSceneView.keyDownReceiver = input
        self.sharedSceneView.positionReceiver = input

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

    func codePages() {
        currentController.sceneInactive()
        codePagesController.setupScene()
        currentController = codePagesController
        currentMode = .source
        currentController.sceneActive()
    }
    
}
