import XCTest
import SwiftSyntax
import SceneKit
@testable import LookAtThat_AppKit

import SwiftTrace

class LookAtThat_AppKitTests: XCTestCase {

	var bundle: TestBundle!

    override func setUpWithError() throws {
        // Fields reset on each test!
        bundle = TestBundle()
		try bundle.setUpWithError()
    }

    override func tearDownWithError() throws {
		try bundle.tearDownWithError()
    }
    
    func testSwiftSyntax() throws {
		bundle.gridParser.loadSourceUrl(bundle.testFile)?.tokens.forEach {
            print($0.triviaAndText)
            $0.triviaAndText.forEach {
				let (geometry, size) = bundle.glyphs[
                    GlyphCacheKey("\($0)", NSUIColor.white)
                ]
                
                print(size, "--", geometry.lengthX, geometry.lengthY, geometry.lengthZ)
                XCTAssertEqual(size.width, geometry.lengthX, accuracy: 0.0)
                XCTAssertEqual(size.height, geometry.lengthY, accuracy: 0.0)
            }
        }
    }
    
    func testParserV2() throws {
        printStart()
        
		let testFile = bundle.testFile
        let visitor = CodeSheetVisitor(WordNodeBuilder())
        let tracer = OutputTracer(trace: CodeSheetVisitor.self)
        
        let sheet = try visitor.makeFileSheet(testFile)
        
        tracer.logOutput.forEach {
            print(String(repeating: "-", count: 10))
            print($0)
        }
        
        XCTAssertNotNil(sheet)
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
		let sourceSyntax = bundle.swiftSyntaxParser.parse(source)
		let _ = bundle.swiftSyntaxParser.visit(sourceSyntax!)
		let testCodeSheet = bundle.swiftSyntaxParser.makeSheetFromInfo()
        print("CodeSheet created with children: \(testCodeSheet.children.count)")

        printEnd()
    }


    func test_JustFunctions() throws {
        printStart()

		let testCodeSheet = bundle.swiftSyntaxParser.makeSheetFromInfo()
        print("CodeSheet created with children: \(testCodeSheet.children.count)")

        printEnd()
    }

    func test_singleSheet() throws {
        printStart()

		let testCodeSheet = bundle.swiftSyntaxParser.makeSheetFromInfo()
        print("CodeSheet created with children: \(testCodeSheet.children.count)")

        measure {
            _ = testCodeSheet.wireSheet
        }

        printEnd()
    }

    func test_backAndForth() throws {
        printStart()

		let parentCodeSheet = bundle.swiftSyntaxParser.makeSheetFromInfo()
        let wireSheet = parentCodeSheet.wireSheet
        let backConverted = wireSheet.makeCodeSheet()

        print("Did I make equal sheets?", backConverted == parentCodeSheet)

        printEnd()
    }

    func test_sheetDataTransformer() throws {
        printStart()


		let testCodeSheet = bundle.swiftSyntaxParser.makeSheetFromInfo()
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

		let testCodeSheet = bundle.swiftSyntaxParser.makeSheetFromInfo()
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
	
	func testSemanticBuilder() {
		
	}
    
    func testKeyboardInterecptor() {
        
    }

    func printStart() {
        print("------------------------------- Starting -------------------------------\n\n")
    }
    func printEnd() {
        print("\n\n------------------------------- Done -------------------------------" )
    }
}

class LookAtThat_AppKitCodeGridTests: XCTestCase {
	var bundle: TestBundle!
	
	override func setUpWithError() throws {
		// Fields reset on each test!
		bundle = TestBundle()
		try bundle.setUpWithError()
		
	}
	
	override func tearDownWithError() throws {
		try bundle.tearDownWithError()
	}
	
