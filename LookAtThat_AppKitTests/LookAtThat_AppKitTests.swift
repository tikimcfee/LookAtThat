import XCTest
import SwiftSyntax
import SceneKit
@testable import LookAtThat_AppKit

extension CodeSheetVisitor {
    static func run() throws {
        let visitor = CodeSheetVisitor()
        guard let loaded = visitor.loadSourceUrl(
            LookAtThat_AppKitTests.testFileResourceURLs[2]
        )
        else { throw NSError(domain: "file-not-loaded", code: 1, userInfo: nil) }
        visitor.walk(loaded)
    }
}

class LookAtThat_AppKitTests: XCTestCase {

    static let testFileNames = [
        "WordNodeIntrospect",
        "RidiculousFile",
        "SmallFile"
    ]
    
    static let testFileResourceURLs = testFileNames.compactMap {
        Bundle.main.url(forResource: $0, withExtension: "")
    }

    var wordNodeBuilder: WordNodeBuilder!
    var swiftSyntaxParser: SwiftSyntaxParser!

    override func setUpWithError() throws {
        // Fields reset on each test!
        wordNodeBuilder = WordNodeBuilder()
        swiftSyntaxParser = SwiftSyntaxParser(wordNodeBuilder: wordNodeBuilder)
        swiftSyntaxParser.prepareRendering(source: Self.testFileResourceURLs[0])
    }

    override func tearDownWithError() throws {

    }
    
    func testParserV2() throws {
        printStart()
        try CodeSheetVisitor.run()
        printEnd()
    }

    func test_RawSource() throws {
        printStart()

        let source =
"""
extension String {
    var hello: String
}
"""
        let sourceSyntax = swiftSyntaxParser.parse(source)
        let _ = swiftSyntaxParser.visit(sourceSyntax!)
        let testCodeSheet = swiftSyntaxParser.makeSheetFromInfo()
        print("CodeSheet created with children: \(testCodeSheet.children.count)")

//        swiftSyntaxParser.organizedInfo.dump()

        printEnd()
    }


    func test_JustFunctions() throws {
        printStart()

        let testCodeSheet = swiftSyntaxParser.makeSheetFromInfo()
        print("CodeSheet created with children: \(testCodeSheet.children.count)")

//        swiftSyntaxParser.organizedInfo.dump()

        printEnd()
    }

    func test_singleSheet() throws {
        printStart()

        let testCodeSheet = swiftSyntaxParser.makeSheetFromInfo()
        print("CodeSheet created with children: \(testCodeSheet.children.count)")

        measure {
            _ = testCodeSheet.wireSheet
        }

        printEnd()
    }

    func test_backAndForth() throws {
        printStart()

        let parentCodeSheet = swiftSyntaxParser.makeSheetFromInfo()
        let wireSheet = parentCodeSheet.wireSheet
        let backConverted = wireSheet.makeCodeSheet()

        print("Did I make equal sheets?", backConverted == parentCodeSheet)

        printEnd()
    }

    func test_sheetDataTransformer() throws {
        printStart()


        let testCodeSheet = swiftSyntaxParser.makeSheetFromInfo()
        print("CodeSheet created with children: \(testCodeSheet.children.count)")

        func transformer(_ mode: WireDataTransformer.Mode) {
            print("++++ Start compression with \(mode)\n")

            let transformer = WireDataTransformer()
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

        let testCodeSheet = swiftSyntaxParser.makeSheetFromInfo()
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

    func test_runningAWorker() throws {
        printStart()
        let expectation = XCTestExpectation(description: "The worker runs")

        let worker = BackgroundWorker()
        worker.run {
            print("Hey there folks, I'm '\(Thread.current)'.")
            expectation.fulfill()
            print("What a funny thing to code against. 'Fulfill expectation'. Heh.")
            worker.stop()
        }

        wait(for: [expectation], timeout: 3)
        printEnd()
    }

    func test_writingStreams() throws {
        printStart()

        let worker = BackgroundWorker()

        let dataDecoded = XCTestExpectation(description: "Data decoded")
        let decodeData = { (data: Data) in
            let inputStream = InputStream(data: data)
            inputStream.schedule(in: .current, forMode: .default)
            inputStream.open()

            let reader = InputStreamReader(stream: inputStream)
            let outputData = try! reader.readData()
            let outputString = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(outputData) as? String

            print("So what did we write?:\n\t", outputString as Any)

            inputStream.close()
            dataDecoded.fulfill()
        }

        let dataEncoded = XCTestExpectation(description: "Data encoded")
        worker.run {
            let outputStream = OutputStream.toMemory()
            outputStream.schedule(in: .current, forMode: .default)
            outputStream.open()

            let message = "Thanks, internet person: https://gist.github.com/lucasecf/bde1d9bd3492f29b7534"
            let data = try! NSKeyedArchiver.archivedData(withRootObject: message, requiringSecureCoding: false)
            let writtenData = outputStream.writeDataWithBoundPointer(data)
            print("Well. It wrote: \(writtenData)")

            decodeData(data)

            outputStream.close()
            dataEncoded.fulfill()
        }

        wait(for: [dataEncoded, dataDecoded], timeout: 10)
        printEnd()
    }

    func printStart() {
        print("------------------------------- Starting -------------------------------\n\n")
    }
    func printEnd() {
        print("\n\n------------------------------- Done -------------------------------" )
    }
}
