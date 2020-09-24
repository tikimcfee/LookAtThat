import XCTest
import SwiftSyntax
@testable import LookAtThat_AppKit

class LookAtThat_AppKitTests: XCTestCase {

    var wordNodeBuilder: WordNodeBuilder!
    var swiftSyntaxParser: SwiftSyntaxParser!

    override func setUpWithError() throws {
        // Fields reset on each test!
        wordNodeBuilder = WordNodeBuilder()
        swiftSyntaxParser = SwiftSyntaxParser(wordNodeBuilder: wordNodeBuilder)

        let fileUrl = Bundle.main.url(forResource: "WordNodeIntrospect", withExtension: "")
        swiftSyntaxParser.prepareRendering(source: fileUrl!)
    }

    override func tearDownWithError() throws {

    }

    func test_JustFunctions() throws {
        print("------------------------------- Starting -------------------------------\n\n" )
        let parentCodeSheet = CodeSheet()
        for node in swiftSyntaxParser.rootSyntaxNode!.children {
            print("At node \(node.syntaxNodeType)")
            if node.isToken {
                let token = node.firstToken!
                swiftSyntaxParser.add(token, to: parentCodeSheet)
            }
            visitChildrenOf(node, parentCodeSheet)
        }

        print("\nParent code sheet created: \(parentCodeSheet.allLines.count) lines")
        for childSheet in parentCodeSheet.children {
            print("- Child sheet: \(childSheet.allLines.count) lines")
        }

        print("\n\n------------------------------- Done -------------------------------" )
    }

    func visitChildrenOf(_ childSyntaxNode: SyntaxChildren.Element,
                         _ parentCodeSheet: CodeSheet) {
        for syntaxChild in childSyntaxNode.children {
            print("At syntax node child \(syntaxChild.syntaxNodeType)")
            let childSheet = parentCodeSheet.spawnChild()

            if syntaxChild.isToken {
                print("Found solo syntax node")
                swiftSyntaxParser.arrange(syntaxChild.firstToken!.text,
                                          syntaxChild.firstToken!,
                                          childSheet)
            } else {
                for token in syntaxChild.tokens {
                    swiftSyntaxParser.add(token, to: childSheet)
                }
            }

            childSheet.sizePageToContainerNode()
            childSheet.containerNode.position.x +=
                childSheet.containerNode.lengthX / 2.0
        }
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
