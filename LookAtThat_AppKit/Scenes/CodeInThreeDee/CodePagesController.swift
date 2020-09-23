import Foundation
import SceneKit
import SwiftSyntax
import Combine

var z = CGFloat(0)
var nextZ: CGFloat {
    z -= 50
    return z
}

class CodePagesController: BaseSceneController {

    let iteratorY = WordPositionIterator()
    var bumped = Set<Int>()
    let highlightCache = HighlightCache()

    let wordNodeBuilder: WordNodeBuilder
    let syntaxNodeParser: SwiftSyntaxParser

    var cancellables = Set<AnyCancellable>()

    init(sceneView: SCNView,
         wordNodeBuilder: WordNodeBuilder) {
        self.wordNodeBuilder = wordNodeBuilder
        self.syntaxNodeParser = SwiftSyntaxParser(wordNodeBuilder: wordNodeBuilder)
        super.init(sceneView: sceneView)
    }

    func attachMouseSink() {
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

    func newScrollEvent(_ event: NSEvent) {
        sceneTransaction(0) {
            let sensitivity = CGFloat(1.5)
            let scaledX = -event.deltaX * sensitivity
            let scaledY = event.deltaY * sensitivity
            if event.modifierFlags.contains(.command) {
                let translate = SCNMatrix4MakeTranslation(scaledX, scaledY, 0)
                sceneCameraNode.transform = SCNMatrix4Mult(translate, sceneCameraNode.transform)
            } else {
                let translate = SCNMatrix4MakeTranslation(scaledX, 0, scaledY)
                sceneCameraNode.transform = SCNMatrix4Mult(translate, sceneCameraNode.transform)
            }
        }
    }

    func newMousePosition(_ point: CGPoint) {
        let hoverEnabled = false
        let hoverTranslationY = CGFloat(50)
        guard hoverEnabled else { return }

        let newMouseHoverSheet =
            self.sceneView.hitTestCodeSheet(with: point).first?.node.parent

        let currentHoveredSheet =
            touchState.mouse.currentHoveredSheet

        if currentHoveredSheet == nil, let newSheet = newMouseHoverSheet {
            touchState.mouse.currentHoveredSheet = newSheet
            sceneTransaction {
                newSheet.position.y += hoverTranslationY
            }
        } else if let currentSheet = currentHoveredSheet, currentSheet != newMouseHoverSheet {
            touchState.mouse.currentHoveredSheet = newMouseHoverSheet
            sceneTransaction {
                currentSheet.position.y -= hoverTranslationY
                newMouseHoverSheet?.position.y += hoverTranslationY
            }
        }
    }

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
                self.syntaxNodeParser.render(
                    source: fileUrl,
                    in: self.sceneState
                )
                // AFTER ALL THAT THE ISSUE WAS THE MAIN THREAD.
                // DAMN IT.
                self.main.async {
                    handler(self.syntaxNodeParser.resultInfo)
                }
            }
        }
    }

    func renderDirectory(_ handler: @escaping (SourceInfo) -> Void) {
        syntaxNodeParser.requestSourceDirectory{ directory in
            self.workerQueue.async {
                for url in directory.swiftUrls {
                    self.syntaxNodeParser.render(
                        source: url,
                        in: self.sceneState
                    )
                }

                // AFTER ALL THAT THE ISSUE WAS THE MAIN THREAD.
                // DAMN IT.
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
        forEach {
            let lastWordPosition: SCNVector3
            if let lastNode = lastNode {
                let lastWordSize = lastNode.lengthX
                lastWordPosition = lastNode.position.translated(dX: lastWordSize)
            } else {
                if let lastChild = node.childNodes.last {
                    lastWordPosition = lastChild.position.translated(dX: lastChild.lengthX)
                } else {
                    lastWordPosition = SCNVector3Zero
                }
            }
            $0.position = lastWordPosition
            node.addChildNode($0)
            lastNode = $0
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
                lastWordPosition = lastNode.position.translated(dX: lastWordSize)
            } else {
                lastWordPosition = SCNVector3Zero
            }
            $0.position = lastWordPosition
            node.addChildNode($0)
            lastNode = $0
        }
    }
}
