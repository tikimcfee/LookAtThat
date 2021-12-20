import SceneKit
import Foundation

protocol SceneControls {
    var scene: SCNScene { get }
    var sceneView: CustomSceneView { get }
    var sceneCamera: SCNCamera { get }
    var sceneCameraNode: SCNNode { get }

    var sceneState: SceneState { get set }
    var touchState: TouchState { get set }
    var panGestureShim: GestureShim { get set }

    var workerQueue: DispatchQueue { get }

    func setupScene()
    func resetScene()

    func sceneActive()
    func sceneInactive()
}

open class BaseSceneController: SceneControls {
    var sceneView: CustomSceneView
    lazy var scene: SCNScene = makeScene()
    lazy var sceneCamera: SCNCamera = makeSceneCamera()
    lazy var sceneCameraNode: SCNNode = makeSceneCameraNode()

    lazy var sceneState: SceneState = SceneState(cameraNode: sceneCameraNode)
    lazy var touchState = TouchState()

    lazy var panGestureShim: GestureShim = GestureShim(
        { self.pan($0) },
        { self.magnify($0) },
        { self.onTap($0) }
    )

    var workerQueue: DispatchQueue {
        return WorkerPool.shared.nextWorker()
    }

    var main: DispatchQueue {
        return DispatchQueue.main
    }

    // this is even more fragile. find a way to lock out subclasses
    private var awaitingInitialSetup = true

    init(sceneView: CustomSceneView) {
        self.sceneView = sceneView
    }

    open func makeScene() -> SCNScene {
        let scene = SCNScene()
        return scene
    }

    open func makeSceneCamera() -> SCNCamera {
        let camera = SCNCamera()
        camera.zFar = 2000
        return camera
    }

    open func makeSceneCameraNode() -> SCNNode {
        let cameraNode = SCNNode()
        cameraNode.camera = sceneCamera
        cameraNode.position = SCNVector3Make(0, 0, 150)
        return cameraNode
    }

    open func sceneActive() {
        
    }

    open func sceneInactive() {
        
    }

    open func setupScene() {
        guard awaitingInitialSetup else { return }
        awaitingInitialSetup = false
        setupDefaultScene()
    }

    private func setupDefaultScene() {
        sceneView.setupDefaultLighting()

        scene.rootNode.addChildNode(sceneState.rootGeometryNode)
        scene.rootNode.addChildNode(sceneCameraNode)

        attachPanRecognizer()
        attachMagnificationRecognizer()
        attachTapGestureRecognizer()

        // TODO: have a way to set the scene on completion of loading stuff
        // Seems logical to break down into preloaded scenes and then set on the view.
        // Some performance tests show that even when a scene is not added, it's doing
        // a lot of background work on a blocking thread (!!!).
        /**
         launch
         lock main thread
         load a scene *locked on that loading thread* (or N-scenes)
         unlock scene with *with a flush*, wait for flush finish, and then return
         When all scenes load, unlock main thread
         Hope real hard
        */
        sceneView.scene = scene
    }

    func resetScene() {
        lockedSceneTransaction {
            sceneState.rootGeometryNode.removeFromParentNode()
            sceneState.rootGeometryNode = SCNNode()
            scene.rootNode.addChildNode(sceneState.rootGeometryNode)
            onSceneStateReset()
        }
    }

    open func onSceneStateReset() {
        print("BaseSceneController resetting for '\(type(of: self))'")
    }
}

extension SceneControls {
    func toggleBoundingBoxes() {
        toggle(.showBoundingBoxes)
    }

    private func toggle(_ option: SCNDebugOptions) {
        if sceneView.debugOptions.contains(option) {
            sceneView.debugOptions.remove(option)
        } else {
            sceneView.debugOptions.insert(option)
        }
    }
}

final class WorkerPool {

    static let shared = WorkerPool()
    private let workerCount = 3

    private lazy var allWorkers =
        (0..<workerCount).map { DispatchQueue(
            label: "WorkerQ\($0)",
            qos: .userInteractive
        )}

    private lazy var concurrentWorkers =
        (0..<workerCount).map { DispatchQueue(
            label: "WorkerQC\($0)",
            qos: .userInitiated,
            attributes: .concurrent
        )}

    private lazy var workerIterator =
        allWorkers.makeIterator()

    private lazy var concurrentWorkerIterator =
        concurrentWorkers.makeIterator()

    private init() {}

    func nextWorker() -> DispatchQueue {
        return workerIterator.next() ?? {
            workerIterator = allWorkers.makeIterator()
            let next = workerIterator.next()!
            return next
        }()
    }

    func nextConcurrentWorker() -> DispatchQueue {
        return concurrentWorkerIterator.next() ?? {
            concurrentWorkerIterator = concurrentWorkers.makeIterator()
            let next = concurrentWorkerIterator.next()!
            return next
        }()
    }
}

protocol Actor: Hashable {
	func withCurrentSceneState() throws -> SceneState
}

class SceneState {

    var rootGeometryNode: SCNNode = SCNNode()
	var cameraNode: SCNNode
    
	init(cameraNode: SCNNode) {
        self.cameraNode = cameraNode
    }
}

enum SceneControllerError: Error, Identifiable {
    case missingWord(query: String)
    case noWordToTrack(query: String)

    typealias ID = String
    var id: String {
        switch self {
        case .missingWord(let query):
            return query
        case .noWordToTrack(let query):
            return query
        }
    }
}

