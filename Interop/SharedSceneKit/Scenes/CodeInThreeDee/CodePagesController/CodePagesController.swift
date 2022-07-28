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
    
    lazy var appStatus = AppStatus()
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
    
    override func onTapGesture(_ event: GestureEvent) {
        self.onTapGestureOverrideImpl(event)
    }
    
    override func sceneActive() {
        // Looming bug here: all of these compat and local objects
        // are mostly lazy, plenty of implicit static loads.
        // This dispatch is an unsafe timing hack to to handle
        // UI display timing. WIthout logs to back it up, memory
        // serves it was observers not being ready, instances being
        // nil because of recursive definitions, and others.
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

// MARK: - File Events

extension CodePagesController {
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
                doTestRender(parent: parent)
                
            default: break
            }
            
            
        case let .newMultiCommandRecursiveAllCache(parent):
            print("Start cache: \(parent.fileName)")
            codeGridParser.cacheConcurrent(parent) {
                print("Cache complete: \(parent.fileName)")
            }
            
            
        }
    }
}

extension CodePagesController {
    func doTestRender(parent: URL) {
        codeGridParser.__versionThree_RenderConcurrent(parent) { rootGrid in
            self.addToRoot(rootGrid: rootGrid)
        }
    }
    
    func doRenderPlan(parent: URL) {
        RenderPlan(
            rootPath: parent,
            queue: codeGridParser.renderQueue,
            renderer: codeGridParser.concurrency
        ).startRender(onComplete: [
            { root in
                print("RenderPlan, activate | ",  root.rootNode.name ?? "unnamed node")
                self.appStatus.update { $0.isActive = true }
            },
            { root in
                print("RenderPlan, first callback | ",  root.rootNode.name ?? "unnamed node")
                // DAE: Swift Cherrier View, CLI action
                /// Given a directory, render CherrierView[yourFileName|Default].dae and output to current directory.
                /// swift cherrier-View .
                //
//                try self.writeScene()
            },
            { root in
                print("RenderPlan, deactivate | ",  root.rootNode.name ?? "unnamed node")
                self.appStatus.update { $0.isActive = false }
            }
        ])
    }
}

// MARK: - CherrieiSupport

extension CodePagesController {
    
    typealias CVResult = Result<Void, Error>
    typealias CVReceiver = (CVResult) -> Void
    
    func cherrieiRenderSceneFor(
        path root: URL,
        to target: URL,
        _ receiver: @escaping CVReceiver
    ) {
        print("Cherriei:", root, target)
        compat.inputCompat.searchController.mode = .inPlace
        
        RenderPlan(
            rootPath: root,
            queue: codeGridParser.renderQueue,
            renderer: codeGridParser.concurrency
        ).startRender(onComplete: [
            { root in
                let semaphore = DispatchSemaphore(value: 0)
                let term = "SwiftSyntax"
                print("Starting search: \(term)")
                self.compat.inputCompat.doNewSearch("SwiftSyntax", self.sceneState) {
                    print("Received search completion")
                    
                    let parent = root.rootNode.parent
                    let cloned = root.rootNode.flattenedClone()
                    root.rootNode.removeFromParentNode()
                    parent?.addChildNode(cloned)
                    
                    semaphore.signal()
                }
                semaphore.wait()
            },
            { root in
                let stopWatch = Stopwatch(running: true)
                self.writeSceneWithoutProgress(to: target)
                stopWatch.stop()
                
                print("Wrote scene: \(stopWatch.elapsedTimeString())")
                receiver(.success(()))
            }
        ])
    }
    
}

// MARK: - Scene actions

extension CodePagesController {
    func writeSceneWithoutProgress(
        to target: URL
    ) {
        sceneTransaction {
            self.scene.write(
                to: target,
                options: [:],
                delegate: nil,
                progressHandler: nil
            )
        }
    }
    
    func writeScene(
        to target: URL = AppFiles.defaultSceneOutputFile
    ) throws {
        weak var status = appStatus
        func progressHandlerForwardingFunction(
            _ float: Float,
            _ error: Error?,
            _ bool: UnsafeMutablePointer<ObjCBool>
        ) {
            status?.update {
                $0.totalValue = 100.0
                $0.currentValue = Double(float * 100.0)
                
                if $0.currentValue < $0.totalValue {
                    $0.message = "Writing output to \(target)"
                } else {
                    $0.message = "Progress complete, showing \(target)"
                    showInFinder(url: target)
                }
                
                if let error = error {
                    print("Scene writing error: ", error)
                    $0.detail = error.localizedDescription
                }
            }
        }
        sceneTransaction {
            self.scene.write(
                to: target,
                options: [:],
                delegate: nil,
                progressHandler: progressHandlerForwardingFunction(_:_:_:)
            )
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
    
}

// MARK: - Gesture overrides

private extension CodePagesController {
    func onTapGestureOverrideImpl(_ event: GestureEvent) {
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
