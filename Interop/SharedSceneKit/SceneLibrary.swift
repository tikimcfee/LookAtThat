import Foundation
import SceneKit
import Combine

enum SceneType {
    case source
}

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
        
        #if os(OSX)
        self.sharedSceneView.keyDownReceiver = input
        #endif
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
