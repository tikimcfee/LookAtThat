import Foundation
import SwiftUI
import SceneKit


extension MainSceneController {
    func makeScene() -> SCNScene {
        let scene = SCNScene()
        return scene
    }

    func makeSceneView() -> SCNView {
        let view = SCNView()
//        view.debugOptions.insert(.showBoundingBoxes)
        return view
    }

    private func makeSceneCamera() -> SCNCamera {
        let camera = SCNCamera()
        camera.zFar = 2000
        return camera
    }

    func makeSceneCameraNode() -> SCNNode {
        let cameraNode = SCNNode()
        cameraNode.camera = makeSceneCamera()
        cameraNode.position = SCNVector3Make(0, 0, 150)
        return cameraNode
    }
}

extension MainSceneController {
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

    func resetScene() {
        lockedSceneTransaction {
            sceneState.rootGeometryNode.removeFromParentNode()
            sceneState.rootGeometryNode = SCNNode()
            scene.rootNode.addChildNode(sceneState.rootGeometryNode)
            iteratorY.reset()
        }
    }
}

class MainSceneController {

    public static let global = MainSceneController()
    
    lazy var sceneState = SceneState()
    lazy var wordParser = WordParser()
    lazy var wordNodeBuilder = WordNodeBuilder()
    lazy var syntaxNodeBuilder = AbstractSyntaxTreeVisitor()
    lazy var iteratorY = WordPositionIterator()
    lazy var sceneControllerQueue = DispatchQueue(label: "SceneController", qos: .userInteractive)

    lazy var scene: SCNScene = makeScene()
    lazy var sceneView: SCNView = makeSceneView()
    lazy var sceneCamera: SCNCamera = makeSceneCamera()
    lazy var sceneCameraNode: SCNNode = makeSceneCameraNode()

    lazy var panGestureRecognizer = ModifiersPanGestureRecognizer(target: self, action: #selector(pan))
    lazy var touchState = TouchState()

    private lazy var setupWorkers = (0..<8).map { DispatchQueue(label: "Q\($0)", qos: .userInteractive) }
    private lazy var workerIterator = setupWorkers.makeIterator()
    func nextWorker() -> DispatchQueue {
        if let iterator = workerIterator.next() {
            return iterator
        } else {
            workerIterator = setupWorkers.makeIterator()
            let next = workerIterator.next()!
            return next
        }
    }

    init() {
        setupScene()
    }

    private func setupScene() {
        sceneView.backgroundColor = NSUIColor.gray

        attachPanRecognizer()
//        sceneView.allowsCameraControl = true

        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light!.type = SCNLight.LightType.ambient
        ambientLightNode.light!.color = NSUIColor(white: 0.67, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLightNode)

        let omniLightNode = SCNNode()
        omniLightNode.light = SCNLight()
        omniLightNode.light!.type = SCNLight.LightType.omni
        omniLightNode.light!.color = NSUIColor(white: 0.75, alpha: 1.0)
        omniLightNode.position = SCNVector3Make(0, 50, 50)
        scene.rootNode.addChildNode(omniLightNode)

        scene.rootNode.addChildNode(sceneCameraNode)
        scene.rootNode.addChildNode(sceneState.rootGeometryNode)

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
}

class WordPositionIterator {
    let linesPerBlock = CGFloat(WORD_FONT_POINT_SIZE + LINE_MARGIN_HEIGHT)
    let wordYSemaphore = DispatchSemaphore(value: 1)
    var wordY = CGFloat(0)

    func reset(_ to: CGFloat = 0) {
        wordY = to
    }

    func nextLineY() -> CGFloat {
        wordY -= linesPerBlock
        return wordY
    }

    func nextPosition() -> SCNVector3 {
        return SCNVector3(x: -100, y: nextLineY(), z: -25)
    }

    func wordIndicesForWordCount(_ words: Int) -> [SCNVector3] {
        wordYSemaphore.wait()
        defer { wordYSemaphore.signal() }
        return (0..<words).map{ _ in SCNVector3(-100, nextLineY(), -25) }
    }
}

class SceneState {
    // Geometry
    var rootGeometryNode: SCNNode = SCNNode()
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

