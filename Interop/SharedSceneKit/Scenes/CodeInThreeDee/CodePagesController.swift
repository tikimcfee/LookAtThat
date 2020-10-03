import Foundation
import SceneKit
import SwiftSyntax
import Combine

var z = VectorFloat(0)
var nextZ: VectorFloat {
    z -= 15
    return z
}

class CodePagesController: BaseSceneController {

    let iteratorY = WordPositionIterator()
    var bumped = Set<Int>()
    let highlightCache = HighlightCache()

    let wordNodeBuilder: WordNodeBuilder
    let syntaxNodeParser: SwiftSyntaxParser

    var cancellables = Set<AnyCancellable>()

    init(sceneView: CustomSceneView,
         wordNodeBuilder: WordNodeBuilder) {
        self.wordNodeBuilder = wordNodeBuilder
        self.syntaxNodeParser = SwiftSyntaxParser(wordNodeBuilder: wordNodeBuilder)
        super.init(sceneView: sceneView)
    }

    func attachMouseSink() {
        #if os(OSX)
        SceneLibrary.global.sharedMouse
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] mousePosition in
                self?.newMousePosition(mousePosition)
            }
            .store(in: &cancellables)

        SceneLibrary.global.sharedScroll
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] scrollEvent in
                self?.newScrollEvent(scrollEvent)
            }
            .store(in: &cancellables)

        SceneLibrary.global.sharedMouseDown
            .receive(on: DispatchQueue.global(qos: .userInteractive))
            .sink { [weak self] downEvent in
                self?.newMouseDown(downEvent)
            }
            .store(in: &cancellables)
        #endif
    }

    override func sceneActive() {
        // This is pretty dumb. I have the scene library global, and it automatically inits this.
        // However, this tries to attach immediately.. by accessing the init'ing global.
        //                 This is why we don't .global =(
        // Anyway, dispatch for now with no guarantee of success.
        DispatchQueue.main.async {
            self.attachMouseSink()
        }
    }

    override func sceneInactive() {
        cancellables = Set()
    }

    override func onSceneStateReset() {
        iteratorY.reset()
    }
}


extension CodePagesController {

    func selected(name: String) {
        bumpNodes(
            allTokensWith(name: name)
        )
    }

    func highlightNode(_ node: SCNNode) {
        for letter in node.childNodes {
            letter.geometry = highlightCache[letter.geometry!]
        }
    }

    func bumpNodes(_ nodes: [SCNNode]) {
        sceneTransaction {
            for node in nodes {
                let hash = node.hash
                if bumped.contains(hash) {
                    bumped.remove(hash)
                    node.position = node.position.translated(dZ: -50)
                    highlightNode(node)
                } else {
                    bumped.insert(hash)
                    node.position = node.position.translated(dZ: 50)
                    highlightNode(node)
                }
            }
        }
    }

    func allTokensWith(name: String) -> [SCNNode] {
        return sceneState.rootGeometryNode.childNodes{ testNode, _ in
            return testNode.name == name
        }
    }

    func onTokensWith(type: String, _ operation: (SCNNode) -> Void) {
        sceneState.rootGeometryNode.enumerateChildNodes{ testNode, _ in
            if testNode.name?.contains(type) ?? false {
                operation(testNode)
            }
        }
    }

    func renderSyntax(_ handler: @escaping (SourceInfo) -> Void) {
        syntaxNodeParser.requestSourceFile { fileUrl in
            self.workerQueue.async {
                // todo: make a presenter or something oof
                self.syntaxNodeParser.prepareRendering(source: fileUrl)
                self.syntaxNodeParser.render(in: self.sceneState)
                self.main.async {
                    handler(self.syntaxNodeParser.resultInfo)
                }
            }
        }
    }

    func renderDirectory(_ handler: @escaping (SourceInfo) -> Void) {
        syntaxNodeParser.requestSourceDirectory{ directory in
            self.workerQueue.async {
                // todo: make a presenter or something oof
                for url in directory.swiftUrls {
                    self.syntaxNodeParser.prepareRendering(source: url)
                    self.syntaxNodeParser.render(in: self.sceneState)
                }
                self.main.async {
                    handler(self.syntaxNodeParser.resultInfo)
                }
            }
        }
    }
}

extension Array where Element == SCNNode {
    func arrangeInLine(on node: SCNNode) {
        var lastNode: SCNNode?
        forEach { wordNode in
            let lastWordPosition: SCNVector3
            if let lastNode = lastNode {
                lastWordPosition = lastNode.position.translated(dX: lastNode.lengthX)
            } else {
                if let lastChild = node.childNodes.last {
                    lastWordPosition = lastChild.position.translated(dX: lastChild.lengthX)
                } else {
                    lastWordPosition = SCNVector3Zero.translated(dY: -wordNode.lengthY)
                }
            }
            wordNode.position = lastWordPosition
            node.addChildNode(wordNode)
            lastNode = wordNode
        }
    }

    func appendToLine(on node: SCNNode) {
        var lastNode: SCNNode?
        forEach {
            let lastWordPosition: SCNVector3
            if let lastNode = lastNode {
                let lastWordSize =
                    lastNode.boundingBox.max.x -
                    lastNode.boundingBox.min.x
                lastWordPosition = lastNode.position.translated(dX: lastWordSize.vector)
            } else {
                lastWordPosition = SCNVector3Zero
            }
            $0.position = lastWordPosition
            node.addChildNode($0)
            lastNode = $0
        }
    }
}
