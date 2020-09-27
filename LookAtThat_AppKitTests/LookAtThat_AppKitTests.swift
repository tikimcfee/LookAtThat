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

    func test_ManySheets() throws {
        printStart()

        let testCodeSheet = swiftSyntaxParser.makeCodeSheet()
        print("CodeSheet created with children: \(testCodeSheet.children.count)")

        let list = Array.init(repeating: 0, count: 100)
        var iterator = list.slices(sliceSize: 10).makeIterator()
        let concurrentQueue = DispatchQueue(label: "Work", attributes: .concurrent)

        let jsonEncoder = JSONEncoder()
        jsonEncoder.dataEncodingStrategy = .base64
        jsonEncoder.outputFormatting = .withoutEscapingSlashes

        while let next = iterator.next() {
            let id = UUID.init().uuidString
            let toFulfill = expectation(description: "Work slice \(id)")
            concurrentQueue.async {
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

//struct WireVector: Codable {
//    let x: VectorFloat
//    let y: VectorFloat
//    let z: VectorFloat
//
//    enum Keys: CodingKey {
//        case x
//        case y
//        case z
//    }
//
//    public init(from decoder: Decoder) throws {
//        let container = try? decoder.container(keyedBy: WireVector.Keys.self)
//        self.x = (try? container?.decode(VectorFloat.self, forKey: Keys.x)) ?? 0.0
//        self.y = (try? container?.decode(VectorFloat.self, forKey: Keys.y)) ?? 0.0
//        self.z = (try? container?.decode(VectorFloat.self, forKey: Keys.z)) ?? 0.0
//    }
//
//    public func encode(to encoder: Encoder) throws {
//        let container = encoder.container(keyedBy: WireVector.Keys.self)
//        container.encode(x, forKey: .x)
//        container.encode(y, forKey: .y)
//        container.encode(z, forKey: .z)
//    }
//}
