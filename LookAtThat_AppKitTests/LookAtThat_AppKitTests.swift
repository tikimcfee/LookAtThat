import XCTest
import SwiftSyntax
import SceneKit
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
        printStart()

        let testCodeSheet = swiftSyntaxParser.makeCodeSheet()
        print("CodeSheet created with children: \(testCodeSheet.children.count)")

        printEnd()
    }

    func test_singleSheet() throws {
        printStart()

        let testCodeSheet = swiftSyntaxParser.makeCodeSheet()
        print("CodeSheet created with children: \(testCodeSheet.children.count)")

        measure {
            _ = testCodeSheet.wireSheet
        }

        printEnd()
    }

    func test_backAndForth() throws {
        printStart()

        let parentCodeSheet = swiftSyntaxParser.makeCodeSheet()
        let wireSheet = parentCodeSheet.wireSheet
        let backConverted = wireSheet.makeCodeSheet()

        print("Did I make equal sheets?", backConverted == parentCodeSheet)

        printEnd()
    }

    func test_compressSheet() throws {
        printStart()

        let compressionFormat = NSData.CompressionAlgorithm.lzma

        let testCodeSheet = swiftSyntaxParser.makeCodeSheet()
        print("CodeSheet created with children: \(testCodeSheet.children.count)")

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .withoutEscapingSlashes
        let jsonDecoder = JSONDecoder()

        let wireSheet = testCodeSheet.wireSheet
        let encodedSheet = try jsonEncoder.encode(wireSheet)
        print("Encoded sheet size: \(encodedSheet.mb)mb (\(encodedSheet.kb)kb)")

        let compressedData = try (encodedSheet as NSData).compressed(using: compressionFormat)
        print("Comressed sheet size: \(compressedData.mb)mb (\(compressedData.kb)kb)")

        let compressionRatio = (Float(compressedData.count) / Float(encodedSheet.count)) * 100
        print("Compression ratio: \(compressionRatio)")

        let decompressedData = try compressedData.decompressed(using: compressionFormat)
        print("Decompressed size: \(decompressedData.mb)mb (\(decompressedData.kb)kb)")

        guard case let ConnectionData.sheet(sheet) = ConnectionData.fromData(decompressedData as Data) else {
            fatalError("Well, a data sheet didn't come back.")
        }

        print("Decompression succeeded: \(sheet)")

        printEnd()
    }

    func test_ManySheets() throws {
        printStart()

        let testCodeSheet = swiftSyntaxParser.makeCodeSheet()
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
