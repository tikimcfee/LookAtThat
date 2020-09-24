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
        print("------------------------------- Starting -------------------------------\n\n")

        let testCodeSheet = swiftSyntaxParser.makeCodeSheet()
        print("CodeSheet created with lines: \(testCodeSheet.allLines.count)")

        print("\n\n------------------------------- Done -------------------------------" )
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
