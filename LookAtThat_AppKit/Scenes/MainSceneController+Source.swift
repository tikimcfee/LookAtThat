import Foundation
import SceneKit
import SwiftSyntax

var z = CGFloat(0)
var nextZ: CGFloat {
    z -= 50
    return z
}

// ewww...
var bumped = Set<Int>()
let highlightCache = HighlightCache()

extension MainSceneController {

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
            return testNode.name?.contains(name) ?? false
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
        let nodes = SwiftSyntaxParser(wordNodeBuilder: wordNodeBuilder)
        nodes.requestSourceFile { fileUrl in
            self.sceneControllerQueue.async {
                // todo: make a presenter or something oof
                let sourceInfo = nodes.renderNodes(fileUrl)
                handler(sourceInfo)
            }
        }

    }

    func renderDirectory(_ handler: @escaping (SourceInfo) -> Void) {
        let nodes = SwiftSyntaxParser(wordNodeBuilder: wordNodeBuilder)
        nodes.requestSourceDirectory{ directory in
            self.sceneControllerQueue.async {
                // todo: make a presenter or something oof
                for url in directory.swiftUrls {
                    let sourceInfo = nodes.renderNodes(url)
                    handler(sourceInfo)
                }
            }
        }

    }


    private func customRender() {
        wordParser.testSourceFileLines.forEach{ sourceLine in // source; "x = x + 1"
            let lineNode = SCNNode()
            lineNode.position = iteratorY.nextPosition()
            sourceLine.splitToWordsAndSpaces
                .map{ wordNodeBuilder.node(for: $0) }
                .arrangeInLine(on: lineNode)

            sceneTransaction {
                self.sceneState.rootGeometryNode.addChildNode(lineNode)
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
