//
//  LookAtThat-TracingTests.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 5/3/22.
//

import XCTest
import SwiftSyntax
import SwiftParser
import SceneKit
import Foundation
import BitHandling
import SwiftGlyphs
@testable import LookAtThat_AppKit

import SwiftTreeSitter
import TreeSitterSwift

class LookAtThat_TracingTests: XCTestCase {
    var bundle: TestBundle!
    
    override func setUpWithError() throws {
        // Fields reset on each test!
        printStart()
        
        bundle = TestBundle()
        try bundle.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try bundle.tearDownWithError()
        printEnd()
    }
    
    func testScalars() throws {
//        let test = "🇵🇷"
        let test = RAW_ATLAS_STRING_
        
        var counts: [Int: Int] = [:]
        for character in test {
            counts[character.unicodeScalars.count, default: 0] += 1
            if character.unicodeScalars.count == 7 {
                print(
                    character,
                    character.unicodeScalars
                        .map { "\($0.value)" }
                        .joined(separator: ", ")
                )
            }
        }
        print("Scalars in \(test.count) characters:")
        print(counts)
    }
    
    func testGlyphCompute() throws {
        try doComputeTest("A")
        try doComputeTest("🇵🇷")
        try doComputeTest("🏴󠁧󠁢󠁥󠁮󠁧󠁿")
        try doComputeTest("🇵🇷🏴󠁧󠁢󠁥󠁮󠁧󠁿A")
        try doComputeTest("🇵🇷🏴󠁧󠁢󠁥󠁮󠁧󠁿")
        try doComputeTest("🇵🇷A")
        try doComputeTest("A🇵🇷A🏴󠁧󠁢󠁥󠁮󠁧󠁿")
        try doComputeTest("0🇵🇷1🏴󠁧󠁢󠁥󠁮󠁧󠁿23456")
        try doComputeTest("A🇵🇷🏴󠁧󠁢󠁥󠁮󠁧󠁿")
        try doComputeTest("🇵🇷A🇵🇷")
        try doComputeTest(RAW_ATLAS_STRING_)
        
        func doComputeTest(_ testString: String) throws {
            let compute = ConvertCompute(link: GlobalInstances.defaultLink)
            let output = try compute.execute(inputData: testString.data!.nsData)
            let (pointer, count) = compute.cast(output)
            let result = compute.makeString(from: pointer, count: count)
            
            XCTAssertEqual(testString, result, "Must have the same strings... yo.")
        }
    }
    
    func testTreeSitter() throws {
        let language = Language(language: tree_sitter_swift())
        
        let parser = Parser()
        try parser.setLanguage(language)
        
        let path = URL(filePath: "/Users/ivanlugo/rapiddev/_personal/LookAtThat/Interop/Views/SourceInfoPanelState.swift")
        let testFile = try! String(contentsOf: path)
        let tree = parser.parse(testFile)!
        
        print(tree)
        
        let queryUrl = Bundle.main
                      .resourceURL?
                      .appendingPathComponent("TreeSitterSwift_TreeSitterSwift.bundle")
                      .appendingPathComponent("Contents/Resources/queries/highlights.scm")
        
        let query = try language.query(contentsOf: queryUrl!)
        let cursor = query.execute(node: tree.rootNode!, in: tree)
        
        for match in cursor {
            print("match: ", match.id, match.patternIndex)
            
            print("\t-- captures")
            for capture in match.captures {
                print("\t\t\(capture)")
                print("\t\t\(capture.nameComponents)")
                print("\t\t\(capture.metadata)")
            }
        }
    }
    
    class TreeSyntaxCollector {
        var rootNode: TreeSyntaxNode
        
        init(
            rootNode: TreeSyntaxNode
        ) {
            self.rootNode = rootNode
        }
    }
    
    class TreeSyntaxNode {
        var name: String
        var nameChildren: [String]
        var nameCaptures: [QueryCapture]
        init(
            name: String,
            nameChildren: [String],
            nameCaptures: [QueryCapture]
        ) {
            self.name = name
            self.nameChildren = nameChildren
            self.nameCaptures = nameCaptures
        }
    }
    
    func testDeepRecursion() throws {
        let rootUrl = try XCTUnwrap(bundle.testSourceDirectory, "Must have root directory")
        rootUrl.enumeratedChildren().forEach { print($0) }
    }
    
    func testClassCollection() throws {
        let rootUrl = try XCTUnwrap(bundle.testSourceDirectory, "Must have root directory")
        let dummyGrid = bundle.newGrid()
        let visitor = FlatteningVisitor(
            target: dummyGrid.semanticInfoMap,
            builder: dummyGrid.semanticInfoBuilder
        )
        
        try rootUrl.enumeratedChildren().forEach { url in
            guard !url.isDirectory else {
                return
            }
            let sourceFile = try XCTUnwrap(bundle.gridCache.loadSourceUrl(url), "Must render syntax from file")
            let sourceSyntax = Syntax(sourceFile)
            visitor.walkRecursiveFromSyntax(sourceSyntax)
        }
        
        let classes = dummyGrid.semanticInfoMap.classes.keys.compactMap {
            dummyGrid.semanticInfoMap.semanticsLookupBySyntaxId[$0]
        }.compactMap { (info: SemanticInfo) -> String? in
            "\(info.referenceName).self"
        }
        .sorted()
        .joined(separator: ",\n")
        
        
        print(classes)
        
        printEnd()
    }
    
    
}
