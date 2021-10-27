import SceneKit
import Foundation

class DictionarySceneController: BaseSceneController {
    let wordParser = WordParser()
    let iteratorY = WordPositionIterator()
    let wordNodeBuilder: WordNodeBuilder

    init(sceneView: CustomSceneView,
         wordNodeBuilder: WordNodeBuilder) {
        self.wordNodeBuilder = wordNodeBuilder
        super.init(sceneView: sceneView)
    }

    override func onSceneStateReset() {
        iteratorY.reset()
    }
}

extension DictionarySceneController {

    func add(word: String) throws {
        guard let definition = wordParser.dictionary[word] else {
            throw SceneControllerError.missingWord(query: word)
        }

        sceneTransaction {
            let nextPosition =
                sceneState.rootGeometryNode.childNodes.last?.position
                    .translated(dY: -10) ?? SCNVector3()

            let nodeToAdd =
                wordNodeBuilder.definitionNode(nextPosition, word, definition)

//            let rootWordNode =
//                nodeToAdd.childNodes.first!

            let definitionWords =
                nodeToAdd.childNodes.dropFirst()

            var lastNode: SCNNode!
            let definitionLength =
                definitionWords.reduce(into: CGFloat(0)) { length, node in
                    length += node.boundingBox.max.x.cg
                    defer { lastNode = node }
                    guard let target = lastNode else { return }
                    
                    let dX = target.lengthX / 2 + node.lengthX / 2
                    node.position = target.position.translated(dX: dX, dY: 0, dZ: 0)
                }

            sceneCameraNode.position =
                nextPosition.translated(
                    dX: definitionLength.vector / 2.0,
                    dZ: 75
                )

            sceneState.rootGeometryNode.addChildNode(nodeToAdd)
        }
    }

    func renderDictionaryTest() {
        workerQueue.async {
            sceneTransaction {
                self.doRenderDictionaryTest()
            }
        }
    }

    private func doRenderDictionaryTest() {
        let dispatchGroup = DispatchGroup()
        if let next = self.wordParser.definitionSliceIterator.next(), next.count > 0 {
            dispatchGroup.enter()
            self.renderWordSlice(next) {
                dispatchGroup.leave()
            }
        }
        dispatchGroup.wait()
        print("++ All items rendered in DictionaryTest. Have fun! ++")
    }

    private func renderWordSlice(_ wordSlice: ArraySlice<(String, String)>,
                                 _ renderFinished: @escaping VoidCompletion) {
        workerQueue.async {
            print("Dispatched \(wordSlice.startIndex)..<\(wordSlice.endIndex)")
            var rootWordPositions = self.iteratorY.wordIndicesForWordCount(wordSlice.count + 1).makeIterator()

            let containerNode = SCNNode()
            containerNode.position.x = -100
            containerNode.position.x = 100
            wordSlice.forEach { word, definition in
                let rootWordPosition = rootWordPositions.next()!
                let newNode = self.wordNodeBuilder.definitionNode(rootWordPosition, word, definition)
                containerNode.addChildNode(newNode)
            }

            sceneTransaction {
                self.sceneState.rootGeometryNode.addChildNode(containerNode)
                // TODO: make a struct that reaches into the node hiearchy and exposes things like:
                // "the list of containers that have a root word and definition words"
                
//                print("Completed \(wordSlice.startIndex)..<\(wordSlice.endIndex); last word == \(wordSlice.last!.0)")
                renderFinished()
            }
        }
    }

    func trackWordWithCamera(_ word: String) {
        workerQueue.async {
            let searchNodes = self.sceneState.rootGeometryNode.childNodes(
                passingTest: { node, stopLooking in
                    let rootWordNodeName = node.name
                    let foundMatch = rootWordNodeName?.starts(with: word) ?? false
                    stopLooking.pointee = ObjCBool(foundMatch)
                    return foundMatch
                })

            guard let foundNode = searchNodes.first else {
                return
            }
            sceneTransaction {
                self.sceneCameraNode.constraints = [
                    {
                        let lookAtNode = SCNLookAtConstraint(target: foundNode)
                        lookAtNode.isGimbalLockEnabled = true
                        return lookAtNode
                    }(),
                    {
                        let followNode = SCNDistanceConstraint(target: foundNode)
                        followNode.maximumDistance = 75
                        followNode.minimumDistance = 75
                        return followNode
                    }()
                ]
            }
        }
    }

    func animateRootAsDragon(_ node: SCNNode) {
        DragonAnimationLoop(node)
    }
}
