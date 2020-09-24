import Foundation
import SwiftSyntax

extension SwiftSyntaxParser {

    func __renderSheetTest(in sceneState: SceneState) {
        let fileUrl = Bundle.main.url(forResource: "WordNodeIntrospect", withExtension: "")
        prepareRendering(source: fileUrl!)

        let parentCodeSheet = makeCodeSheet()

        sceneTransaction {
            sceneState.rootGeometryNode.addChildNode(parentCodeSheet.containerNode)
        }
    }

    func makeCodeSheet() -> CodeSheet {
        let parentCodeSheet = CodeSheet()

        parentCodeSheet.containerNode.position =
            parentCodeSheet.containerNode.position
                .translated(dY: -100, dZ: nextZ - 200)

        for node in rootSyntaxNode!.children {
            print("At node \(node.syntaxNodeType)")
            visitChildrenOf(node, parentCodeSheet)
        }

        parentCodeSheet.sizePageToContainerNode()

        return parentCodeSheet
    }

    func visitChildrenOf(_ childSyntaxNode: SyntaxChildren.Element,
                         _ parentCodeSheet: CodeSheet) {
        for syntaxChild in childSyntaxNode.children {
            let childSheet = parentCodeSheet.spawnChild()
            childSheet.pageGeometry.firstMaterial?.diffuse.contents = NSUIColor.gray
            childSheet.containerNode.position.z -= nextZ

            if syntaxChild.isToken {
                print("Found solo syntax node")
                arrange(syntaxChild.firstToken!.text,
                        syntaxChild.firstToken!,
                        childSheet)
            } else {
                for token in syntaxChild.tokens {
                    add(token, to: childSheet)
                }
            }

            childSheet.sizePageToContainerNode()
            childSheet.containerNode.position.x +=
                childSheet.containerNode.lengthX / 2.0
            childSheet.containerNode.position.y -=
                childSheet.containerNode.lengthY / 2.0

            parentCodeSheet.arrangeLastChild()
        }
    }

}
