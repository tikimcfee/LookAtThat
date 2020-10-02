import XCTest
import SwiftSyntax
import SceneKit
@testable import LookAtThat_AppKit

class LookAtThat_AppKitTests: XCTestCase {

    let testFiles = [
        "WordNodeIntrospect",
        "RidiculousFile"
    ]

    var wordNodeBuilder: WordNodeBuilder!
    var swiftSyntaxParser: SwiftSyntaxParser!

    override func setUpWithError() throws {
        // Fields reset on each test!
        wordNodeBuilder = WordNodeBuilder()
        swiftSyntaxParser = SwiftSyntaxParser(wordNodeBuilder: wordNodeBuilder)

        let fileUrl = Bundle.main.url(forResource: testFiles[0], withExtension: "")
        swiftSyntaxParser.prepareRendering(source: fileUrl!)
    }

    override func tearDownWithError() throws {

    }

    func test_JustFunctions() throws {
        printStart()

        let testCodeSheet = swiftSyntaxParser.makeRootCodeSheet()
        print("CodeSheet created with children: \(testCodeSheet.children.count)")

        swiftSyntaxParser.organizedInfo.dump()

        printEnd()
    }

    func test_singleSheet() throws {
        printStart()

        let testCodeSheet = swiftSyntaxParser.makeRootCodeSheet()
        print("CodeSheet created with children: \(testCodeSheet.children.count)")

        measure {
            _ = testCodeSheet.wireSheet
        }

        printEnd()
    }

    func test_backAndForth() throws {
        printStart()

        let parentCodeSheet = swiftSyntaxParser.makeRootCodeSheet()
        let wireSheet = parentCodeSheet.wireSheet
        let backConverted = wireSheet.makeCodeSheet()

        print("Did I make equal sheets?", backConverted == parentCodeSheet)

        printEnd()
    }

    func test_sheetDataTransformer() throws {
        printStart()


        let testCodeSheet = swiftSyntaxParser.makeRootCodeSheet()
        print("CodeSheet created with children: \(testCodeSheet.children.count)")

        func transformer(_ mode: SheetDataTransformer.Mode) {
            print("++++ Start compression with \(mode)\n")

            let transformer = SheetDataTransformer()
            transformer.mode = mode

            guard let compressedData = transformer.data(from: testCodeSheet) else {
                XCTFail("Failed to compress code sheet")
                return
            }

            guard let reifiedSheet = transformer.sheet(from: compressedData) else {
                XCTFail("Failed to recreate code sheet")
                return
            }

            print("\n+++Round trip succeeded: \(reifiedSheet)")
        }

        transformer(.standard)
        transformer(.brotli)

        printEnd()
    }

    func test_ManySheets() throws {
        printStart()

        let testCodeSheet = swiftSyntaxParser.makeRootCodeSheet()
        print("CodeSheet created with children: \(testCodeSheet.children.count)")

        let list = Array.init(repeating: 0, count: 100)
        var iterator = list.slices(sliceSize: 10).makeIterator()

        let jsonEncoder = JSONEncoder()
        jsonEncoder.dataEncodingStrategy = .base64
        jsonEncoder.outputFormatting = .withoutEscapingSlashes

        while let next = iterator.next() {
            let id = UUID.init().uuidString
            let toFulfill = expectation(description: "Work slice \(id)")
            WorkerPool.shared.nextConcurrentWorker().async {
                for _ in next {
                    print("\(id) making sheet...")
                    let sheet = testCodeSheet.wireSheet
                    do {
                        _ = try jsonEncoder.encode(sheet)
                    } catch {
                        print(error)
                    }
                }
                toFulfill.fulfill()
            }
        }

        waitForExpectations(timeout: 10)

        printEnd()
    }

    func printStart() {
        print("------------------------------- Starting -------------------------------\n\n")
    }
    func printEnd() {
        print("\n\n------------------------------- Done -------------------------------" )
    }
}
