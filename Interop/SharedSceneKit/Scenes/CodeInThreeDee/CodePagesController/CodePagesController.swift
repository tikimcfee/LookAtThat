import Foundation
import SceneKit
import SwiftSyntax
import Combine
import SwiftUI

extension CodePagesController {
    static var shared: CodePagesController {
        SceneLibrary.global.codePagesController
    }
}

class CodePagesController: BaseSceneController, ObservableObject {
        
    let codeGridParser: CodeGridParser
    
    lazy var editorState = CodePagesPopupEditorState()
    lazy var hover = CodeGridHoverController()
    lazy var selection = CodeGridSelectionController(parser: codeGridParser)
    lazy var trace = CodeGridTraceController(parser: codeGridParser)
    lazy var globalSemantics = CodeGridGlobalSemantics(source: codeGridParser.gridCache)
    
    let fileBrowser = FileBrowser()
    lazy var fileStream = fileBrowser.$scopes.share().eraseToAnyPublisher()
    lazy var fileEventStream = fileBrowser.$fileSelectionEvents.share().eraseToAnyPublisher()

    var cancellables = Set<AnyCancellable>()

#if os(macOS)
    lazy var compat = CodePagesControllerMacOSCompat(
        controller: self
    )
    var commandHandler: CommandHandler { compat }
#elseif os(iOS)
    lazy var compat = ControlleriOSCompat(
        controller: self
    )
    var commandHandler: CommandHandler { compat }
#endif

    override init(sceneView: CustomSceneView) {
        self.codeGridParser = CodeGridParser()
        super.init(sceneView: sceneView)
        
        if let pointOfView = sceneView.pointOfView {
            print("CodePagesController using point of view for camera node")
            codeGridParser.cameraNode = pointOfView
        } else {
            codeGridParser.cameraNode = sceneCameraNode
        }
        codeGridParser.rootGeometryNode = sceneState.rootGeometryNode
    }
    
    func onNewFileStreamEvent(_ event: FileBrowser.Event) {
        switch event {
        case .noSelection:
            break
            
        case let .newSingleCommand(path, style):
            commandHandler.handleSingleCommand(path, style)
            
        case let .newMultiCommandRecursiveAllLayout(parent, style):
            switch style {
            case .addToFocus:
                let sem = DispatchSemaphore(value: 1)
                codeGridParser.__versionThree_RenderImmediate(parent) { path, grid in
                    sem.wait()
                    self.compat.doAddToFocus(grid)
                    sem.signal()
                }
            case .addToWorld:
//                 Touch and cylinder layout isn't precise / visually usable enough for iOS.... yet
                #if os(iOS)
                codeGridParser.__versionThree_RenderConcurrent(parent) { rootGrid in
                    self.addToRoot(rootGrid: rootGrid)
                }
                #else
                RenderPlan(
                    rootPath: parent,
                    queue: codeGridParser.renderQueue,
                    renderer: codeGridParser.concurrency
                ).startRender { _ in }
                #endif
                

            default: break
            }

            
        case let .newMultiCommandRecursiveAllCache(parent):
            print("Start cache: \(parent.fileName)")
            codeGridParser.cacheConcurrent(parent) {
                print("Cache complete: \(parent.fileName)")
            }
        }
    }
    
    func addToRoot(rootGrid: CodeGrid) {
#if os(iOS)
        codeGridParser.editorWrapper.addInFrontOfCamera(grid: rootGrid)
#else
        sceneState.rootGeometryNode.addChildNode(rootGrid.rootNode)
        rootGrid.translated(
            dX: -rootGrid.measures.lengthX / 2.0,
            dY: rootGrid.measures.lengthY / 2.0,
            dZ: -2000
        )
#endif
    }
    
    override func sceneActive() {
        // This is pretty dumb. I have the scene library global, and it automatically inits this.
        // However, this tries to attach immediately.. by accessing the init'ing global.
        //                 This is why we don't .global =(
        // Anyway, dispatch for now with no guarantee of success.
#if os(OSX)
        DispatchQueue.main.async {
            self.compat.attachMouseSink()
            self.compat.attachKeyInputSink()
            self.compat.attachEventSink()
            self.compat.attachSearchInputSink()
        }
#elseif os(iOS)
        DispatchQueue.main.async {
            self.compat.attachEventSink()
            self.compat.attachSearchInputSink()
        }
#endif

    }

    override func sceneInactive() {
        cancellables = Set()
    }

    override func onSceneStateReset() {
        // Clear out all the grids and things
        compat.inputCompat.focus.resetState()
        compat.inputCompat.focus.setNewFocus()
    }
    
    // MARK: - Gesture overrides
    override func onTapGesture(_ event: GestureEvent) {
        guard event.type == .deviceTap else { return }
        
        let location = event.currentLocation
        let found = HitTestEvaluator(controller: SceneLibrary.global.codePagesController)
            .testAndEval(location, [.codeGridControl, .codeGrid])
        
        for result in found {
            switch result {
            case let .grid(codeGrid):
                #if !TARGETING_SUI
                guard let path = codeGrid.sourcePath else {
                    print("Grid does not have active path: \(codeGrid.fileName) -> \(codeGrid)")
                    return
                }
                editorState.rootMode = .editing(grid: codeGrid, path: path)
                #else
                codeGrid.toggleGlyphs()
                #endif
            case let .control(codeGridControl):
                codeGridControl.activate()
            default:
                break
            }
        }
    }
}

extension Set where Element == SyntaxIdentifier {
    mutating func toggle(_ id: SyntaxIdentifier) -> Bool {
        if contains(id) {
            remove(id)
            return false
        } else {
            insert(id)
            return true
        }
    }
}

//MARK: - Path tracing

extension CodePagesController {
    func zoom(to grid: CodeGrid) {
        sceneTransaction {
            let newPosition = grid.rootNode.worldPosition.translated(
                dX: grid.measures.lengthX / 2.0,
                dY: 0,
                dZ: 125
            )
            sceneState.cameraNode.worldPosition = newPosition
        }
    }
}

// MARK: File loading

extension CodePagesController {
    func requestSetRootDirectory() {
        #if os(OSX)
        selectDirectory { result in
            switch result {
            case .failure(let error):
                print(error)
                
            case .success(let directory):
                self.fileBrowser.setRootScope(directory.parent)
            }
        }
        #endif
    }
    
    func requestSourceFile(_ receiver: @escaping (URL) -> Void) {
        openFile { fileReslt in
            switch fileReslt {
            case let .success(url):
                receiver(url)
            case let .failure(error):
                print(error)
            }
        }
    }
}
