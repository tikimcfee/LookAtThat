//
//  LookAtThat-TracingTests.swift
//  LookAtThat_AppKitTests
//
//  Created by Ivan Lugo on 5/3/22.
//

@testable import LookAtThat_AppKit
import XCTest
import SwiftSyntax
import SwiftParser
import SceneKit
import Foundation
import BitHandling
import SwiftGlyphs
import MetalLink
import MetalLinkHeaders
import MetalLinkResources

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
//        let eh = [2, 7]
        for character in test {
            counts[character.unicodeScalars.count, default: 0] += 1
//            if eh.contains(character.unicodeScalars.count) {
            if character.unicodeScalars.count > 6 {
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
        try doComputeTest("0🇵🇷1🏴󠁧󠁢󠁥󠁮󠁧󠁿23🦾4🥰56")
        try doComputeTest("A🇵🇷🏴󠁧󠁢󠁥󠁮󠁧󠁿")
        try doComputeTest("🇵🇷A🇵🇷")
        
        let testFile = bundle.testFile2
        let testFileText = try String(contentsOf: testFile)
        try doComputeTest(testFileText)
        
        // This is the current failing test case for grapheme clusters.. not bad so far...
        // I think I'm just missing some types of glyphs.
//        try doComputeTest(RAW_ATLAS_STRING_)
        
        func doComputeTest(_ testString: String) throws {
            let compute = ConvertCompute(link: GlobalInstances.defaultLink)
            let output = try compute.execute(inputData: testString.data!.nsData)
            let (pointer, count) = compute.cast(output)
            let result = compute.makeString(from: pointer, count: count)
            
            let testHashes = testString.map { $0.glyphComputeHash }
            let resultHashes = result.map { $0.glyphComputeHash }
            let gpuComputeHashes = (0..<count).map { pointer[$0].unicodeHash }.filter { $0 != 0 }
            
            XCTAssertEqual(testHashes, resultHashes, "Hashes are indices and need to line up")
            XCTAssertEqual(resultHashes, gpuComputeHashes, "Hashes are indices and need to line up")
            
            let iterativeStringMatchesTest = testString == result
            XCTAssertTrue(iterativeStringMatchesTest, "Adding them all up manually needs to work")
            
            let graphemeString = compute.makeGraphemeBasedString(from: pointer, count: count)
            let graphemeMatchesTest = testString == graphemeString
            XCTAssertTrue(graphemeMatchesTest, "Graphemes need to match for Atlas to match")
        }
    }
    
    func testAtlas() throws {
        let atlas = GlobalInstances.defaultAtlas
        
        
        let text = RAW_ATLAS_STRING_
//        let text = "0🇵🇷1🏴󠁧󠁢󠁥󠁮󠁧󠁿23🦾4🥰56"

//        let testFile = bundle.testFile2
//        let text = try String(contentsOf: testFile)
        
        let filtered = text.filter {
            CharacterSet.alphanumerics
                .union(.symbols)
                .union(.whitespacesAndNewlines)
                .containsUnicodeScalars(of: $0)
        }
        
        let test = filtered
        let testCount = test
            .count
        
        let compute = ConvertCompute(link: GlobalInstances.defaultLink)
        let output = try compute.execute(inputData: test.data!.nsData)
        let (pointer, count) = compute.cast(output)
        
        let (_, atlasPointer) = try compute.makeGraphemeAtlasBuffer()
        
        var added = 0
        for index in (0..<count) {
            let pointee = pointer[index]
            let hash = pointee.unicodeHash
            guard hash > 0 else { continue; }
            
            // We should always get back 1 character.. that's.. kinda the whole point.
            let unicodeCharacter = pointee.expressedAsString.first!
            
            let key = GlyphCacheKey.fromCache(source: unicodeCharacter, .white)
            atlas.addGlyphToAtlasIfMissing(key)
            
            let writtenKey = try XCTUnwrap(atlas.uvPairCache[key])
            let unicodeHash = pointee.unicodeHash
            atlasPointer[Int(unicodeHash)].unicodeHash = unicodeHash
            atlasPointer[Int(unicodeHash)].textureDescriptorU = writtenKey.u
            atlasPointer[Int(unicodeHash)].textureDescriptorV = writtenKey.v
            
            added += 1
        }
        
        // TODO: Ya know, NOT FREAKING BAD for a first run!
        // I'm missing 20,000 characters. I'm sure a lot of those are non rendering and
        // I'm not filtering them out, but still, that's AWESOME so far!
//        XCTAssertEqual failed: ("435716") is not equal to ("457634") - Make all the glyphyees

        XCTAssertEqual(added, testCount, "Make all the glyphees")
        
        atlas.save()
//        atlas.load()
    }
    
    func testMeasureGlyphComputeButLikeALot() throws {
        measure {
            do {
                try testGlyphCompute()
            } catch {
                
            }
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