	func testGridSizing() throws {
		bundle.gridParser.loadSourceUrl(bundle.testFile)?.tokens.forEach {
			print($0.triviaAndText)
			$0.triviaAndText.forEach {
				let (geometry, size) = bundle.glyphs[
					GlyphCacheKey("\($0)", NSUIColor.white)
				]
				
				print(size, "--", geometry.lengthX, geometry.lengthY, geometry.lengthZ)
				XCTAssertEqual(size.width, geometry.lengthX, accuracy: 0.0)
				XCTAssertEqual(size.height, geometry.lengthY, accuracy: 0.0)
			}
		}
	}
	
	func testSemanticInfo() throws {
		let sourceFile = try bundle.loadTestSource()
		let sourceSyntax = Syntax(sourceFile)
//		grids.consume(syntax: sourceSyntax)
		
		func onVisit(_ syntax: Syntax) -> SyntaxVisitorContinueKind {
//			let info = bundle.semanticBuilder.semanticInfo(for: syntax)
//			print(info)
			return .visitChildren
		}
		
		func onVisitPost(_ syntax: Syntax) {
			
		}
		
		let visitor = StateCapturingVisitor(
			onVisitAny: onVisit,  
			onVisitAnyPost: onVisitPost
		)
		
		visitor.walk(sourceSyntax)
	}
    
    func testAttributedWrites() throws {
        let testFile = bundle.testFile
        let fileData = try Data(contentsOfPath: FileKitPath(testFile.path))
        let dataString = try XCTUnwrap(String(data: fileData, encoding: .utf8))
        
        let dataStringAttributed = NSMutableAttributedString(
            string: dataString,
            attributes: [.foregroundColor: NSUIColor.red]
        )
        let appendedTestString = NSMutableAttributedString(
            string: "yet this is dog",
            attributes: [.foregroundColor: NSUIColor.blue]
        )
        dataStringAttributed.append(appendedTestString)
        
        let transformer = WireDataTransformer()
        let encodedTest = try XCTUnwrap(transformer.encodeAttributedString(dataStringAttributed))
        let (decodedTest, _) = try transformer.decodeAttributedString(encodedTest)
        print("Size of encode: \(encodedTest.mb)mb")
        XCTAssert(decodedTest == dataStringAttributed, "AttributedString write and re-read didn't reeturn same attributes")
    }
    
    func testSemanticWordGridEditor() throws {
        let editor = WorldGridEditor()
        
        var expected = FocusPosition()
        let start = editor.focusPosition
        XCTAssertEqual(start, expected, "start off from expected origin")
        
        expected = FocusPosition(x: expected.x + 1)
        editor.shiftFocus(.right)
        XCTAssertEqual(editor.focusPosition, expected, "start off from expected origin")
    }
	
}

class TestBundle {
	static let testFileNames = [
		"WordNodeIntrospect",
		"RidiculousFile",
		"SmallFile"
	]
	
	static let testFileResourceURLs = testFileNames.compactMap {
		Bundle.main.url(forResource: $0, withExtension: "")
	}
	
	lazy var testFile = Self.testFileResourceURLs[0]
	var glyphs: GlyphLayerCache!
	var gridParser: CodeGridParser!
	var tokenCache: CodeGridTokenCache!
	var semanticBuilder: SemanticInfoBuilder!
	
	var wordNodeBuilder: WordNodeBuilder!
	var swiftSyntaxParser: SwiftSyntaxParser!
	
	func setUpWithError() throws {
		glyphs = GlyphLayerCache()
		gridParser = CodeGridParser()
		tokenCache = CodeGridTokenCache()
		semanticBuilder = SemanticInfoBuilder()
		
		wordNodeBuilder = WordNodeBuilder()
		swiftSyntaxParser = SwiftSyntaxParser(wordNodeBuilder: wordNodeBuilder)
		swiftSyntaxParser.prepareRendering(source: testFile)
	}
	
	func tearDownWithError() throws {
		
	}
	
	func makeGrid() -> CodeGrid {
		CodeGrid(
			glyphCache: glyphs, 
			tokenCache: tokenCache
		)
	}
	
	func loadTestSource() throws -> SourceFileSyntax {
		try XCTUnwrap(
			gridParser.loadSourceUrl(testFile), 
			"Failed to load test file"
		)
	} 
}
