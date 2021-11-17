//
//  CodeSheetTests.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 11/17/21.
//

import XCTest
import SwiftSyntax
import SwiftSyntaxParser
import SceneKit
import SwiftTrace
@testable import LookAtThat_AppKit

class CodeSheetTests: XCTestCase {
    
    var bundle: TestBundle!

    override func setUpWithError() throws {
        // Fields reset on each test!
        bundle = TestBundle()
        try bundle.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try bundle.tearDownWithError()
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
}
